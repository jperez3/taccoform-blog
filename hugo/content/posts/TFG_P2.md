+++
title =  "Elevate your AWS environment with tagging and Terraform"
tags = ["terraform", "aws", "tagging"]
date = "2021-07-28"
+++


![Margaritas](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfg_p2/header.jpg)


# Overview

* What are tags? 
* Why should I care about tags? 
* How can I create tags? 
* How do I query tags?  


## Lesson

### What are tags?

In AWS, tags are metadata that you can attach to AWS resources like ec2 instances, rds databases, and s3 buckets. The tags are create as key/value pairs and can be queried by tools like [awscli](https://aws.amazon.com/cli/) and Terraform. 

### Why should I care about tags?

When done right, tags can make automation easier and more efficient. Standardizing tags enables:
* Developers to query the information they need without a lot of work. 
* Management to easily see how much each service costs and who is responsible for the huge AWS bill
* Infrastructure Engineers to breathe a sigh of relief because AWS environments are more manageable and consistent 

### How can I create tags? 

Tags can be created via the AWS Console and in Terraform. For consistency sake, Terraform is the preferred method for creating tags. There are currently two different levels at which you can define tags. You can define tags on the AWS resource definitions that allow tags and more recently at the AWS provider level. Tags at the AWS provider level are great for establishing a blanket approach to tagging all resource created by Terraform in a workspace. Tags created at the resource level take precedence over ones created at the AWS provider level.  

#### Provider Level Tags

I recommend defining more general tags at the AWS provider level. Things like the git repo folder path and environment:

```hcl
provider "aws" {
  ...
  ...
  ...

  default_tags {
    tags = {
      Environment = "prod"
      TFWorkspace = "taccoform-blog/terraform/app"
    }
  }
}
```


#### Resource Level Tags

You can verify if a resource allows tagging by checking out the resource's documentation page. For example, the `aws_instance` resource [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#tags) shows that it indeed supports tagging. If you wanted to tag this resource, I would start by defining shared tags that you'd want associate with every resource in your terraform module. You can define `common` tags by creating a local variable map of those tags.

`variables.tf`
```hcl
variable "env" {
  description = "unique environment name"
  default     = "prod"
}

variable "service" {
  description = "unique service name"
  default     = "burrito"
}


locals {

  common_tags = {
    Service   = var.service
    ManagedBy = "terraform"
    Team      = "el-compadre"
  }
}
```

When you want to apply those `common_tags` to a resource, you will need to merge that map with any tags which will uniquely identify that resource.


`ec2.tf`
```
resource "aws_instance" "web" {
  count = var.instance_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = merge(
    var.common_tags,
    {
      Name = "web${count.index}-${var.service}-${var.env}"
    },
  )
}
```
Above we're using `count` with the `aws_instance` resource to create and maintain uniquely named ec2 instances. We're also merging those more general tags with the `Name` tag so that we can apply consistent tagging to this resource and other resources created in this module.



### How do I query tags?

You can query tags via Data Source lookups. If you go into the Terraform documentation, you will see two headings under each AWS hosted service, Resources and Data Sources. Resources is where you'll get information on how to deploy resources and Data Sources is where you'll get information on how to query existing resources. You might want to query things like VPC and subnet information to feed your ec2 instances. 

`data_source.tf`
```hcl

data "aws_vpc" "selected" {
  
  filter {
    name   = "tag:Name"
    values = ["vpc-1"] 
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.selected.id

  filter {
    name   = "tag:Zone"
    values = ["private"]
  }
}
```

The values have been hard-coded here for visibility, but these are generally fed to the module as input variables. You can see that we need to lookup the [VPC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) `Name` tag in order to get the subnet IDs. When it comes to the data source lookup for [aws_subnet_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) we're filtering and/or matching based on the `Zone` tag. The zone tag would be created in your VPC module when the subnet was created. Without this lookup, the VPC and this ec2 module would need to live in the same Terraform workspace for the subnet ID handoff. This is not ideal because it means that every resource that needs subnet IDs would need to live in the same Terraform Workspace as your VPC. Using tagging in this way allows you to loosely couple your base infrastructure and the services that rely on it. 

Now that we've looked up that information, we can apply it to the ec2 instance:

`ec2.tf`
```
resource "aws_instance" "web" {
  count = var.instance_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = element(tolist(data.aws_subnet_ids.private.ids), count.index)

  tags = merge(
    var.common_tags,
    {
      Name = "web${count.index}-${var.service}-${var.env}"
    },
  )
}
```
In the `subnet_id` parameter above, we're converting the subnet_ids `set` to a `list` so that we can loop over it and place each provisioned instance across subnets (and Availability Zones.) If the instance count is higher than the number of subnet IDs in the list, the instance creation would continue by starting again at the beginning of the subnet ID list. 

#### Common Data Source Lookups 

Here are a few examples of data source lookups you can do with tag-based filters:
* Grab Security Group IDs to attach to resources
* Filter by VPC name tag for resource placement
* Attaching instances to target group created in a different workspace 

Some of the more common data source lookup don't even require a tag filter. You can do things like: 

* Grab a certificate required to attach to an Application Load Balancer
* Query the zone ID for a DNS record creation via the the zone name 
* Look up a secret from AWS Secrets Manager to feed into a resource 

### In Review


We've only explored the tip of the iceberg here, but as you experiment more with tagging, it will become clearer that the combination of tags and data source lookups are incredibly powerful. Without tagging, we would put all of our resources in one Terraform workspace and pray to the HashiCorp Gods every time we ran `terraform apply`


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
