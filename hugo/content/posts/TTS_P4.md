+++
title =  "Taccoform Tutorial Series - Part IV"
tags = ["terraform", "tutorial", "digitalocean"]
date = "2021-02-12"
+++


![Photo by T. Kaiser](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tts_p4/header.jpg)


# Overview

At some point you'll want to allow others to build off of the terraform work you've started or maybe you want to add your terraform to a CI/CD pipeline. In order to accomplish this, you'll need to move your Terraform statefile to a central location and update your terraform configuration settings. There's a couple of ways to make this work and we'll go over the pros and cons of each approach.

## Lesson 4

In this post we'll go over:
* What's a statefile? 
* Where to host your statefile
* How to configure `statefile` in Terraform


### What's a statefile? 

In Terraform, a statefile is a file which is used to store information about what has been provisioned in your current workspace (and/or directory.) Terraform uses this stored information in conjunction with the Terraform resource definitions that you've defined in your `.tf` files. When you run Terraform, it checks to make sure your `.tf` matches what is in your statefile. When there's a difference between the two files, terraform will try to reconcile those differences. Examples of this include:
    - Terraform sees a resource definition for a droplet in a `.tf` file, but not in the `statefile`. Terraform attempts to create the droplet
    - Terraform sees a droplet in the `statefile`, but cannot find a resource definition for the droplet in the `.tf` file. Terraform attemps to destroy the droplet
    - Terraform sees a resource definition for a droplet in a `.tf` file and a matching droplet in the `statefile`. Terraform will do nothing

When you start a new terraform workspace and don't specify a `backend` configuration, terraform will create a `terraform.statefile` file in the working directory. This will help you get up and running, but it is not ideal. Exposed secrets can live in the `statefile`, so you shouldn't check it into git and other people who check out your code won't have the `statefile` to help terraform reconsile the differences.

### Where to host your statefile

To allow others and/or automation to use the same `statefile`, it needs to be hosted somewhere that multiple individuals can access it. 

### Self-hosting

* You can host your Terraform statefile in DigitalOcean's Spaces which is modeled after AWS's S3 storage. If you choose to use this form of hosting, you will be responsible for:
  * making sure the `statefile` is backed up and/or versioned. Losing a statefile is not fun and would cause a lot of headaches to get things back to where they were
  * making sure the `statefile` is secure. This means locking down access to the `statefile` and encrypting it.
  * managing the locking mechanism for the `statefile` so that two or more people cannot run terraform on the same workspace at the same time. Multiple runs at the same time could corrupt the `statefile`
* You might want to self host because you want control of your own data or you might have security and/or compliance requirements

#### Self-Hosting Pros/Cons TLDR
* Pros:
  * You control your statefile
* Cons:
  * You are responsible for organizing, securing and locking

### Terraform Cloud

In 2019, HashiCorp (the company which built Terraform) announced that they were creating a platform called Terraform Cloud to help alleviate some of the difficulty around managing `statefiles`. At the time of this writing, Terraform Cloud is free for up to 5 users. They've also mentioned that their allowed number of hosted `statefiles` is generous, but I haven't seen an exact limit.

#### Terraform Cloud Pros/Cons TDLR
* Pros
  * HashiCorp does a lot of the heavy lifting for you
* Cons
  * You don't "own" your `statefile`


### How to configure `statefile` in Terraform

We're gonna focus on using Terraform Cloud because there's building/maintenance involved. If you're interested in using DigitalOcean's Spaces or S3, check out [this](https://www.terraform.io/docs/language/settings/backends/s3.html) documentation.


#### Create a Terraform Cloud account

1. Go to [Terraform Cloud](https://app.terraform.io/signup/account) and create a new account
2. Once logged in, it will ask you to confirm your email address. Go ahead, I'll wait
3. When you click the validation link in your Terraform Cloud validation email, it will take you a screen to `Create a new organization`. Give it a name, then press `Create organization`
4. You'll now see a `Create a new Workspace` page and given three options. It recommends `version control workfolw`, but right now we're just interested in `statefile` hosting. Choose `CLI-driven workflow` 
5. At the `Create a new Workspace` screen, enter `tf-tutorial`, then press `Create workspace`
6. Go to the `Settings` menu on the top right corner, select `General`
7. Change the `Execution Mode` to `local` then press `Save settings`, this means terraform cloud will only be used for `statefile` storage. If you leave it on `Remote`, Terraform Cloud will need credentials for your cloud provider to build/destroy on your behalf.
8. Go back to the `Runs` tab, here you will find example code to paste into your `provider.tf` file like the text below:

```hcl
terraform {
  backend "remote" {
    organization = "CashiHorp"

    workspaces {
      name = "tf-tutorial"
    }
  }
}
```
_Note: Don't copy the text above, copy the **Example Code** shown in the Terraform Cloud interface._

##### Workspace Naming Conventions

You will more than likely have multiple/many workspaces. Be sure to include environment/stage information by doing things like appending `-prod` to the end of the workspace. Think about what makes sense to you and your team. Try out different naming schemes prior to deciding because it might come back to bite you later.

#### Create an API key to access Terraform Cloud

1. Go to [User Settings/Tokens](https://app.terraform.io/app/settings/tokens)
2. Press `Create an API Token`
3. Enter a description like "My Dell Optiplex GX260", then press `Create API token`
4. Open your terminal and run `terraform login`
5. Enter `yes` when prompted to proceed
6. Paste the token you created in steps 1-3, then press enter
   * You should recieve a confirmation that says your credentails were stored in `/root/.terraform.d/credentials.tfrc.json`


#### Configuring `provider.tf`

1. Create a new folder on your computer called `tf-tutorial`
2. Create `provider.tf` file in the `tf-tutorial` folder
3. Copy the `Example code` provided to you in the Terraform Cloud "Runs" page into your `provider.tf`
4. Now add your cloud provider to the mix. We'll be using DigitalOcean which will look like this:

`provider.tf`
```hcl
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0.0"
    }
  }
  required_version = "~> 0.13"
}

variable "do_token" {
  description = "Digital Ocean auth token"
}

provider "digitalocean" {
  token = var.do_token
}
```
_Note: [Taccoform Tutorial Series - Part I](https://www.taccoform.com/posts/tts_p1/) has information on how to set up a DigitalOcean account and API token_

5. Now you should be ready to run Terraform commands, start with `terraform init`

```
$ terraform init

Initializing the backend...

Successfully configured the backend "remote"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Finding digitalocean/digitalocean versions matching "~> 2.0.0"...
- Installing digitalocean/digitalocean v2.0.2...
- Installed digitalocean/digitalocean v2.0.2 (signed by a HashiCorp partner, key ID F82037E524B9C0E8)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/plugins/signing.html

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```


#### Testing Your Terraform Cloud Configuration

1. Create a `droplet.tf` file in the `tf-tutorial` folder with the following in it:

`doplet.tf`
```hcl
resource "digitalocean_droplet" "web" {
  image  = "ubuntu-20-04-x64"
  name   = "web-test"
  region = "sfo2"
  size   = "s-1vcpu-1gb"
}
```

2. Run `terraform apply`
3. Enter your DigitalOcean token when prompted
4. Type `yes` when prompted and press enter
5. After the apply has completed, go back to the `tf-tutorial` workspace in Terraform Cloud and go to the `States` tab
6. You will see a new state has been created. Click on the state and you'll be able to see the contents of the `statefile`
7. Once you're ready, you can run `terraform destroy` to remove the droplet you created.
8. You can also remove the `tf-tutorial` workspace in Terraform Cloud


### In Review

You now have Terraform Cloud doing the heavy lifting for storing, encrypting, and versioning your Terraform `statefiles`. Even better, you can add more people to your Terraform Cloud organization to collaborate on terraform work. You can also start incorporating CI/CD workflows into your terraform projects.


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_