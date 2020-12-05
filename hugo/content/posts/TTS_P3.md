+++
title =  "Taccoform Tutorial Series - Part III"
tags = ["terraform", "tutorial", "digitalocean", "terraform13", "variables", "load_balancer"]
date = "2020-11-09"
draft = true
+++


# Overview


# Lesson 3

### Variable creation

##### anatomy of a variable

```hcl
variable "env" {
  description = "short and unique environment name"
  default     = "prod"
}
```

| Component            | Description                                                                              |
| :------------------- | :--------------------------------------------------------------------------------------- |
| description          | an optional parameter, but I strongly suggest assigning one to every variable            |
| default              | an optional parameter that assigns a default value to the variable if one isn't provided |


* In the example above we've created a string variable, but you can also create variables which are booleans, integers, lists and maps.

_list example_

```hcl
variable "private_networks" {
  description = "a list of default private networks"
  default     = ["10.0.0.0/24","10.0.1.0/24","10.0.2.0/24]
}
```

_integer example_

```hcl
variable "droplet_count" {
  description = "the amount of droplets to provision"
  default     = 2
}
```

_boolean example_

```hcl
variable "droplet_monitoring" {
  description = "boolean controlling whether monitoring agent is installed"
  default     = true
}
```

_map example_

```hcl
variable "droplet_names" {
  description = "map of droplet names"
  default = {
        "web0" = "web0-burrito-prod"
        "web1" = "web1-burrito-prod"
    }
}
```

### Variable naming

Variable naming isn't always easy, but there are a couple things that I've picked up on:


* If there is a variable that you want to set to a paramater in a resource definition, be sure you align the variable name to the parameter.
    - eg.    

```hcl
resource "digitalocean_droplet" "web" {

  image  = var.droplet_image
  ...
  ...

}
```
_Notice the `droplet_` prefix, this helps when you have different resource definitions with similar parameter names._ 

* You will also have variables that will be used by multiple resource definitions. Some of these variables will be consistent across all of your resources which require them. An example of this type of variable in DigitalOcean is `region`. It's likely that you would want to build resources which work together and a common cloud provider constraint is that all complimentary resources must reside in the same geographic region. Each cloud provider has created their own shorthand for the geographic regions they've created to host your resources. 
    - eg.

```hcl
resource "digitalocean_droplet" "web" {

  image  = var.droplet_image
  ...
  region = var.region

}

resource "digitalocean_loadbalancer" "web" {

  ...
  region = var.region
  ...

}
```

* Another type of variable that is used across multiple resource definitions will be specific to you and/or your company. These variables will help inforce standardized naming and provide uniquness to the resources that you have created. Common variables of this type are `service` (or `app`) and `env` (or `environment`)
    - eg.

```hcl
resource "digitalocean_droplet" "web" {

  image  = var.droplet_image
  name   = "web-${var.service}-${var.env}"
  region = var.region

}

resource "digitalocean_loadbalancer" "web" {

  name   = "lb-${var.service}-${var.env}"
  region = var.region
  ...
  
}
```
_The quotes/`$`/curly brackets are necessary because some variable interpolation is happening prior to passing the value to the resource definition's `name` parameter. `droplet_image` and `region` are passed to the resource definition "as-is", so they don't require the extra formatting. You might wonder why we don't just set the interpolation as the `default` when creating the variable, but terraform doesn't allow you to do this in regular variables._ 

### Variable organization
    - in .tf files
    - in environment variables
    - .tfvars
### Variable validation 
### Local Variables
    - vs regular variables
### Load balancer creation
* functions:
    - length
    - replace
    - lower
    - upper
    - timestamp



### Pre-Flight



## In Review


## Conclusion 
