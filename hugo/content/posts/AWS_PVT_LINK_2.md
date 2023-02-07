+++
title =  "AWS PrivateLink Part 2"
tags = ["privatelink", "tutorial", "aws", "vpc", "vpc-endpoint"]
date = "2022-02-06"
+++


![Tostada](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/aws_pvt_link_1/header.jpg)


# Overview

 In the previous PrivateLink post, we went through the separate resources that make up AWS PrivateLink. In this post, we will be provisioning a PrivateLink configuration which will allow resources in one VPC to connect to a web service in another VPC. You can use several different AWS services to accomplish the same goal, but PrivateLink can simplify some setups and meet security expectations with its standard one-way communication.


![PrivateLink](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/aws_pvt_link_2/tacoform-privatelink.jpg)
## Lesson

* Building Two VPCs
* Creating A Web Service To Share Via PrivateLink
* Deploying PrivateLink Resources in Provider VPC
* Provision PrivateLink Resources in Consumer VPC
* Validating Connectivity From The Consumer VPC To Provider VPC


### Building Two VPCs

A prerequisit for creating a PrivateLink connection is at least two VPCs. Remember that the VPC providing the service can interface with more than one consumer VPCs. These consumer VPCs can live in the same or different accounts, but they must be in the same region. That being said, we'll start with creating two VPCs. This module will also create a jumpbox to allow you to connect into the VPC and a wildcard certificate. If you'd like to see the code, you can view it [here](https://github.com/jperez3/taccoform-privatelink-demo/tree/main/infra/modules/vpc).

```hcl
module "vpc" {
  source = "../../modules/vpc"

  for_each = {
    provider = {
      cidr_block         = "10.1.0.0/16"
      vpc_name           = "provider-prod"
    },
    consumer = {
      cidr_block         = "10.2.0.0/16"
      vpc_name           = "consumer-prod"

    }
  }

  cidr_block              = each.value.cidr_block
  env                     = "prod"
  enable_jumpbox_instance = true
  vpc_name                = each.value.vpc_name
}
```
_Note: if you plan on deploying this module on your own, you will need to have a public DNS zone in the AWS account use the `public_domain_name` to specify your domain._



### Creating A Web Service To Share Via PrivateLink

We now have a provider VPC to start building a new service we'll call "tostada". For the sake of keeping things simple of this demo, the service is comprised of an EC2 instance with nginx installed, a security group, and Application Load Balancer resources (ALB, listener, listener rule, target group.)

```hcl
resource "aws_security_group" "tostada" {

  name        = "tostada-${local.vpc_name}"
  description = "${local.vpc_name} tostada security group"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [data.aws_vpc.selected.cidr_block]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "tostada-${local.vpc_name}"
    })
  )
}

resource "aws_instance" "tostada" {

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t4g.nano"
  subnet_id              = data.aws_subnets.private.ids[0]
  vpc_security_group_ids = [aws_security_group.tostada.id]
  user_data              = file("${path.module}/files/user-data.sh")

  tags = {
    Name = "tostada-${local.vpc_name}"
  }
}

resource "aws_lb_target_group" "tostada" {
  name     = "tostada"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id
}

resource "aws_lb" "tostada" {
  name               = "tostada"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tostada.id]
  subnets            = data.aws_subnets.private.ids

}

resource "aws_lb_listener" "tostada" {
  load_balancer_arn = aws_lb.tostada.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.issued.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tostada.arn
  }
}

resource "aws_lb_target_group_attachment" "tostada" {
  target_group_arn = aws_lb_target_group.tostada.arn
  target_id        = aws_instance.tostada.id
  port             = 80
}


resource "aws_route53_record" "lb_cname" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "tostada.${local.private_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.tostada.dns_name]
}
```
_Note: To see the entire module, you can visit the [tostada service module](https://github.com/jperez3/taccoform-privatelink-demo/tree/main/infra/modules/tostada)_


Once this module is done provisioning, you can use a tool like [aws-connect](https://github.com/rewindio/aws-connect) to "ssm" into the jumpbox in the same provider VPC as the tostada service and verify that the service is online via `curl`:

```bash
$ aws-connect -n jumpbox0-provider-prod -r us-east-2


Establishing session manager connection to jumpbox0-provider-prod (i-044687cbb5f964344)

Starting session with SessionId: taccoform-0cad163c26c2c8610
sh-4.2$ curl https://tostada.provider-prod.tacoform.com
<html><body><h1>IT'S TOSTADA TIME</h1></body></html>
```




### Deploying PrivateLink Resources in Provider VPC

At the same time of the `tostada` service provisioning, additional resource will be created in the `provider-prod` VPC to support the PrivateLink connection. This will include a VPC Endpoint Service, Network Load Balancer, and Target Group attachment to the `tostada` service's ALB:


```hcl
resource "aws_lb" "privatelink" {
  enable_cross_zone_load_balancing = false
  internal                         = true
  load_balancer_type               = "network"
  name                             = "tostada-privatelink-nlb"
  subnets                          = data.aws_subnets.private.ids
}

resource "aws_lb_target_group" "privatelink" {
  name        = "tostada-privatelink-tg"
  port        = "443"
  protocol    = "TCP"
  target_type = "alb"
  vpc_id      = data.aws_vpc.selected.id

  health_check {
    matcher  = "200"
    path     = "/"
    port     = "443"
    protocol = "HTTPS"
  }
}

resource "aws_lb_listener" "privatelink" {
  load_balancer_arn = aws_lb.privatelink.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.privatelink.arn
  }
}

resource "aws_lb_target_group_attachment" "privatelink" {
  port             = aws_lb_listener.privatelink.port
  target_group_arn = aws_lb_target_group.privatelink.arn
  target_id        = aws_lb.tostada.arn
}


resource "aws_vpc_endpoint_service" "privatelink" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.privatelink.arn]
  private_dns_name           = "tostada.${local.private_domain_name}"
}

resource "aws_route53_record" "privatelink" {
    name    = "${aws_vpc_endpoint_service.privatelink.private_dns_name_configuration[0]["name"]}."
    records = [aws_vpc_endpoint_service.privatelink.private_dns_name_configuration[0]["value"]]
    type    = "TXT"
    ttl     = "300"
    zone_id = data.aws_route53_zone.public.zone_id
}


resource "aws_vpc_endpoint_service_allowed_principal" "allowed_aws_accounts" {
  for_each = toset(var.allowed_aws_accounts_list)

  vpc_endpoint_service_id = aws_vpc_endpoint_service.privatelink.id
  principal_arn           = "arn:aws:iam::${each.key}:root"
}

```
_Note: To see the entire module, you can visit the [tostada service module](https://github.com/jperez3/taccoform-privatelink-demo/tree/main/infra/modules/tostada)_


Some things to note for the Provider VPC PrivateLink resources:
* You want to enable auto acceptance on the VPC endpoint Service resource to make things more automated
* Enabling private DNS on the VPC Endpoint Service resource will allow Consumer VPCs to use your domain and HTTPS connections (eg. tostada.provider-prod.tacoform.com instead of the Amazon provided DNS name)
* The VPC Endpoint Service Allowed Principal resource is what will allow Consumer VPCs in different AWS accounts to connect to this Provider VPC. You will need to populate this list prior to attempting any connectivity from a Consumer VPC.
* The Route53 record is required to automatically verify ownership of the domain to allow you to use your own DNS Zone.
* When AWS says "private DNS", it just means your own domain (eg. `tacoform.com`). It doesn't mean private or public DNS zones.
* During initial provisioning, you may run into errors related to the private DNS not validating in time, you can re-run the validation step by grabbing the VPC Endpoint Service ID and re-validating via `awscli`:

```bash
$ VPCE_SERVICE_ID=$(terraform output -raw vpce_service_id)
$ aws ec2 start-vpc-endpoint-service-private-dns-verification --service-id $VPCE_SERVICE_ID --region us-east-2
```

### Provision PrivateLink Resources in Consumer VPC

After the "private DNS" has been verified, you are now ready to connect Consumer VPCs to the `tostada` service in your Provider VPC. To do this, I would start with another terraform workspace/stack/etc. You only need to provision a Security Group and VPC Endpoint resource, but I would still put them into a module:

```hcl
resource "aws_security_group" "consumer" {
  name        = "tostada-${local.vpc_name}"
  description = "${local.vpc_name} tostada security group"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "tostada-${local.vpc_name}"
    })
  )
}


resource "aws_vpc_endpoint" "privatelink" {
  private_dns_enabled = true # allows custom domain usage instead of AWS provided DNS name
  service_name        = data.aws_vpc_endpoint_service.privatelink.service_name
  security_group_ids  = [aws_security_group.consumer.id]
  subnet_ids          = data.aws_subnets.private.ids
  vpc_endpoint_type   = "Interface"
  vpc_id              = data.aws_vpc.selected.id
}
```
_Note: To see the entire module, you can visit the [VPC Endpoint module](https://github.com/jperez3/taccoform-privatelink-demo/tree/main/infra/modules/vpc-endpoint)_


If you put the two resources in a module, you can group together Consumer VPCs in the same AWS account to avoid needing separate workspaces per Consumer VPC:
```hcl
module "service_consumer" {
    source = "../../modules/vpc-endpoint"

    for_each = {
        consumer-prod = {
            vpc_name = "consumer-prod"
        },
    }

    env                = "prod"
    service            = "tostada"
    vpc_name           = each.value.vpc_name
}
```
_Note: To see the entire module, you can visit the [VPC Endpoint module](https://github.com/jperez3/taccoform-privatelink-demo/tree/main/infra/modules/vpc-endpoint)_



### Validating Connectivity From The Consumer VPC To Provider VPC

Once the module is provisioned in the [service-consumer workspace](https://github.com/jperez3/taccoform-privatelink-demo/tree/main/infra/workspaces/service-consumer), you can move on to validating the HTTPS connection from a jumpbox in the Consumer VPC to the `tostada` service in the Provider VPC. You can use the [aws-connect](https://github.com/rewindio/aws-connect) tool again to "ssm" into the Consumer VPC's jumpbox and `curl` the endpoint to validate connectivity:

```bash
$ aws-connect -n jumpbox0-consumer-prod -r us-east-2
Establishing session manager connection to jumpbox0-consumer-prod (i-01f12a90d03e99d60)

Starting session with SessionId: taccoform-05f4d141e79540cf6
sh-4.2$ curl https://tostada.provider-prod.tacoform.com
<html><body><h1>IT'S TOSTADA TIME</h1></body></html>
```

You can also check DNS with `dig` to see how the Consumer VPC DNS resolves the request for `tostada.provider-prod.tacoform.com` and points them to Elastic Network Interfaces (ENIs) assigned to the VPC Endpoint for the `tostada` PrivateLink config:

```bash
$ dig tostada.provider-prod.tacoform.com +noall +answer

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.amzn2.5.2 <<>> tostada.provider-prod.tacoform.com +noall +answer
;; global options: +cmd
tostada.provider-prod.tacoform.com. 60 IN A     10.2.3.124
tostada.provider-prod.tacoform.com. 60 IN A     10.2.4.142
```
_Note: Notice how the IPs live within the CIDR block we've created for the Consumer VPC (10.2.0.0/16)_

If you deployed the `vpc`, `tostada`, and `vpc-endpoint` modules, be sure to destroy those workspaces to avoid any unnecessary AWS charges



### In Review

We've set up two VPCs (one Consumer, one Provider) and created a one way trust allowing resources in the Consumer VPC to reach the `tostada` web service in the Provider VPC. This simple example can be expanded by mapping one Provider VPC service to **many** Consumer VPCs (as long as they are in the same region which is an AWS limitation.) In the future, AWS can expand the resources to share across PrivateLink which will make it even more useful. That being said, the main use-case of sharing web services is compelling enough to start using PrivateLink.




---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
