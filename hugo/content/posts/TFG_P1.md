+++
title =  "Terraform Import"
tags = ["terraform", "tutorial", "digitalocean", "import"]
date = "2021-06-17"
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfg_p1/header.jpg)


# Overview

Terraform is a great tool for managing infrastructure, but let's be honest, sometimes it can put you into precarious situations. After working with Terraform for a while, you will start to develop some kind of muscle memory for what works and what doesn't. One thing you'll start to notice is that your Terraform workspace is taking longer and longer to run. You need to address this problem, but you also can't delete production resources and recreate them in a different terraform workspace. Today we'll go over Terraform Import and when to use it.


## Lesson

* What's a Terraform Import?
* When Should I Use Terraform Import?
* How do I use a terraform import?
 
### What's a Terraform Import?

Terraform import is a subcommand that allows you to bring existing resources into your current terraform workspace's statefile. These resources could have been created by clicking through a GUI or via Terraform in another workspace. By defining a resource definition and importing the cloud resource (eg droplet), you will be able to manage/track that resource in the future via terraform. 

### When Should I Use Terraform Import? 

There are various reasons why you might want to use the terraform resources:
* To start tracking resources that are not in terraform
* Consolidate related resources into a single terraform workspace
* Separate unrelated resources into multiple workspaces to limit the blast radius when problems occur
* Changing/upgrading a terraform module which might trigger a destroy of critical infrastructure 


### How Do I Use Terraform Import?

Let's start by building a couple of terraform workspaces

1. Create the following folder and file structure:

```
tutorial-import
├── web1
│   ├── droplet.tf
│   ├── provider.tf
│   └── variables.tf
└── web2
    ├── droplet.tf
    ├── provider.tf
    └── variables.tf
```

2. Fill in the `web1` folder with the following:

`droplet.tf`
```hcl
resource "digitalocean_droplet" "web1" {
  image  = "ubuntu-18-04-x64"
  name   = "web1-import"
  region = "sfo2"
  size   = "s-1vcpu-1gb"
}
```


`provider.tf`
```hcl
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0.0"
    }
  }
  required_version = "~> 1.0.0"
}


provider "digitalocean" {
  token = var.do_token
}
```


`variables.tf`
```hcl
variable "do_token" {
  description = "DigitalOcean authentication token for terraform provider"
}
```

3. Fill in the `web2` folder with the following:

`droplet.tf`
```hcl
resource "digitalocean_droplet" "web_import" {
  image  = "ubuntu-18-04-x64"
  name   = "web1-import"
  region = "sfo2"
  size   = "s-1vcpu-1gb"
}
```


`provider.tf`
```hcl
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0.0"
    }
  }
  required_version = "~> 1.0.0"
}


provider "digitalocean" {
  token = var.do_token
}
```


`variables.tf`
```hcl
variable "do_token" {
  description = "DigitalOcean authentication token for terraform provider"
}
```

4. In terminal, navigate into the `tutorial-import>web1` folder
   1. Make sure you've set your DigitalOcean token as an environment variable: `export TF_VAR_do_token='YOURDIGITALOCEANTOKENGOESHERE'`
   2. Use `tfswitch` to switch over to terraform 1.0.0: `tfswitch 1.0.0` (You can also download it from [here](https://www.terraform.io/downloads.html))
5. Run `terraform init` to intialize your workspace, it should look something like this:

```
$ terraform init

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

6. Run `terraform apply` to create the `web1` droplet resource that we'll use to demonstrate the `terraform import` command

```
terraform apply --auto-approve

Terraform used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # digitalocean_droplet.web1 will be created
  + resource "digitalocean_droplet" "web1" {
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
      + monitoring           = false
      + name                 = "web1-import"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + status               = (known after apply)
      + urn                  = (known after apply)
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
digitalocean_droplet.web1: Creating...
digitalocean_droplet.web1: Still creating... [10s elapsed]
digitalocean_droplet.web1: Still creating... [20s elapsed]
digitalocean_droplet.web1: Still creating... [30s elapsed]
digitalocean_droplet.web1: Creation complete after 34s [id=1234567890]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```
_Note: Write down the Droplet ID number from the last line in the output, you will need this later._

7. Now that we have the `web1` droplet created, we can remove it from this workspace's statefile with the `terraform state rm` command

```
$ terraform state rm digitalocean_droplet.web1
Removed digitalocean_droplet.web1
Successfully removed 1 resource instance(s).
```
_Note: This isn't a terraform workspace with a bunch of other resources, but you have probably experienced a bloated workspace which has many resources and takes forever to run terraform commands. You can use the combination of the state removal and import commands to group related resources in their own terraform workspace._

8. Remove or comment out the droplet resource definition in `tutorial-import>web1>droplet.tf` and then run `terraform plan`. You should see that there are no changes made and the `web1` droplet is still alive in the DigitalOcean control panel:

```
$ terraform plan

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no
differences, so no changes are needed
```

9. In terminal, navigate to `tutorial-import>web2` folder, then run `terraform init` followed by `terraform plan`:

```
$ terraform init && terraform plan

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

Terraform used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # digitalocean_droplet.web_import will be created
  + resource "digitalocean_droplet" "web_import" {
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
      + monitoring           = false
      + name                 = "web1-import"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + status               = (known after apply)
      + urn                  = (known after apply)
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to
take exactly these actions if you run "terraform apply" now.

```
_Note: you can see that terraform wants to create the `web1-import` droplet again, but that's not what we want. We want to import the existing droplet into this workspace._

10. Check out the official Terraform/DigitalOcean droplet documenation [here](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet#import). It looks like the format required for importing a droplet is:

```
terraform import digitalocean_droplet.mydroplet 100823
  |        |             |              |         |
terraform  |             |              |          \
binary     |              \             |           Droplet ID
       import subcommand   resource      \
                           definition    resource name
                           type
```

11. You will need to grab the Droplet ID you wrote down earlier and droplet resource name in `tutorial>web2>droplet.tf`. Your import command should look something like `terraform import digitalocean_droplet.web_import 123456790`, run the command and you should see an output like the import below:

```
terraform import digitalocean_droplet.web_import 1234567890
digitalocean_droplet.web_import: Importing from ID "1234567890"...
digitalocean_droplet.web_import: Import prepared!
  Prepared digitalocean_droplet for import
digitalocean_droplet.web_import: Refreshing state... [id=1234567890]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```
12. Now run `terraform plan` and you shouldn't see any changes. In some scenarios you will be prompted for changes because a parameter set on the old workspace's resource definition that isn't present on the new workspace's resource definition. You will likely have to fill in those paramaters and play whack-a-mole until your `terraform plan` comes back clean.

13. Clean up your workspace so that you aren't billed for the droplet by running `terraform destroy` 

_If you ran into any issues with the terraform files, they can be found [here](https://github.com/jperez3/taccoform-tutorial/tree/main/tutorial-import)_

### In Review

Ok, now you know what Terraform import is all about and how to use it. I don't think it's a tool that you'll use a lot, but it's a great tool to have in your back pocket when you can't freely destroy and recreate resources. You might also be in a place where you've inherited cloud infrastructure and want to manage those resources in Terraform. I should also mention that Terraform import isn't a silver bullet and the documentation is very limited, so your mileage may vary. Thank you for making it to the end and don't forget to smash that like button.



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
