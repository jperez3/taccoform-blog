+++
title =  "Packer Detour #1: Packer+Amazon Linux 2+AWS Session Manager "
tags = ["packer", "tutorial", "aws", "session-mana"]
date = "2021-11-07"
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tts_p1/header.jpg)


# Overview

The year is 2021 and you're still building servers, you read that right. It's not always a bad thing though. There are certain scenarios you might consider using an instance over a container or function. Maybe AWS doesn't provide a hosted solution for the technology you want to use, maybe you want to do multi-cloud and the cloud provider's offerings are too different to manage. No matter the reason, you should familiarize yourself with Hashicorp Packer. 

## Lesson

* What is Packer?
* Why Should I Care About Packer?
* Security Hurdles 
* Packer Files And Components
* Packer Commands 
* Packer Builds  


### What is Packer? 

Packer is brought to you by Hashicorp, the very same people who brought you Terraform. The link between these two products might be a little loose, but can become a superpower when combined. Packer also uses Hashicorp's HCL2 (Hashicorp Configuration Language V2) which should feel similar to writing Terraform code. Packer allows you to build configurations on top of existing images. In our case, we're talking about adding additional configuration to Amazon Linux 2 AMIs. Packer builds AMIs by provisioning an instance on your behalf, uses ssh to log into the instance and configure it based on your specifications. When the configuration completes, packer shuts down the instance and turns it into an AMI and then does a bit of clean up. 

### Why Should I Care About Packer? 

Investing in Packer will bring you closer to immutable infrastructure which is a fancy way of saying you'll have the ability to trash an instance and not freak out about it. Rebuilding a broken/missing/deleted instance is fast and easy because you baked most of your configuration into a custom AMI. I say most of your configuration because you should not store sensitive information like secrets in your custom AMI. 


### Security Hurdles

The default behavior for Packer is to provision a keypair (for ssh access), instance, and security group on your behalf during the Packer build process. This all looks great on the surface, but take a closer look at the security group and you'll notice that it opens up the instance to the public Internet which doesn't feel very secure. The Packer build process can take anywhere from 5-30 minutes depending on the amount of custom configuration you put into your build. A more secure way to do this is by using a [bastion](https://www.learningjournal.guru/article/public-cloud-infrastructure/what-is-bastion-host-server/) instance to tunnel through to get to the private instance for configuration. The cost of using this method is additional configuration and a bastion instance to maintain. An even more secure way to accomplish this is by leveraging AWS's Session Manager to connect into the instance for configuration. Session Manager is its own glorious thing and deserves more praise for all that it gives you. People with other cloud provider experience might shrug it off, but you should definitely check it out if you're working in AWS. 



### Packer Files And Components

Packer uses HCL2 just like terraform and if you've written Terraform code, you know the files end in `.tf`, so naturally packer files end in `.pkr`. LOL not the case, but somewhat close... Packer files end with `.pkr.hcl`. I recommend taking some time to think about how you want to organize your Packer files, rather than throwing everything into something like `main.pkr.hcl`. The two major components of Packer are `builds` and `sources`, so that might be a good line in the sand for file organization.

* Source: a code block which tells Packer where to start which is most likely a cloud provider and how to connect to the instance/droplet/vm for additional configuration 

* Build: a code block which tells packer to invoke a defined source block and run additional configuration on that intance/droplet/vm

`source.pkr.hcl`
```hcl

```



### In Review



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
