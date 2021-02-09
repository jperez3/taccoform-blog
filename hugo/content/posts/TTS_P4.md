+++
title =  "Taccoform Tutorial Series - Part IV"
tags = ["terraform", "tutorial", "digitalocean", "terraform13"]
date = "2020-02-08"
+++


![Photo by T. Kaiser](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tts_p1/header.jpg)


# Overview

At some point you'll want to allow others to build off of the terraform work you've started or maybe you want to add your terraform to a CI/CD pipeline. In order to accomplish this, you'll need to move your Terraform statefile to a central location and update your terraform configuration settings. There's a couple of ways to make this work and we'll go over the pros and cons of each approach.

## Lesson 4

In this post we'll go over:
* What's a statefile? 
* How to configure statefile in terraform
* Where to host your statefile


### What's a statefile? 

In Terraform, a statefile is a file which is used to store information about what has been provisioned in your current workspace (and/or directory.) Terraform uses this stored information in conjunction with the Terraform resource definitions that you've defined in your `.tf` files. When you run Terraform, it checks to make sure your `.tf` matches what is in your statefile. When there's a difference between the two files, terraform will try to reconcile those differences. Examples of this include:
    - Terraform sees a resource definition for a droplet in a `.tf` file, but not in the `statefile`. Terraform attempts to create the droplet
    - Terraform sees a droplet in the `statefile`, but cannot find a resource definition for the droplet in the `.tf` file. Terraform attemps to destroy the droplet
    - Terraform sees a resource definition for a droplet in a `.tf` file and a matching droplet in the `statefile`. Terraform will do nothing

When you start a new terraform workspace and don't specify a `backend` configuration, terraform will create a `statefile` in the working directory. This will help you get up and running, but it is not ideal. Exposed secrets can live in the `statefile`, so you shouldn't check it into git and other people who check out your code won't have the `statefile` to help terraform reconsile the differences.

### Statefile Hosting Options

To allow others and/or automation to use the same `statefile`, it needs to be hosted somewhere that multiple individuals can access it. 

### Self-hosting

* You can host your Terraform statefile in DigitalOcean's Spaces which is modeled after AWS's S3 storage. If you choose to use this form of hosting, you will be responsible for:
  * making sure the `statefile` is backed up and/or versioned. Losing a statefile is not fun and would cause a lot of headaches to get things back to where they were
  * making sure the `statefile` is secure. This means locking down access to the `statefile` and encrypting it.
  * managing the locking mechanism for the `statefile` so that two or more people cannot run terraform on the same workspace at the same time. Multiple runs at the same time could corrupt the `statefile`
* You might want to self host because you want control of your own data or you might have security and/or compliance requirements

### Terraform Cloud

In 2019, HashiCorp (the company which built Terraform) announced that they were creating a platform called Terraform Cloud to help alleviate some of the difficulty around managing `statefiles`. At the time of this writing, Terraform Cloud is free for up to 5 users. They've also mentioned that their allowed number of hosted `statefiles` is generous, but I haven't seen an exact limit.



### In Review



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_