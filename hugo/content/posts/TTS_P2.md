+++
title =  "Taccoform Tutorial Series - Part II"
tags = ["terraform", "tutorial", "digitalocean", "terraform13"]
date = "2020-10-26"
+++


# Overview



* DRY 
* `count`
* splat
* `for_each`


### DRY (Don't Repeat Yourself)

With the information you have right now, you would think to yourself that you just need to define another resource

`droplet.tf`
```hcl

resource "digitalocean_droplet" "web1" {
  image     = "ubuntu-20-04-x64"
  name      = "web1-burrito-prod"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [data.digitalocean_ssh_key.root.id]
  user_data = templatefile("templates/user_data_nginx.yaml", { hostname = "web1-burrito-prod" })
}

resource "digitalocean_droplet" "web2" {
  image     = "ubuntu-20-04-x64"
  name      = "web2-burrito-prod"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [data.digitalocean_ssh_key.root.id]
  user_data = templatefile("templates/user_data_nginx.yaml", { hostname = "web2-burrito-prod" })
}

```


### Count

`droplet.tf`
```hcl
resource "digitalocean_droplet" "web" {
  count = 2

  image     = "ubuntu-20-04-x64"
  name      = "web${count.index}-burrito-prod"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [data.digitalocean_ssh_key.root.id]
  user_data = templatefile("templates/user_data_nginx.yaml", { hostname = "web${count.index}-burrito-prod" })
}
```


* Running a `terraform plan` will show you what will be provisioned:

```hcl
Terraform will perform the following actions:

  # digitalocean_droplet.web[0] will be created
  + resource "digitalocean_droplet" "web" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-20-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + ipv6_address_private = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "web1-burrito-prod"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + ssh_keys             = [
          + "28662501",
        ]
      + status               = (known after apply)
      + urn                  = (known after apply)
      + user_data            = "331465f904afe38c2787224a5c3958cb0b83e184"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

  # digitalocean_droplet.web[1] will be created
  + resource "digitalocean_droplet" "web" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-20-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + ipv6_address_private = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "web2-burrito-prod"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + ssh_keys             = [
          + "28662501",
        ]
      + status               = (known after apply)
      + urn                  = (known after apply)
      + user_data            = "f61ed69ba1092537492203cb4472cf66a13eb763"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

* Notice how an index is appended to the end of the resource, this is how terraform helps you keep track of unique resources. 
 -  eg. `digitalocean_droplet.web[0] will be created`



#### Pros
* Adheres to DRY (Don't Repeat Yourself)
* Simple to follow and implement
* Follows strict naming convention
* Great for creating identical resource (eg. web servers)

#### Cons
* Terraform can get in a non-ideal state when adding/removing resources due to list iteration
* Only able to handle simple configurations


### For Each




```hcl
  # digitalocean_droplet.web["web0"] will be created
  + resource "digitalocean_droplet" "web" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-20-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + ipv6_address_private = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "web0-burrito-prod"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + ssh_keys             = [
          + "28662501",
        ]
      + status               = (known after apply)
      + urn                  = (known after apply)
      + user_data            = "9af6308fba3c408e311eea495a9d288fae5e84b6"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

  # digitalocean_droplet.web["web1"] will be created
  + resource "digitalocean_droplet" "web" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-20-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + ipv6_address_private = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "web1-burrito-prod"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + ssh_keys             = [
          + "28662501",
        ]
      + status               = (known after apply)
      + urn                  = (known after apply)
      + user_data            = "331465f904afe38c2787224a5c3958cb0b83e184"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy
```


#### Pros
* Adheres to DRY (Don't Repeat Yourself)
* Allows for more complex configurations
* Doesn't get tripped up by adding/removing resources
* Loose naming convention

#### Cons
* Syntax can get messy
* Harder to follow what's going on
* Outputs are way more complicated than `count`