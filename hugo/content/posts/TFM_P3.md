+++
title =  "Composed Service Modules"
tags = ["terraform", "tutorial", "digitalocean", "terraform14"]
date = "2021-05-05"
+++


![Nachos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfm_p3/header.jpg)


# Overview

You've started building out terraform modules to help keep your Terraform workspaces DRY, but you've noticed that your terraform workspaces are filled with modules and you still have to remember how they all wire up together. In this post we'll go over how to create easy to deploy composed services so that anyone on your team can deploy services without needing to know how the individual resources interact with eachother.  

## Lesson

* Terraform Module Review
* Using Vendor Modules to create Composed Service modules
* Verifying Composed Service modules
* Versioning Composed Service modules

### Terraform Module Review

In the previous [post](https://www.taccoform.com/posts/tfm_p2/), I brought up two types of modules, vendor specific and composed services. Vendor specific modules are smaller modules which are focused on creating resources from a single provider. Think of vendor specific modules as consistent/repeatable instructions to perform a specific task like grilling chicken. Composed services are the combining smaller vendor specific modules into one functional service. Think of composed services as an order of nachos. Nachos are the combination of multiple layers and/or ingredients. But be careful with how many layers and ingredients you add, your chicken nachos (and terraform modules) can become a soggy mess. 

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


1. Create a new github repository called `taccoform-modules` (if you haven't already) and create a new branch called `nachos-module`
2. Create new `tacco-corp>services>nachos` folders in your ` taccoform-modules` repo:
```
tacco-corp
└── services
    └── nachos
```
_Note: Creating this organization layer allows you to add new services in the future_

3. In the `nachos` folder create a `provider.tf` file to store provider information

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
_Note: Needing to add a provider block to modules is a newer development, I believe it was introduced in terraform 0.14.x_

4. In the `nachos` folder create a `variables.tf` file to house your composed service variables

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

5. In the `nachos` folder create `droplet.tf` to keep your droplet vendor module in order

`droplet.tf`
```hcl
module "droplet" {
  source = "git::git@github.com:jperez3/taccoform-modules.git//vendors/digitalocean/droplet?ref=do-droplet-v1.1.1"

  env     = var.env
  service = var.service
}

output "droplet_ids" {
  value = module.droplet.droplet_ids
}

```

6. In the `nachos` folder create a `load_balancer.tf` file to keep your load balancer module and variables organized

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

Now that we've wired up the droplet and load balancer modules as a composed service module, we can start testing the nachos module to make sure it's doing what we want it to do.

1. Create `module-testing/nachos-test` in the root of your repository, it should look like this:


```
taccoform-modules
├── module-testing
│   └── nachos-test
└── tacco-corp
    └── services
        └── nachos
```

2. In `nachos-test` create `provider.tf`, `variables.tf`, and `nachos.tf`

`provider.tf`

```hcl
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0.0"
    }
  }
  required_version = "~> 0.14.10"
}


provider "digitalocean" {
  token = var.do_token
}
```

`variables`
```hcl
variable "do_token" {
  description = "DigitalOcean authentication token for terraform provider"
}

```


`nachos.tf`

```hcl
module "nachos" {
    source = "../../tacco-corp/services/nachos"

    env = "stg"
}


output "loadbalancer_ip" {
    value = module.nachos.lb_public_ip
}
```
_Note: the module `source` is using the relative path because we want to test what is local to our branch_

3. Run `terraform init` from the `nachos-test` directory, you should see:

```
$ terraform init
Initializing modules...
- nachos in ../../tacco-corp/services/nachos
Downloading git::git@github.com:jperez3/taccoform-modules.git?ref=do-droplet-v1.1.1 for nachos.droplet...
- nachos.droplet in .terraform/modules/nachos.droplet/vendors/digitalocean/droplet
Downloading git::git@github.com:jperez3/taccoform-modules.git?ref=do-lb-v1.0.0 for nachos.loadbalancer...
- nachos.loadbalancer in .terraform/modules/nachos.loadbalancer/vendors/digitalocean/load-balancer

Initializing the backend...

Initializing provider plugins...
- Finding digitalocean/digitalocean versions matching "~> 2.0.0"...
- Installing digitalocean/digitalocean v2.0.2...
- Installed digitalocean/digitalocean v2.0.2 (signed by a HashiCorp partner, key ID F82037E524B9C0E8)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

* In the module initialization step, you will see that it's using the relative path to get instructions for the nachos module and then the nachos module is like "hey, I actually need these vendor-specific modules. I have to reach out to github to retrieve them" 

4. Run `terraform plan` and you should see the output below:

```
$ terraform plan

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.nachos.module.droplet.digitalocean_droplet.vm[0] will be created
  + resource "digitalocean_droplet" "vm" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-18-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = true
      + name                 = "web0-nachos-stg"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + status               = (known after apply)
      + urn                  = (known after apply)
      + user_data            = "56c8e1b356a23cc4fc55dc3ff2bbb4d12cc46e61"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

  # module.nachos.module.droplet.digitalocean_droplet.vm[1] will be created
  + resource "digitalocean_droplet" "vm" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-18-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = true
      + name                 = "web1-nachos-stg"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + status               = (known after apply)
      + urn                  = (known after apply)
      + user_data            = "70f4f2b501bce1744200ec4d8e0c5c476a571a3a"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

  # module.nachos.module.loadbalancer.digitalocean_loadbalancer.lb will be created
  + resource "digitalocean_loadbalancer" "lb" {
      + algorithm                = "round_robin"
      + droplet_ids              = (known after apply)
      + enable_backend_keepalive = false
      + enable_proxy_protocol    = false
      + id                       = (known after apply)
      + ip                       = (known after apply)
      + name                     = "lb-nachos-stg"
      + redirect_http_to_https   = false
      + region                   = "sfo2"
      + status                   = (known after apply)
      + urn                      = (known after apply)
      + vpc_uuid                 = (known after apply)

      + forwarding_rule {
          + certificate_id   = (known after apply)
          + certificate_name = (known after apply)
          + entry_port       = 80
          + entry_protocol   = "http"
          + target_port      = 80
          + target_protocol  = "http"
          + tls_passthrough  = false
        }

      + healthcheck {
          + check_interval_seconds   = 5
          + healthy_threshold        = 5
          + path                     = "/"
          + port                     = 80
          + protocol                 = "http"
          + response_timeout_seconds = 5
          + unhealthy_threshold      = 3
        }

      + sticky_sessions {
          + cookie_name        = (known after apply)
          + cookie_ttl_seconds = (known after apply)
          + type               = (known after apply)
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + loadbalancer_ip = (known after apply)

```

* This plan output looks like what we expect it to, terraform is going to create two droplets and one load balancer

5. Run `terraform apply` to create the resources and confirm with `yes` when prompted:

```
$ terraform apply

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.nachos.module.droplet.digitalocean_droplet.vm[0] will be created
  + resource "digitalocean_droplet" "vm" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-18-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = true
      + name                 = "web0-nachos-stg"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + status               = (known after apply)
      + urn                  = (known after apply)
      + user_data            = "56c8e1b356a23cc4fc55dc3ff2bbb4d12cc46e61"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

  # module.nachos.module.droplet.digitalocean_droplet.vm[1] will be created
  + resource "digitalocean_droplet" "vm" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-18-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = true
      + name                 = "web1-nachos-stg"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + status               = (known after apply)
      + urn                  = (known after apply)
      + user_data            = "70f4f2b501bce1744200ec4d8e0c5c476a571a3a"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

  # module.nachos.module.loadbalancer.digitalocean_loadbalancer.lb will be created
  + resource "digitalocean_loadbalancer" "lb" {
      + algorithm                = "round_robin"
      + droplet_ids              = (known after apply)
      + enable_backend_keepalive = false
      + enable_proxy_protocol    = false
      + id                       = (known after apply)
      + ip                       = (known after apply)
      + name                     = "lb-nachos-stg"
      + redirect_http_to_https   = false
      + region                   = "sfo2"
      + status                   = (known after apply)
      + urn                      = (known after apply)
      + vpc_uuid                 = (known after apply)

      + forwarding_rule {
          + certificate_id   = (known after apply)
          + certificate_name = (known after apply)
          + entry_port       = 80
          + entry_protocol   = "http"
          + target_port      = 80
          + target_protocol  = "http"
          + tls_passthrough  = false
        }

      + healthcheck {
          + check_interval_seconds   = 5
          + healthy_threshold        = 5
          + path                     = "/"
          + port                     = 80
          + protocol                 = "http"
          + response_timeout_seconds = 5
          + unhealthy_threshold      = 3
        }

      + sticky_sessions {
          + cookie_name        = (known after apply)
          + cookie_ttl_seconds = (known after apply)
          + type               = (known after apply)
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + loadbalancer_ip = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.nachos.module.droplet.digitalocean_droplet.vm[0]: Creating...
module.nachos.module.droplet.digitalocean_droplet.vm[1]: Creating...
module.nachos.module.droplet.digitalocean_droplet.vm[0]: Still creating... [10s elapsed]
module.nachos.module.droplet.digitalocean_droplet.vm[1]: Still creating... [10s elapsed]
module.nachos.module.droplet.digitalocean_droplet.vm[0]: Still creating... [20s elapsed]
module.nachos.module.droplet.digitalocean_droplet.vm[1]: Still creating... [20s elapsed]
module.nachos.module.droplet.digitalocean_droplet.vm[1]: Still creating... [30s elapsed]
module.nachos.module.droplet.digitalocean_droplet.vm[0]: Still creating... [30s elapsed]
module.nachos.module.droplet.digitalocean_droplet.vm[1]: Creation complete after 33s [id=1234567890]
module.nachos.module.droplet.digitalocean_droplet.vm[0]: Creation complete after 35s [id=1234567891]
module.nachos.module.loadbalancer.digitalocean_loadbalancer.lb: Creating...
module.nachos.module.loadbalancer.digitalocean_loadbalancer.lb: Still creating... [10s elapsed]
module.nachos.module.loadbalancer.digitalocean_loadbalancer.lb: Still creating... [20s elapsed]
module.nachos.module.loadbalancer.digitalocean_loadbalancer.lb: Still creating... [30s elapsed]
module.nachos.module.loadbalancer.digitalocean_loadbalancer.lb: Still creating... [40s elapsed]
module.nachos.module.loadbalancer.digitalocean_loadbalancer.lb: Still creating... [50s elapsed]
module.nachos.module.loadbalancer.digitalocean_loadbalancer.lb: Still creating... [1m0s elapsed]
module.nachos.module.loadbalancer.digitalocean_loadbalancer.lb: Creation complete after 1m10s [id=d61e9717-f698-482e-a733-1234567890]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

loadbalancer_ip = "138.68.X.X"
```

6. Wait about 30 seconds for the droplet to intialize, then `curl` the `loadbalancer_ip` in **your** terraform apply output. You should receive responses like the output below:

```
$ curl http://138.68.X.X
<html><body><h1>web1-nachos-stg IS ALIVE!!!</h1></body></html>
$ curl http://138.68.X.X
<html><body><h1>web0-nachos-stg IS ALIVE!!!</h1></body></html>
$ curl http://138.68.X.X
<html><body><h1>web1-nachos-stg IS ALIVE!!!</h1></body></html>
$ curl http://138.68.X.X
<html><body><h1>web0-nachos-stg IS ALIVE!!!</h1></body></html>
```
_Note: Notice how the output changes depending on which host responds to the request, which confirms that the load balancer is working as we intended it to. You can also browse to that load balancer address in a chrome/firefox/etc._

7. When you're ready, remove the droplets and load balancer. Run `terraform destroy` and confirm with `yes` when prompted.


### Versioning Composed Service modules

With testing out of the way, we're ready to promote and version the `nachos` module.

1. Commit the changes you've made to your `nachos-module` branch
2. Create a pull request, self hi-five that bad boy, and merge it into `main`
3. Checkout the `main` branch and pull the changes: `git checkout main && git pull`
4. Create a git tag for this module: `git tag -a taccocorp-nachos-v1.0.0 -m "first release of nachos service module"`
5. Push the tag: `git push --follow-tags`
6. Go to your `taccoform-modules` repo on github.com and on the right side, you'll see the `Releases` heading, click the link and you'll see your new `taccocorp-nachos-v1.0.0` tag


### In Review

In this post, we learned what the hell a composed service is, how to create one and how to version it. Where do we go from here? How do I deploy this thing? How do I hand this off to someone else on my team? In the next post, we'll go over how to document your modules so that it's easy for others to pick up and for you to remember how to use it when you forget 6 months from now. 

Code for this post can be found in the [taccoform-modules](https://github.com/jperez3/taccoform-modules) repo.

---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
