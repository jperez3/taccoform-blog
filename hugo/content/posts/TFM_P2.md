+++
title =  "Creating a Terraform Module"
tags = ["terraform", "tutorial", "digitalocean", "terraform14", "module", "modules"]
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

1. Start by creating a new private repo named `taccoform-modules`. Since this is a private repository, any person (or machine) that wants to use your terraform modules will need read access to the repo.
2. Create a new branch in that repo, eg `new-droplet-module`
3. Create a two folders in the root of your new repository `vendors` and `tacco-corp` 
   1. `vendors` is where you'll put terraform modules from cloud providers with terraform providers
   2. `tacco-corp` is where you'll put terraform modules that are comprised of one or more vendor modules to create a composed service for our Tacco-Corp company. Think of composed services as a meal coming together like a plate of fajitas, rice, beans, and a salt-rimmed margarita. In cloud provider terms this could be a composed service with a load-balancer, virtual machine, and database.
4. In the vendors folder, create `digitalocean` and in that folder create a `droplet` folder.

_Your folder structure should look something like this_

```
taccoform-modules
├── tacco-corp
└── vendors
    └── digitalocean
        └── droplet
```

Starting with a well-organized terraform module repo will help keep things clean and predictable as your team and company grows. In a later post, we'll go over further organization of your `tacco-corp` folder, today we will be focusing on creating a simple vendor module.


### Creating a DigitalOcean droplet module

1. Inside the `droplet` folder, create `droplet.tf`, `droplet_variables.tf`, `provider.tf`, and `variables.tf`
   * `droplet.tf` will house resource definitions for the droplet itself and any directly related resources
   * `droplet_variables.tf` will house the variable definitions related to resources in the `droplet.tf` file
   * `provider.tf` will house terraform provider information and any terraform state management
   * `variables.tf` will house any variables which can be used by multiple `.tf` files
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

* For more information on terraform variables and how to use them, check out [Taccoform Tutorial Series - Part III](https://www.taccoform.com/posts/tts_p3/) 

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
_Note: Terrform providers may have different options/parameters, check out the official [Terraform Provider Registry](https://registry.terraform.io/browse/providers) for more information on the provider that you want to use._

10. Commit the changes to your git branch.


### Testing the DigitalOcean droplet module

Now that you've created a new droplet terraform module, it's time to test it out! You'll want to create a new workspace/folder. 

1. Let's create a temporary workspace in the `taccoform-modules` folder called `module-testing`. Inside the `module-testing` folder we'll add another folder called `droplet-test` 

* Your `taccoform-modules` repo should look something like this:
```
taccoform-modules
├── README.md
├── module-testing
│   └── droplet-test
├── tacco-corp
└── vendors
    └── digitalocean
        └── droplet
            ├── droplet.tf
            ├── droplet_variables.tf
            ├── provider.tf
            └── variables.tf
```            

2. In the `droplet-test` folder, create three new files: `provider.tf`, `droplet.tf`, and `variables.tf`

3. In the `provider.tf` file, paste the following to have a bare-bone provider configuration:

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


provider "digitalocean" {
  token = var.do_token
}
```

4. In the `variables.tf` file, paste the following to create the necessary variable for your DigitalOcean authorization:

```hcl
variable "do_token" {
  description = "DigitalOcean authentication token for terraform provider"
}
```

5. In the `droplet.tf` file, paste the following:

```hcl
module "burrito_droplet" {
  source = "../../vendors/digitalocean/droplet"

  env     = "stg"
  service = "burrito"
}
```
    1. Line 1 tells terraform that you want to call a module and give it any name that you want for this specific deployment of the module
    2. Line 2 tells terraform where to get the module from. In this case, up a couple directories in this repo and then going down into the droplet module folder. You can also use a github repo as a source and we'll go over that in a little bit.
    3. Line 3 is empty (duh)
    4. Line 4 is telling the module to override the default value for the variable `env`
    5. Line 5 is telling the module to set the value for the `service` variable to `burrito`. If we did not set a value for `service`, terraform would prompt you for a value when you ran a `terraform` cli command. This isn't ideal because you will probably get tired of entering that variable for every `terraform` command

6. If you haven't already, set the `TF_VAR_do_token` environment variable with your DigitalOcean token:

```
export TF_VAR_do_token=YOURDIGITALOCEANTOKENGOESHERE
```

7. Check your terraform version with `terraform version` and make sure you're on terraform 0.14.0 or higher. If you aren't on terraform 14, you can use [tfswitch](https://tfswitch.warrensbox.com/Install/) to switch between terraform versions, (eg. `tfswitch 0.14.7`)
8. Run `terraform init` to initialize the workspace and pull the terraform module. Your output should look something like this:

```
terraform init
Initializing modules...
- burrito_droplet in ../../vendors/digitalocean/droplet

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

9. Now run `terraform plan` to see what the module wants to create:

```
terraform plan

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.burrito_droplet.digitalocean_droplet.vm[0] will be created
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
      + name                 = "web0-burrito-stg"
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

  # module.burrito_droplet.digitalocean_droplet.vm[1] will be created
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
      + name                 = "web1-burrito-stg"
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

Plan: 2 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```

10. If the plan looks good to you, go ahead and run `terraform apply`, then enter _yes_ when prompted:

```
terraform apply

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.burrito_droplet.digitalocean_droplet.vm[0] will be created
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
      + name                 = "web0-burrito-stg"
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

  # module.burrito_droplet.digitalocean_droplet.vm[1] will be created
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
      + name                 = "web1-burrito-stg"
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

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.burrito_droplet.digitalocean_droplet.vm[0]: Creating...
module.burrito_droplet.digitalocean_droplet.vm[1]: Creating...
module.burrito_droplet.digitalocean_droplet.vm[0]: Still creating... [10s elapsed]
module.burrito_droplet.digitalocean_droplet.vm[1]: Still creating... [10s elapsed]
module.burrito_droplet.digitalocean_droplet.vm[1]: Still creating... [20s elapsed]
module.burrito_droplet.digitalocean_droplet.vm[0]: Still creating... [20s elapsed]
module.burrito_droplet.digitalocean_droplet.vm[0]: Still creating... [30s elapsed]
module.burrito_droplet.digitalocean_droplet.vm[1]: Still creating... [30s elapsed]
module.burrito_droplet.digitalocean_droplet.vm[0]: Creation complete after 34s [id=240470473]
module.burrito_droplet.digitalocean_droplet.vm[1]: Creation complete after 34s [id=240470472]

```

    * Check out the DigitalOcean control panel to verify that terraform has created what you expected from the `droplet` module

11. After you've reviewed the terraform output and digitalocean control panel, run `terraform destroy` then enter _yes_ when prompted:

```
terraform destroy

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # module.burrito_droplet.digitalocean_droplet.vm[0] will be destroyed
  - resource "digitalocean_droplet" "vm" {
      - backups              = false -> null
      - created_at           = "2021-04-08T03:16:53Z" -> null
      - disk                 = 25 -> null
      - id                   = "240470473" -> null
      - image                = "ubuntu-18-04-x64" -> null
      - ipv4_address         = "159.65.106.42" -> null
      - ipv4_address_private = "10.120.0.4" -> null
      - ipv6                 = false -> null
      - locked               = false -> null
      - memory               = 1024 -> null
      - monitoring           = true -> null
      - name                 = "web0-burrito-stg" -> null
      - price_hourly         = 0.00744 -> null
      - price_monthly        = 5 -> null
      - private_networking   = true -> null
      - region               = "sfo2" -> null
      - resize_disk          = true -> null
      - size                 = "s-1vcpu-1gb" -> null
      - status               = "active" -> null
      - urn                  = "do:droplet:240470473" -> null
      - vcpus                = 1 -> null
      - volume_ids           = [] -> null
      - vpc_uuid             = "f7eaa987-e987-4f65-ab27-a7cf99e08ee8" -> null
    }

  # module.burrito_droplet.digitalocean_droplet.vm[1] will be destroyed
  - resource "digitalocean_droplet" "vm" {
      - backups              = false -> null
      - created_at           = "2021-04-08T03:16:53Z" -> null
      - disk                 = 25 -> null
      - id                   = "240470472" -> null
      - image                = "ubuntu-18-04-x64" -> null
      - ipv4_address         = "159.65.106.99" -> null
      - ipv4_address_private = "10.120.0.5" -> null
      - ipv6                 = false -> null
      - locked               = false -> null
      - memory               = 1024 -> null
      - monitoring           = true -> null
      - name                 = "web1-burrito-stg" -> null
      - price_hourly         = 0.00744 -> null
      - price_monthly        = 5 -> null
      - private_networking   = true -> null
      - region               = "sfo2" -> null
      - resize_disk          = true -> null
      - size                 = "s-1vcpu-1gb" -> null
      - status               = "active" -> null
      - urn                  = "do:droplet:240470472" -> null
      - vcpus                = 1 -> null
      - volume_ids           = [] -> null
      - vpc_uuid             = "f7eaa987-e987-4f65-ab27-a7cf99e08ee8" -> null
    }

Plan: 0 to add, 0 to change, 2 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

module.burrito_droplet.digitalocean_droplet.vm[1]: Destroying... [id=240470472]
module.burrito_droplet.digitalocean_droplet.vm[0]: Destroying... [id=240470473]
module.burrito_droplet.digitalocean_droplet.vm[0]: Still destroying... [id=240470473, 10s elapsed]
module.burrito_droplet.digitalocean_droplet.vm[1]: Still destroying... [id=240470472, 10s elapsed]
module.burrito_droplet.digitalocean_droplet.vm[1]: Still destroying... [id=240470472, 20s elapsed]
module.burrito_droplet.digitalocean_droplet.vm[0]: Still destroying... [id=240470473, 20s elapsed]
module.burrito_droplet.digitalocean_droplet.vm[0]: Destruction complete after 23s
module.burrito_droplet.digitalocean_droplet.vm[1]: Destruction complete after 23s

Destroy complete! Resources: 2 destroyed.
```

### Versioning the DigitalOcean droplet module

Now that you've confirmed that the `droplet` module works, it's time to think about adding versioning to the module. Versioning your module is important because you will want to track changes to the module and you don't want module updates to cause a cascading change for other services which references this module.

1. Prior to the actual versioning, you want to change the module source to pull from the git repository. In `module-testing/droplet-test/droplet.tf`, you want to update the module to look like the one below:

```hcl
module "burrito_droplet" {
  source = "git::git@github.com:YOURGITHUBUSERNAMEGOESHERE/taccoform-modules.git//vendors/digitalocean/droplet?ref=new-droplet-module"

  env     = "stg"
  service = "burrito"
}
```

* There's a lot going on in the newly updated `source` line:
  * From `git:` to `.git` is the github repo that you want to pull from
  * From `//` to `?` is the path to the module you want to use
  * After `ref=` is the github reference to use. This can be a branch name like the one we created for this module, a github SHA or a github tag. I've most commonly used branch name to test my module changes and github tag to create specific points in time for a module or version.

2. Save the `droplet.tf` file and run `terraform init` to pull the module from git:

```
terraform init
Initializing modules...
Downloading git::git@github.com:jperez3/taccoform-modules.git?ref=new-droplet-module for burrito_droplet...
- burrito_droplet in .terraform/modules/burrito_droplet/vendors/digitalocean/droplet

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of digitalocean/digitalocean from the dependency lock file
- Using previously-installed digitalocean/digitalocean v2.0.2

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
* In the `terraform init` output, you can see that it's now pulling the module from github. 

3. Now you can run `terraform apply` to confirm it's creating what you want and destroying it with `terraform destroy`

* After you're satisfied with the outcome of pulling the module from your branch, it's time to move on to versioning your module. I prefer to naming that is a combination of the module name and [semantic versioning](https://semver.org/) (eg. do-droplet-v1.0.0)

4. Create a pull request for your branch, approve your own PR (:facepalm:), then merge it into the `main` branch. Don't delete your branch yet.
5. In terminal, go to your `taccoform-modules` repo, switch to the `main` branch, and run `git pull`
6. Now create the github tag that you will use as a version for your module:

```
❯ git tag -a do-droplet-v1.0.0 -m "creating my first DigitalOcean droplet module"
❯ git push --follow-tags
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 194 bytes | 194.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0)
To https://github.com/jperez3/taccoform-modules.git
 * [new tag]         do-droplet-v1.0.0 -> do-droplet-v1.0.0
```

7. Switch back to your `new-droplet-module` branch and edit your `module-testing/droplet-test/droplet.tf` file to include your new version tag:

`droplet.tf`
```
module "burrito_droplet" {
  source = "git::git@github.com:jperez3/taccoform-modules.git//vendors/digitalocean/droplet?ref=do-droplet-v1.0.0"

  env     = "stg"
  service = "burrito"
}
```

8. Save `droplet.tf` and then run `terraform init` to verify that the `droplet` module is pulling the version `do-droplet-v1.0.0`:

```
❯ terraform init
Initializing modules...
Downloading git::git@github.com:jperez3/taccoform-modules.git?ref=do-droplet-v1.0.0 for burrito_droplet...
- burrito_droplet in .terraform/modules/burrito_droplet/vendors/digitalocean/droplet

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of digitalocean/digitalocean from the dependency lock file
- Using previously-installed digitalocean/digitalocean v2.0.2

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

* SUCCESS!!! Run a `terraform plan` to verify once more that it's still created the resources that you expected
### In Review

You've created a versioned DigitalOcean droplet module that you re-use anywhere. This is a simple module example, other modules can create many resources to interact with eachother. As a stretch goal, try to add another DigitalOcean resource to the `droplet` module and "bump" the version to `do-droplet-v1.1.0`. 

If you get stuck at any point, check out the [taccoform-modules](https://github.com/jperez3/taccoform-modules) repo


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
