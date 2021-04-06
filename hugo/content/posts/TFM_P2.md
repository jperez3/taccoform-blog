+++
title =  "Creating a Terraform Module"
tags = ["terraform", "tutorial", "digitalocean", "terraform14"]
date = "2021-11-07"
draft = true
+++


![Photo by T. Kaiser](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tts_p1/header.jpg)


# Overview




## Lesson

* What is a Terraform Module?
* Organizating Terraform Modules
* Creating a DigitalOcean droplet module
* Testing the DigitalOcean droplet module
* Versioning the DigitalOcean droplet module


### What is a Terraform Module?

A terraform module is a templated verison of Terraform resource definitions, variables, and data source lookups. Terraform modules are great to build because they make your work easily reproducible, enforces naming consistency, and makes it easy for others to build off of your work. For more information on modules, check out [The Who, What, Where, When, and Why of Terraform Modules](https://www.taccoform.com/posts/tfm_p1/)


### Organizating Terraform Modules

Terraform modules can be hosted in several ways, I prefer to host them via git and in their own repository. 

1. Start by creating a new private repo named `tf-modules`. Since this is a private repository, any person (or machine) that wants to use your terraform modules will need read access to the repo.
2. Create a new branch in that repo, eg `new-droplet-module`
3. Create a two folders in the root of your new repository `vendors` and `tacco-corp` 
   1. `vendors` is where you'll put terraform modules from cloud providers with terraform providers
   2. `tacco-corp` is where you'll put terraform modules that are comprised of one or more vendor modules to create a composed service for our Tacco-Corp company. Think of composed services as a meal coming together like a plate of fajitas, rice, beans, and a salt-rimmed margarita. In cloud provider terms this could be a composed service with a load-balancer, virtual machine, and database.
4. In the vendors folder, create `digitalocean` and in that folder create a `droplet` folder.

_Your folder structure should look something like this_

```
tf-modules
├── tacco-corp
└── vendors
    └── digitalocean
        └── droplet
```

Starting with a well-organized terraform module repo will help keep things clean and predictable as your team and company grows. In a later post, we'll go over further organization of your `tacco-corp` folder, today we will be focusing on creating a simple vendor module.


### Creating a DigitalOcean droplet module

1. Inside the `droplet` folder, create `droplet.tf`, `droplet_variables.tf`, `provider.tf`, and `variables.tf`
   1. `droplet.tf` will house resource definitions for the droplet itself and any directly related resources
   2. `droplet_variables.tf` will house the variable definitions related to resources in the `droplet.tf` file
   3. `provider.tf` will house terraform provider information and any terraform state management
   4. `variables.tf` will house any variables which can be used by multiple `.tf` files
2. Take a look at the [digitalocean_droplet](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet) documentation. You may notice that the example sets four requried parameters (`image`, `name`, `region`, and `size`.) The optional parameters have default values set, so you don't need to define them unless you want to change them or anticipate needing to change them in the future.
3. Copy the example resource definition from the `digitalocean_droplet` documentation to your `droplet.tf` file

`droplet.tf`
```hcl
resource "digitalocean_droplet" "web" {
  image  = "ubuntu-18-04-x64"
  name   = "web-1"
  region = "nyc2"
  size   = "s-1vcpu-1gb"
}
```

4. Let's add an optional parameter because we want to take advantage of a feature that isn't enabled by default. Add the `monitoring` parameter to the resource definition

`droplet.tf`
```hcl
resource "digitalocean_droplet" "web" {
  image      = "ubuntu-18-04-x64"
  monitoring = true
  name       = "web-1"
  region     = "nyc2"
  size       = "s-1vcpu-1gb"
}
```
_Note: Setting the parameters in alphabetical order and aligning the `=` signs doesn't change how terraform interprets the resource definition, but it will make your code a lot more readable_


5. Add `count` to have the ability to change how many instances are created

`droplet.tf`
```hcl
resource "digitalocean_droplet" "web" {
  count = 2

  image      = "ubuntu-18-04-x64"
  monitoring = true
  name       = "web-1"
  region     = "nyc2"
  size       = "s-1vcpu-1gb"
}
```
_Note: It's a common practice to define `count` at the top and separated from the other parameters because `count` is not a parameter of the resource you are defining, but more of a built-in function of terraform. Count can be used to create multiple instances of a resource, conditionally create a resource, or disable it all together by setting it to zero_

6. Create variables in `droplet_variables.tf` for `droplet_count`, `droplet_image`, `droplet_monitoring`, `droplet_node_type` and `droplet_size`. Creating variables for these parameters gives us flexibility later when we want to customize the droplet(s) we're provisioning with the droplet module


`droplet_variables.tf`
```hcl

variable "droplet_count" {
  description = "the number of droplets to provision"
  default     = 2
}

variable "droplet_image" {
  description = "the DigitalOcean droplet image ID"
  default     = "ubuntu-18-04-x64"
}

variable "droplet_monitoring" {
  description = "the DigitalOcean droplet image ID"
  default     = true
}

variable "droplet_node_type" {
  description = "the node/droplet/vm type, eg app, web, db"
  default     = "web"
}

variable "droplet_size" {
  description = "the DigitalOcean droplet size"
  default     = "s-1vcpu-1gb"
}
```
_Note: Always set a `description` because this will help you and your team understand what's going on._


7. Now create variables for `env`, `region`, and `service` in the `variables.tf` file. These variables are created in the `variables.tf` file because they can be used by the DigitalOcean droplet resource definition and other resources definitions

`variables.tf`
```hcl
variable "env" {
  description = "a short and unique environment name"
  default     = "prod"
}

variable "region" {
  description = "a DigitalOcean provided locale"
  default     = "sfo2"
}

variable "service" {
  description = "a short and unique service name"
}
```
_Note: The `default` parameter was intentionally left off of the variable definition for `service`. Omitting a `default` parameter tells terraform that `service` is a parameter that needs to be set by the user when they use this droplet module. This is different from setting a `parameter` to an empty string, empty list, or empty map. When you define a `default` parameter with an empty value, it will pass the value on to the resource definition which may be interpretted as that parameter not being set._

8. Fill in the `droplet` resouce definition with the variables you've created and change the resource definition to `vm` since this module may or may not define a `web` droplet

`droplet.tf`
```hcl
resource "digitalocean_droplet" "vm" {
  count = var.droplet_count

  image      = var.droplet_image
  monitoring = var.droplet_monitoring
  name       = "${var.droplet_node_type}${count.index}-${var.service}-${var.env}"
  region     = var.region
  size       = var.droplet_size
}
```
_Note: `${count.index}` tells terraform to set the variable as the current index set by the `count` variable. This index starts at `0`, but you can do `${count.index + 1}` to make the droplet names start at `1`.

9. In Terraform 13 and newer, providers not hosted by Hashicorp need to be called out in the module. Do this by adding the stanza below to your `provider.tf` file

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


### Testing the DigitalOcean droplet module




### Versioning the DigitalOcean droplet module




### In Review



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
