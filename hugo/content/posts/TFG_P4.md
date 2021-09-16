+++
title =  "Terraform Upgrades"
tags = ["terraform", "upgrades", "maintenance"]
date = "2021-09-15"
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfg_p4/header.jpg)


# Overview

You've started down a path to implement a change requested by your product team and you are quick to realize that your provider version and/or terraform version are too old to make the change. What seemed like a minor change turned into hours or days of yak-shaving. To help avoid these issues and security vulnerabilities, it's best to keep your terraform code up to date.  


## Lesson

* Why Should I Upgrade?
* Where Do I Start?
* Upgrading Terraform Modules
* Upgrading your Terraform CLI Version
* Upgrading Terraform Workspaces
* Teamwork Makes The Dream Work


### Why Should I Upgrade? 

Upgrading Terraform isn't always required, but upgrading helps with bugs you run into and you will be able to take advantage of the available community to help when problems come up. You also might need to upgrade your terraform because a feature is only available in a newer version of your provider. This happened between Terraform 0.11.X and 0.12.X for the AWS provider. Depending on public terraform modules might also force you to move to a newer version of terraform and/or will require you to fork the module and maintain it yourself. I'm more inclined to build modules in-house to help support the technology from an operational perspective and to have more control over upgrades. 

Security is another reason to upgrade your Terraform. Vulnerabilities are found in every software tool. Terraform is no [different](https://venturebeat.com/2021/04/26/hashicorp-revoked-private-key-exposed-in-codecov-security-breach/). 


### Where do I Start?

First you will start with the official [Terraform Upgrade Guides](https://www.terraform.io/upgrade-guides/index.html). This will help help you know about any gotchas. To date, the jump from 0.11.x to 0.12.x has been the biggest update because of the syntax changes between Hashicorp Configuration Language (HCL) versions 1 and 2. 

Make sure that versioning is turned on wherever you store your Terraform statefiles. If something goes wrong, you can rollback to your previous statefile and code to start over. Your mileage may vary though, depending on resource deletions during your original testing. 

### Upgrading Terraform Modules

Terraform modules can be tricky to upgrade because of any existing deployments which rely on those modules. If you manage a lot of terraform modules or the terraform upgrade is competing with other business initiatives, I would recommend copying that module to a new folder in your terraform module repo and upgrading it to your desired version. This will allow the other modules to continue services the other deployments, especially in the case of an emergency. I would also recommend using semantic versioning to help people understand which version of the module they are referencing. Eg:

```
Terraform 0.11.x = 1.X.X
Terraform 0.13.x = 2.X.X
Terraform 0.15.x = 3.X.X 
```

The main point of versioning modules is to help your team with context about how modules are progressing. Remember that your goal is still to get all of your code onto a newer version. Getting buy-in from management is key to making progress on this initiative. Also be sure to pick versions to support. If you choose to upgrade to each terraform version sequentially, you'll spend all of your time doing upgrades and no actual building. This is due to the rapid release cycle for Terraform.


| Version | Release Date |
| ------- | ------------ |
| 0.11.0  | 11-16-17     |
| 0.12.0  | 05-22-19     |
| 0.13.0  | 08-10-20     |
| 0.14.0  | 12-02-20     |
| 0.15.0  | 04-15-21     |
| 1.0.0   | 06-08-21     |



### Upgrading your Terraform CLI Version

Before you upgrade your terraform workspace, you should upgrade the terraform CLI to the most recent release for your current version. For example, if you were upgrading from Terraform 0.11.X to 0.12.X, you should make sure you're using the most recent Terraform 0.11.X version (0.11.15) A tool like [tfswitch](https://tfswitch.warrensbox.com/) is great for helping you manage multiple Terraform versions on your local machine.



### Upgrading Terraform Workspaces

Your terraform workspace organization will dictate how you will tackle the upgrade. If you are crazy and deployed all of an environment's resources in a single workspace, you will need to update everything at once. This is not a great organization approach, but it's effective and risky. It would be better to split your workspaces into smaller, loosely coupled workspaces. If you mess up one aspect of your system, it's a big deal, but it's not the end of the world. 

Use lower environments and test environments to see what happens when you upgrade to a newer version of terraform. Nothing builds confidence like upgrading through several lower environments prior to production (as long as you're using the same terraform modules across environments.)

In some cases, you may need to use `terraform state rm` to stop resources from being deleted and `terraform import` to remap existing resources from the previous version into your statefile.



### Teamwork Makes The Dream Work

Coordinate with your team to divvy up the upgrade work. It's too much work for one person and who will maintain it when you leave the company? As your team's resident _Terraform Trailblazer_, you will be the first to run into upgrade issues (yay.) Create documentation to help your teammates get started, they need some reassurances that they aren't gonna burn the house down. 



### In Review

This is not an exhaustive list of how to upgrade your terraform code because everyone will have different starting points. Some people may start on an older terraform version and no modules, some with modules and large workspaces, etc. Create a plan with tasks that can be divvied up, set milestones and push management to get this onto a regular maintenance schedule with priority. 

---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
