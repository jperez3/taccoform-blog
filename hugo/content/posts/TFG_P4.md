+++
title =  "Terraform Upgrades"
tags = ["terraform", "tutorial", "digitalocean", "terraform13"]
date = "2021-19-19"
draft = true
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tts_p1/header.jpg)


# Overview


## Lesson

* Why Should I Upgrade?
* Where Do I Start?
* Common issues with upgrading


### Why Should I Upgrade? 

Upgrading Terraform isn't always required, but upgrading helps with bugs you run into and you will be able to take advantage of the available community to help when problems come up. You also might need to upgrade your terraform because a feature is only available in a newer version of your provider. This happened between Terraform 0.11.X and 0.12.X for the AWS provider. Depending on public terraform modules might also force you to move to a newer version of terraform and/or will require you to fork the module and maintain it yourself. I'm more inclined to build modules in-house to help support the technology from an operational perspective and to have more control over upgrades. 


### Where do I Start?

First you will start with the official [Terraform Upgrade Guides](https://www.terraform.io/upgrade-guides/index.html). This will help help you know about any gotchas. To date, the jump from 0.11.x to 0.12.x has been the biggest update because of the syntax changes between HCL and HCL2.

Make sure that versioning is turned on wherever you store your Terraform statefiles. If something goes wrong, you can rollback to your previous statefile and code to start over. Your mileage may vary though, depending on resource deletions during your original testing. 

### Upgrading Terraform Modules

Terraform modules can be tricky to upgrade because of any existing deployments which rely on those modules. If you manage a lot of terraform modules or the terraform upgrade is competing with other business initiatives, I would recommend copying that module to a new folder in your terraform module repo and upgrading it to your desired version. This will allow the other modules to continue services the other deployments, especially in the case of an emergency. I would also recommend using semantic versioning to help people understand which version of the module they are referencing. Eg:

```
Terraform 0.11.x = 1.X.X
Terraform 0.13.x = 2.X.X
Terraform 0.15.x = 3.X.X 
```

The main point of versioning is to help your team with clarity about how modules are progressing. Remember that your main goal is still to get all of your code onto a newer version. Getting buy-in from management is key to making progress on this initiative. Also be sure to pick versions to support. If you choose to upgrade to each sequentially, you'll spend all of your time doing upgrades and no actual building.


### Upgrading Terraform Workspaces

Your terraform workspace organization will dictate how you will tackle the upgrade. If you are crazy and deployed all of an environment's resources in a single workspace, you will need to update everything at once. This is not a great organization approach, but it's effective and risky. It would be better to split your workspaces into smaller, loosely coupled workspaces. If you mess up one aspect of your system, it's a big deal, but it's not the end of the world. 

Use lower environments and test environments to see what happens when you upgrade to a newer version of terraform. Nothing builds confidence like upgrading through several lower environments prior to production (as long as you're using the same modules across environments.)

In some cases, you may need to use `terraform state rm` to stop resources from being deleted and `terraform import` to remap existing resources from the previous version into your statefile.

### Teamwork Makes The Dream Work

Coordinate with your team to divvy up the upgrade work. It's too much work for one person and who will maintain it when you leave the company? As your team's resident Terraform Trailblazer, you will be the first to run into upgrade issues(yay.) Create documentation to help your teammates get started, they need some reassurances that they aren't gonna burn the house down. 



### In Review



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
