+++
title =  "Composed Service Modules"
tags = ["terraform", "tutorial", "digitalocean", "terraform14"]
date = "2021-05-05"
+++


![Nachos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfm_p3/header.jpg)


# Overview


## Lesson

* Terraform Module Review
* Using Vendor Modules to create Composed Service modules
* Verifying Composed Service modules
* Versioning Composed Service modules
* Updating Composed Service modules

### Terraform Module Review

In the previous entry, I brought up two types of modules, vendor specific and composed services. Vendor specific modules are smaller modules which are focused on creating resources from a single provider. Think of vendor specific modules as consistent/repeatable instructions to perform a specific task like grilling chicken. Composed services are the combining smaller vendor specific modules into one functional service. Think of composed services as an order of nachos. Nachos are the combination of multiple layers and/or ingredients. But be careful with how many layers and ingredients you add, your chicken nachos (and terraform modules) can become a soggy mess. 

#### Vendor Specific Modules

* Small pieces of terraform code like creating a DigitalOcean droplet
* Only uses one terraform provider because passing multiple providers to a module can create unintentional dependencies between providers (eg. when a provider's API has an outage)
* It should only contain resources, data source lookups, and variables. Don't nest modules inside vendor specific modules because you'll regret that complexity when you're troubleshooting later.

#### Composed Service Modules

* A module composed of one or more vendor specific modules, data source lookups, and variables
* Only uses one terraform provider because passing multiple providers to a module can create unintentional dependencies between providers (eg. when a provider's API has an outage)
* You should stray away from using individual resource definitions because you can introduce inconsistencies in your cloud environment, but sometimes it's unavoidable.



### Using Vendor Modules to create Composed Services


In the previous post, we created a droplet terraform module (vendor specific module) and I've created a load balancer terraform module to show you how we can have those two modules come together as a compose service. We'll call this composed service "nachos." 

1. Create new `tacco-corp>services>nachos` folders in a git repo of your choice
```
tacco-corp
└── services
    └── nachos
```
_Note: Creating this organization layer allows you to add new services in the future_

2. In the `nachos` folder create a `provider.tf` file to store provider information

`provider.tf`
```hcl
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0.0"
    }
  }
  required_version = "~> 0.14.0"
}
```

3. In the `nachos` folder create a `variables.tf` file to house your composed service variables

`variables.tf`
```hcl
variable "env" {
  description = "unique environment name"
  default     = "stg"
}

variable "service" {
  description = "unique service name"
  default     = "nachos"
}
```

4. In the `nachos` folder create `droplet.tf` to keep your droplet vendor module in order

`droplet.tf`
```hcl
module "droplet" {
  source = "git::git@github.com:jperez3/taccoform-modules.git//vendors/digitalocean/droplet?ref=do-droplet-v1.0.1"

  env     = var.env
  service = var.service
}

output "droplet_ids" {
  value = module.droplet.droplet_ids
}

```

5. In the `nachos` folder create a `load_balancer.tf` file to keep your load balancer module and variables organized

`load_balancer.tf`
```hcl

module "loadbalancer" {
  source = "git::git@github.com:jperez3/taccoform-modules.git//vendors/digitalocean/load-balancer?ref=do-lb-v1.0.0"

  env         = var.env
  droplet_ids = module.droplet.droplet_ids
  service     = var.service
}

output "lb_public_ip" {
  value = module.loadbalancer.public_ip
}

```
_Note: Notice how we're passing `module.droplet.droplet_ids` (a droplet module output) to the load balancer module. This is telling terraform that the droplet module needs to be created **before** the load balancer module. Sometimes terraform doesn't honor this ordering, but that's a story for another time._

### Verifying Composed Service modules


### Versioning Composed Service modules


### Updating Composed Service modules



### In Review



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
