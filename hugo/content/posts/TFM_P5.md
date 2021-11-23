+++
title =  "A cost effective alternative to Managed NAT Gateways"
tags = ["terraform", "tutorial", "aws", "terraform1"]
date = "2021-11-22"
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfm_p5/header.jpg)


# Overview

You've decided to focus on learning AWS, but you keep seeing tweets that warn you about the cost of Managed NAT Gateways. The thought of receiving an outragous bill makes you sick to your stomach. The AWS docs don't really help you with alternatives and the "Hello World" tutorials don't tell you how to avoid the big bill. Don't worry, today we're gonna go over Managed NAT Gateways and a cheaper alternative for you to use while learning all 150+ AWS services. 


## Lesson

* What is a NAT?
* NAT Gateway Vs NAT Instance
* Developer NAT Instance VPC
* NAT Instance VPC deployment


### What is a NAT?

A NAT is a device which allows servers on your private networks to reach the Internet. Without an NAT, your servers can't interact with outside services and run updates. This is like having a taco truck without windows and trying to take orders. Yes you can work around this obstacle, but it's not an efficient way to work. 

For a deeper dive into VPC components, check out J Cole Morrison's [AWS VPC Core Concepts](https://start.jcolemorrison.com/aws-vpc-core-concepts-analogy-guide/)

### NAT Gateway Vs NAT Instance


A Managed NAT Gateway is an AWS managed service which provides a highly available NAT. This hands off approach costs $37/month (+bandwidth) and you need at least one deployed per VPC. A cheaper approach would be to deploy EC2 instances in your public networks to serve as a NAT and is commonly known as a NAT Instance. You can host a NAT Instance for as little as $3/month. It's important to note that using a NAT Gateway in production is considered a best practice for those who don't want to build and maintain the additional redundancy. From an operational perspect, you should eat the cost of a NAT gateway in production because it will be one less thing to worry about. In lower and/or ephemeral environments, you stand to save a lot of money by using NAT Instances. 



### Developer NAT Instance VPC 

Another good use of VPCs with NAT Instances is for learning AWS. Accidentally leaving a NAT Gateway provisioned and receiving that AWS bill will definitely kill your motivation. Forgetting to remove NAT instances will sting less. I decided to dig into how to build a NAT gateway for developers and found a couple [great](https://www.kabisa.nl/tech/cost-saving-with-nat-instances/) [resources](https://github.com/Disgruntled/terraform_examples) as jump off points. Once I understood the requirements, I decided to build a low cost [NAT Instance VPC module](https://github.com/jperez3/taccoform-modules/tree/main/vendors/aws/vpc/nat-instance). The module contains the VPC, subnets, routing tables, and NAT Instances. I chose to incorporate two NAT Instances to attach one to each availability zone to cut down on cross-AZ transfer costs. Even with this decision, the projected cost is ~$6/month using `t4g.nano` Gravitron2 instances.    

|                     | Month 1 | Month 2 | Month 3 | Month 4 | Month 5 | Month 6 |
| :------------------ | :------ | :------ | :------ |:------- |:------- |:------- |
| Managed NAT Gateway | $37     | $74     | $111    | $148    | $185    | $222    |
| 2 NAT Instances     | $6      | $12     | $18     | $24     | $30     | $36     |

_It will take 6 months of two NAT Instances (`t4g.nano`) to catch up to the 1st month cost of **one** Managed NAT Gateway._


### NAT Instance VPC deployment


1. In a new folder, create a `provider.tf` file with the appropriate `aws` provider information:

`provider.tf`
```hcl

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.64.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}
```

2. Create a `vpc.tf` file:


`vpc.tf`
```hcl
module "vpc" {
  source = "git::git@github.com:jperez3/taccoform-modules.git//vendors/aws/vpc/nat-instance?ref=aws-vpc-ni-v1.0.0"

  env = "prod"

  cidr_block              = "10.45.0.0"
  enable_jumpbox_instance = true
}

output "nat_instance_ids" {
  value = module.vpc_testing.nat_instance_ids
}

output "jumpbox_instance_id" {
  value = module.vpc_testing.jumpbox_instance_id
}

```
_Note: this will also create a jumpbox that will help validate the NAT Instance connectivity_


3. Run `terraform init`, then `terraform apply`

```bash
...
...
...
Plan: 21 to add, 0 to change, 0 to destroy.
```
4. Install the [AWS Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) and use `aws ssm` and the jumpbox instance id from the terraform output to connect:

```bash
aws ssm start-session --target JUMPBOX_INSTANCE_ID_GOES_HERE
```

5. Once connected, you can use `mtr google.com` to confirm that the jumpbox on the private network is routing traffic through the NAT instance:

```bash
ip-10-45-6-123.ec2.internal (10.45.6.123)                                    2021-11-22T16:09:08+0000
Keys:  Help   Display mode   Restart statistics   Order of fields   quit
                                                             Packets               Pings
 Host                                                      Loss%   Snt   Last   Avg  Best  Wrst StDev
 1. ip-10-45-66-111.ec2.internal                            0.0%    24    0.1   0.1   0.1   0.1   0.0
 2. ec2-3-236-63-179.compute-1.amazonaws.com                0.0%    24    7.6  16.0   1.4  84.3  21.8
 3. 243.254.23.78                                           0.0%    24    0.3   0.4   0.3   0.5   0.0
 4. 243.254.16.1                                            0.0%    24    0.3   0.3   0.2   0.4   0.0
 5. 240.192.55.3                                            0.0%    24    0.3   0.4   0.3   0.4   0.1
 6. 240.0.232.16                                            0.0%    24    0.3   0.3   0.2   0.3   0.0
 7. 240.0.232.1                                             0.0%    24    0.3   0.3   0.2   0.3   0.0
 8. 243.253.17.246                                          0.0%    24    0.4   0.4   0.4   0.5   0.0
 9. 240.0.28.17                                             0.0%    24    0.4   0.4   0.3   0.4   0.0
10. 240.0.28.4                                              0.0%    24  689.6 647.6 517.3 720.6  46.8
11. 242.0.146.49                                            0.0%    24    0.4   1.0   0.3   6.4   1.7
12. 52.93.28.207                                            0.0%    24    0.8   1.1   0.5   4.1   0.9
13. 100.100.34.90                                           0.0%    24    0.7   2.0   0.5  18.9   4.0
14. 72.14.203.158                                           0.0%    24    6.8   1.8   1.1   6.8   1.5
15. 172.253.64.251                                          0.0%    24    1.0   1.0   1.0   1.0   0.0
16. 216.239.48.15                                           0.0%    24    1.9   1.8   1.5   2.3   0.1
17. iad23s61-in-f14.1e100.net                               0.0%    23    0.9   0.9   0.9   1.0   0.0

```
_Note: the first hop should be the private IP of the NAT Instance in the same AZ as the jumpbox. Press `q` to quit `mtr`._ 


6. End the `ssm` session and destroy provisioned VPC: `terraform destroy` 

* The VPC module [README](https://github.com/jperez3/taccoform-modules/blob/main/vendors/aws/vpc/nat-instance/README.md) has more examples and even a minimal deployment which should help while you learn the ins and outs of VPCs.

### In Review

Using NAT Instances can be a viable alternative to Managed NAT Gateways for those who want to learn AWS and don't want to break the bank. Managed NAT Gateways do have an important role to play, but let's keep them on the corporate AWS bill. 

---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
