+++
title =  "AWS PrivateLink Part 1"
tags = ["privatelink", "tutorial", "aws", "vpc"]
date = "2022-12-07"
+++


![Ceviche](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/aws_pvt_link_1/header.jpg)


# Overview

Your company is growing and now you have to find out how to allow communication between services across VPCs and AWS accounts. You don't want send traffic over the public Internet and maintaining VPC Peering isn't a fun prospect. Implementing an AWS supported solution is the top priority and AWS PrivateLink can be a front-runner for enabling your infrastructure to scale.


## Lesson

* What is AWS PrivateLink?
* PrivateLink Components
* Gotchas
* Next Steps

### What is AWS PrivateLink?

AWS PrivateLink is a service which allows you to create a one-way connection from a service in one VPC to a service in another VPC. These VPCs can be in the same or different AWS accounts. PrivateLink traffic is transferred over AWS's backbone network which has additional security benefits. Other solutions exist like VPC Peering and Transit Gateway, but PrivateLink is a way to share web applications (or APIs) across an organization or with external customers.


### PrivateLink Components

AWS uses the terminology "Service Provider" to identify the target VPC or destination for traffic. AWS uses the terminology "Service Consumer" to identify source VPC or where the traffic originates.


#### VPC Endpoint

* **Location**: Service Consumer
* **TLDR**: A set of resoures which lives in the Consumer VPC which attaches itself to an existing VPC Endpoint Service

You may or may not be familiar with VPC Endpoints alraedy. Outside of PrivateLink, they provide a similar function which allows applications in a VPC to reach AWS services over AWS's backbone network. This means an application can reach other AWS Services without having to exit through a NAT gateway and traverse the Internet to reach an AWS service like S3. A VPC's default configuration is to send any non-VPC traffic to the Internet which can be costly. When it comes to PrivateLink, a VPC Endpoint is provisioned with Elastic Network Interfaces (ENI) in the consumer VPCs private-zoned networks to cover the available AZs. When configured, the VPC Endpoint also creates an invisible DNS A record for the destination service's FQDN and lists the VPC Endpoint's ENI IPs as the target.

#### VPC Endpoint Service

* **Location**: Sevice Provider
* **TLDR**: A poorly named resource which lives in the Provider VPC and allows one or more VPC Endpoints to connect to it.

A VPC Endpoint Service is an endpoint exposed by a company's provider VPC which allows a secure network connection to a private resource. This does not include automatic authentication. An example of a VPC Endpoint Service can be found in [Datadog](https://docs.datadoghq.com/agent/guide/private-link/?tab=useast1). The company has exposed their APIs via VPC Endpoint Service so that customers can securely route logs/metrics/traces to datadog over PrivateLink instead of going over the public Internet. From what I can tell, only AWS customers can take advantage of Privatelink and connectivity through VPC Endpoint Services.


#### Network Load Balancer
* **Location**: Service Provider
* **TLDR**: A required component which transfers traffic from the VPC Endpoint Service to its intended target.

A Network Load Balancer is required prior to provisioning the VPC Endpoint Service. The NLB then forwards on requests to a registered target. In many cases, this is probably the Application Load Balancer for your service. It's worth calling out that you can't attach security groups to the NLB, so any additional network security to allow PrivateLink traffic will need to reside on the ALBs security group.

The Available AZs in a given AWS region also plays a big role in Privatelink and this is most visible through PrivateLink's requirement to have the provisioned NLB span all Availability Zones. Without it, when a Service Consumer attempts to connect to the VPC Endpoint Service, it will more than likely exit with an AZ mismatch error. You may also compare the AZs in use on the Service Consumer and Service Provider to which you may find that they are both using `us-east-1a`, `us-east-1b`, and `us-east-1c`. You may ask _"Wait, what's the problem then?"_ Well AWS doesn't necessarily make it clear that `us-east-1a` in one AWS account doesn't necessarily guarantee that it matches `us-east-1a` in another AWS account. To evenly distribute account load across AZs, AWS renames/remaps the AZs behind the scenes. To resolve the potential AZ mismatch, you will need to extend your Provider VPC's private subnets to cover to all AZs or create dedicated PrivateLink subnets which span all of the region's AZs. Extending the VPCs private subnets can cause issues with existing service deployments and will create more cross AZ network traffic which creates a bigger AWS bill. Creating dedicated PrivateLink subnets is probably your best bet and it allows you to build additional security groups around them.

#### Application Load Balancer
* **Location**: Service Provider
* **TLDR**: A private or public ALB which sends traffic to some kind of compute like an EC2 instance or ECS task.

The ALB gets attached to the NLB as a target. Other AWS services can be attached to the NLB (I'm still praying for RDS support.) Like any other load balanced service, the ALB contains listener rules with host headers/paths/etc to distribute traffic to EC2 instances, ECS tasks, and Lambdas. A certificate also needs to be attached to the ALB which will help when it comes to DNS

#### DNS
* **Location**: Service Provider and Service Consumer
* **TLDR**: Some wizardry which tells the Service Consumer to send traffic over the VPC Endpoint instead of going out to the public Internet.

Like anything else, PrivateLink relies on DNS. You can send traffic through privatelink based on the auto-generated fully-qualified domain name AWS assigns, but this may be tough to work with if you want to use `https`. Instead AWS gives you the option to use "private DNS" which just means a customer owned domain (eg. `tacoform.com`.) DNS will need to be configured on your ALB with a wildcard, you will also need to validate that you own the domain on the VPC Endpoint Service for AWS to allow it to advertise the FQDN. There's some interesting magic happening on the consumer VPC side. When you connect a VPC Endpoint with the private DNS configured, an A record is created for the service's FQDN (eg. `burrito.tacoform.com`) and points them to the Elastic Network Interfaces created for the VPC Endpoint. This DNS record will intercept the DNS request so that it doesn't go out to the Internet, instead it will route the request over the configured PrivateLink configuration.

### Gotchas

* The VPC Endpoint and VPC Endpoint Service must be in the same AWS Region.
* AWS PrivateLink requires the Consumer and Provider VPCs to share the same Availability Zones, which becomes a problem when configuring PrivateLink across AWS Accounts. `us-east-1a` isn't necessarily `us-east-1a` in every account. AWS remaps Availability Zones to spread their customer load more evenly across the region's provisioned AZs.
* Because of this AZ mismatch, you will need to either extend your VPC's existing private subnets to provide coverage to all AZs or create dedicated PrivateLink subnets which span all of the region's AZs. With all AZs covered, you won't run into provisioning errors when configuring PrivateLink
* In order for private DNS to work, the Consumer VPC needs both "Enable DNS Hostnames" and "Enable DNS Support" enabled for PrivateLink to route traffic properly.
* The private DNS TXT validation on the VPC Endpoint can be fickle. You may need to go into the AWS console (or use AWSCLI) to re-try the validation.
* Validating end-to-end connectivity can be hard if DNS is not configured, you may need to use `curl` with the ignore certificate errors flag.
  * eg: `curl -k https://burrito.tacoform.com`


### In Review

This may or my not have made sense, but hopefully this explanation of AWS PrivateLink can help you decide if it's valuable to you and your organization. In the next post, we will explore how to provision AWS PrivateLink across VPCs using Terraform.


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
