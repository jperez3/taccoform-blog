+++
title =  "How Do I Retrieve VPC Names Via Terraform?"
tags = ["terraform", "tutorial", "aws", "data-source", "vpc", "tagging", "tags"]
date = "2023-07-04"
+++


![Lobster](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfg_p7/lobster.jpg)


# Overview

At some point in your AWS and Terraform journey, you may need the names of the VPCs in a given AWS region. You'd normally look to use a data source lookup, but the name field is not exposed as an attribute for `aws_vpcs`. Here's a quick way to get those VPC names.


## Lesson

You will still need to use the `aws_vpcs` data source to get a list of all the VPC IDs in a given region:

```hcl
data "aws_vpcs" "in_region" {}
```

This will give you information on the VPCs in your region based on the AWS credentials you provide to Terraform. Most notably, it will give you the VPC IDs.


You will now need to pass the list of VPC IDs to the `aws_vpc` (singular) to expose more information about each VPC:

```hcl
data "aws_vpc" "selected" {
  for_each = toset(data.aws_vpcs.in_region.ids)
  id       = each.value
}
```

If you output the `aws_vpc` data source, you will see a lot of information, most of which you don't need. To organize and filter the output a bit more, we'll create a map with the VPC's name as the `key` and VPC's ID as the `value` in a local variable:

```hcl
locals {
  vpc_map = { for vpc_id, vpc_info in data.aws_vpc.selected : vpc_info.tags["Name"] => vpc_id }
}
```

In the `vpc_map` local variable, we're looping over what the `aws_vpc` data source returned and creating a map of key value pairs with the VPC's `Name` tag value. The `=>` separates the `key` from the `value` and then the `vpc_id` is set as the value. You can validate the map by creating an output and running terraform plan/apply:

```hcl
output "vpc_map" {
  value = local.vpc_map
}
```

_**NOTE**:If you get an error, there's a good chance that a VPC in your region does not have a `Name` tag associated with it. To remedy this problem, either log into the AWS console or use `awscli` to give each VPC in the region a proper `Name` tag._

If you are just interested in a list of the VPC names, you can add another local variable called `vpc_names_all`:

```hcl
locals {
  vpc_map       = { for vpc_id, vpc_info in data.aws_vpc.selected : vpc_info.tags["Name"] => vpc_id }
  vpc_names_all = [for vpc_name, vpc_id in local.vpc_map : vpc_name]
}
```

Notice how we're using square brackets instead of curly brackets this time to signify that this new `vpc_names_all` local variable should output a `list` instead of a `map`. We're using `for` again to loop through the `vpc_map` local variable and just adding the VPC's name to the list.

There may be times where you will need to exclude specific VPCs from the VPC names list. You can do this by creating another local variable list:

```hcl
locals {
  vpc_map            = { for vpc_id, vpc_info in data.aws_vpc.selected : vpc_info.tags["Name"] => vpc_id }
  vpc_names_all      = [for vpc_name, vpc_id in local.vpc_map : vpc_name]
  vpc_names_filtered = [for vpc_name, vpc_id in local.vpc_map : vpc_name if !contains(["default"], vpc_name)]
}
```

The new `vpc_names_filtered` local variable is based on the `vpc_names_all` local variable that we previously created with an additional `if` statement. This basically says "add this `vpc_name` if it isn't in this list (`["default"]`.) You can also assign a variable with a list of excluded vpc names to keep this local variable tidy. Having an option to exclude VPCs allows you to do things like de-provision/rebuild a resource in specific VPCs without disturbing other deployments.


Adding outputs for `vpc_names_all` and `vpc_names_filtered` should result in a `terraform plan` like the one below:


```bash
Changes to Outputs:
  + vpc_map            = {
      + birria  = "vpc-0123456789abcdefg"
      + default = "vpc-12345678"
      + flan    = "vpc-abcdefghij0123456"
    }
  + vpc_names_all      = [
      + "birria",
      + "default",
      + "flan",
    ]
  + vpc_names_filtered = [
      + "birria",
      + "flan",
    ]

```


Here is the full code from the above steps:

`variables.tf`
```hcl
data "aws_vpcs" "in_region" {}

data "aws_vpc" "selected" {
  for_each = toset(data.aws_vpcs.in_region.ids)
  id       = each.value
}

locals {
  vpc_map            = { for vpc_id, vpc_info in data.aws_vpc.selected : vpc_info.tags["Name"] => vpc_id }
  vpc_names_all      = [for vpc_name, vpc_id in local.vpc_map : vpc_name]
  vpc_names_filtered = [for vpc_name, vpc_id in local.vpc_map : vpc_name if !contains(["default"], vpc_name)]
}

output "vpc_map" {
  value = local.vpc_map
}

output "vpc_names_all" {
  value = local.vpc_names_all
}

output "vpc_names_filtered" {
  value = local.vpc_names_filtered
}
```




### In Review

Ok now we have the VPC information that we need, how do we use it? You can now pass these lists to terraform modules using `for_each` to simplify your deployments in a given region. If a new VPC comes online, no changes to the code needs to happen, a `terraform apply` should remediate any differences. These are a couple of the benefits when it comes to working with multiple VPCs. You can also use this same exact method to pull tag information from other data source lookups where the information you need isn't built into the AWS response.


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
