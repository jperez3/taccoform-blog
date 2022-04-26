+++
title =  "Securing Terraform Credentials With 1Password"
tags = ["terraform", "tutorial", "1password"]
date = "2022-04-26"
+++


![](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfg_p5/header.jpg)


# Overview

One of the first things you learn with Terraform is that you need a way to authenticate and how to pass those credentials to Terraform. You can use environment variables, the `-var` flag, or use a `.tfvars` file to pass sensitive information from you to the provider. These methods create a security gap because anyone with access to your terminal has the keys to the city. Against our best judgement, we sometimes store these credentials our dot file, exchanging security for convenience. There are several tools out there to help align security and convenience for setting credentials. If you're a 1Password customer, the new 1Password CLI 2.0 is a great fit for many scenarios. Today we'll use 1Password CLI to show how you can pass credentials from one of your vaults to the Terraform provider.


## Lesson

* Installing 1Password And 1Password CLI 2.0
* Adding A New 1Password Vault
* Creating A 1Password Secret
* 1Password CLI And Terraform
* Using 1Password CLI and Docker



### Installing 1Password And 1Password CLI 2.0


#### Updating 1Password App

 In order to take advantage of all the new 1Password CLI 2.0 features, you will need to upgrade your current 1Password to version 8. At the time of this writing, 1Password 8 is still in beta on mac, so please keep that in mind if you do experience any weirdness. You can download the mac install [here](https://downloads.1password.com/mac/1Password%20Beta.zip) and the windows install [here](https://downloads.1password.com/win/1PasswordSetup-latest.exe). (Psssst linux is over [here](https://1password.com/downloads/linux/))


 #### Installing 1Password CLI

 After you've updated the 1Password app, you are ready to isntall the 1Password CLI 2.0. The install instructions vary based on which platform you are on, but the 1Password team created this handy [page](https://developer.1password.com/docs/cli/get-started#install) to help.


#### Configuring 1Password CLI

1. Verify that 1Password CLI version 2.x has been installed: `op -v`. Your output should read 2.0.0 or higher.
2. Open your 1password app and find your 1password account URL. It should be in the form of `subdomain.1password.com` with subdomain being your unique account.
3. In terminal, log into your 1password account: `eval $(op signin --account YOURNAMEGOESHERE.1password.com)`
4. Once logged in, confirm with `op vault ls`. Your available vaults should be listed, confirming that you are authenticated.


### Adding A New 1Password Vault

To keep things organized and separate for this demo, we'll add a new 1Password vault. This will make it easier to clean up later.

1. Create a new `taccoform-dmeo` vault by running: `op vault create taccoform-demo`

```bash
$ op vault create taccoform-demo
ID:                   REDACTED
Name:                 taccoform-demo
Type:                 USER_CREATED
Attribute version:    1
Content version:      1
Items:                0
Created:              now
Updated:              now
```


2. Verify that the new vault has been created via `ops vault ls`




### Creating A 1Password Secret

Now we're ready to create a secret in our new vault. If you create a secret without a password value specified, 1Password will create a random password for you based on your password complexity defaults.

1. Create a new secret: `op item create --category=password --title='demo-secret' --vault taccoform-demo' 'password=passwordistaco'`

```bash
$ op item create --category=password --title='demo-secret' --vault taccoform-demo 'password=passwordistaco'
ID:          REDACTED
Title:       demo-secret
Vault:       REDACTED
Created:     now
Updated:     now
Favorite:    false
Version:     0
Category:    PASSWORD
Fields:
  password:    passwordistaco
```
2. Create environment variable to reference that secret: `export TACCOFORM_DEMO_SECRET=op://taccoform-demo/demo-secret/password`
3. Use 1Password CLI to retrieve the secret from the `taccoform-demo` vault: `op run -- env | grep TACCOFORM`
```bash
$ op run -- env | grep TACCOFORM
TACCOFORM_DEMO_SECRET=<concealed by 1Password>
```
_Note: Notice how 1Password hides the password value when the `env` command is ran. Normally sensitive values would be exposed here in plaintext which is a huge security problem._


Now **any** CLI tool which uses environment variables to inject secrets can query 1password vaults with the help of the `op run --` command.


### 1Password CLI And Terraform

Normally I would start with an AWS example to demonstrate this functionality, but there's already a great tool to help with credential management called [aws-vault](https://github.com/99designs/aws-vault). This method is more for APIs which don't have their own dedicated credential management tool. Since we want to keep it related to building infrastructure, we'll use DigitalOcean as the cloud provider.

_Note: If you don't have a DigitalOcean account, you can use [this referral link](https://m.do.co/c/d26a4fc22a12) to open an account and get free credit to follow along without having to pay._

1. Log into DigitalOcean and browse to `API>Applications & API>Tokens/Keys>Personal Access Tokens`
2. Create a new access token called `taccoform-demo`
3. In terminal, store that new access key in the `taccoform-demo` vault as `do-token`: `op item create --category=password --title='do-token' --vault taccoform-demo 'password=DIGITALOCEANACCESSTOKENGOESHERE`
_Note: be sure to update the password value with the access key which was generated in the DigitalOcean web interface._
4. Create a Terraform readable environment variable for the DigitalOcean access token:  `export TF_VAR_do_token=op://taccoform-demo/do-token/password`
5. Now create a new file called `taccoform.tf` with the following to create a droplet in DigitalOcean:

```hcl
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~>2.19.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

variable "do_token" {}

resource "digitalocean_droplet" "taccoform" {
  image     = "ubuntu-20-04-x64"
  name      = "taccoform-demo"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
}
```
5. After saving, run `op run -- terraform init`

```bash
$ op run -- terraform init

Initializing the backend...

Initializing provider plugins...
- Finding digitalocean/digitalocean versions matching "~> 2.19.0"...
- Installing digitalocean/digitalocean v2.19.0...
- Installed digitalocean/digitalocean v2.19.0 (signed by a HashiCorp partner, key ID F82037E524B9C0E8)

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

6. Now run `op run -- terraform apply` to create the droplet:

```bash
$ op run -- terraform apply

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # digitalocean_droplet.taccoform will be created
  + resource "digitalocean_droplet" "taccoform" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + graceful_shutdown    = false
      + id                   = (known after apply)
      + image                = "ubuntu-20-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "taccoform-demo"
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

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

digitalocean_droplet.taccoform: Creating...
digitalocean_droplet.taccoform: Still creating... [10s elapsed]
digitalocean_droplet.taccoform: Still creating... [20s elapsed]
digitalocean_droplet.taccoform: Still creating... [30s elapsed]
digitalocean_droplet.taccoform: Still creating... [40s elapsed]
digitalocean_droplet.taccoform: Still creating... [50s elapsed]
digitalocean_droplet.taccoform: Creation complete after 55s [id=1234456789]
```
7. If you have [doctl](https://docs.digitalocean.com/reference/doctl/) installed, you can attach the `do-token` in your vault to the environment variable `DIGITALOCEAN_ACCESS_TOKEN` to authenticate to DigitalOcean: `export DIGITALOCEAN_ACCESS_TOKEN=op://taccoform-demo/do-token/password`
_Note: `DIGITALOCEAN_ACCESS_TOKEN` is an environment variable that `doctl` checks for credentials._
8. Now you can use the same token to do things like check in on the droplet you just created:

```bash
$ op run -- doctl compute droplet get 1234567890
ID           Name              Public IPv4       Private IPv4    Public IPv6    Memory    VCPUs    Disk    Region    Image                     VPC UUID                                Status    Tags    Features                            Volumes
1234567890    taccoform-demo    1.2.3.4    10.0.0.4                     1024      1        25      sfo2      Ubuntu 20.04 (LTS) x64    REDACTED    active            droplet_agent,private_networking
```
_Note: Replace `12345667890` with the unique ID following `id=` at the end of your terraform apply output._



### Using 1Password CLI and Docker

You can also use 1password CLI to pass environment variables to a containerized application or CLI tool like `doctl`. You will have to use a trick to push the environment variables to the docker container by using the `--no-masking`:

```bash
$ docker run --rm --interactive --tty --env-file <(op run --no-masking -- env | grep DIGITALOCEAN) digitalocean/doctl compute droplet get 1234567890
ID           Name              Public IPv4       Private IPv4    Public IPv6    Memory    VCPUs    Disk    Region    Image                     VPC UUID                                Status    Tags    Features                            Volumes
1234567890    taccoform-demo    1.2.3.4    10.0.0.4                     1024      1        25      sfo2      Ubuntu 20.04 (LTS) x64    REDACTED    active            droplet_agent,private_networking
```

That's pretty cool and all, but not convenient to type. You can add an `alias` to shorten it to two letters: `alias do='docker run --rm --interactive --tty --env-file <(op run --no-masking -- env | grep DIGITALOCEAN) digitalocean/doctl'`

Now you can just run `do compute droplet get 1234567890`

```bash
$ do compute droplet get 296897878
ID           Name              Public IPv4       Private IPv4    Public IPv6    Memory    VCPUs    Disk    Region    Image                     VPC UUID                                Status    Tags    Features                            Volumes
1234567890    taccoform-demo    1.2.3.4    10.0.0.4                     1024      1        25      sfo2      Ubuntu 20.04 (LTS) x64    REDACTED    active            droplet_agent,private_networking
```

You can also make this stuff persist through terminal sessions, by adding them to your bash/z profile:

```bash
export TF_VAR_do_token=op://taccoform-demo/do-token/password
export DIGITALOCEAN_ACCESS_TOKEN=op://taccoform-demo/do-token/password
alias do='docker run --rm --interactive --tty --env-file <(op run --no-masking -- env | grep DIGITALOCEAN) digitalocean/doctl'
```


**After you're done messing around, delete your droplet by running: `op run -- terraform destroy` AND don't forget to delete the `taccform-demo` 1Password Vault**


### In Review


After upgrading 1password to version 8 and installing 1Password CLI 2.0, we were able to explore how credentials can be passed to a Terraform provider to provision cloud resources. We also explored how we can grab credentials from a 1password vault and set them as tool specific environment variables for authentication. 1Password has done a great job of documenting all the ways you can use 1passowrd CLI. You can find their documentation link below

https://developer.1password.com/docs/cli/get-started/


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
