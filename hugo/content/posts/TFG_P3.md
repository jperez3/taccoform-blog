+++
title =  "Drift Detection with Github Actions"
tags = ["terraform", "tutorial", "digitalocean", "github-actions", "github", "drift"]
date = "2021-08-30"
+++


![](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfg_p3/header.jpg)


# Overview

It's Friday at 5PM and an urgent requests comes in from the Chief Infotainment Officer. You know exactly what you have to update in terraform and create a new feature branch to make the changes. You're rolling through the lower environments and finally get to production. You run a `terraform plan` and unexpected resource deletions show up in the output. You panic a little, then realize that your work didn't trigger the deletion. Terraform "drift" is getting between you and the weekend. Today we're going to talk about a strategy to help identify drift before it becomes a problem.  


## Lesson

* What is "drift"? 
* How can I detect drift? 
* How do I remediate drift? 
* How can I automate drift detection? 


### What is "drift"?

As great of a tool that Terraform is, it's not perfect. One problem is drift. Drift is when running a `terraform plan` detects differences between the terraform code in your current branch and the workspace's statefile. This change can be the result of work that's not merged in from a feature branch or peers actively working in the same workspace. Your `main` branch should be the source of truth when no active development is happening. 


### How can I detect drift? 

You can run a `terraform plan` to check for drift and it's always a good idea to run a `terraform plan` prior to making any changes to the modules and/or resources in a terraform workspace. 



### How do I remediate drift?

You can remediate drift by:
* pulling changes from the `main` branch to get caught up
* adding the missing resource definitions and/or modules for resources marked for deletion
* removing resource definitions and/or modules for resources that will be created
* If a resource definition is defined, but is still marked for creation, you can import that resource into your terraform statefile.  

### How can I automate drift detection? 

I recently discovered that terraform has a built-in flag called `-detailed-exitcode`. When appended to a `terraform plan` the detailed exit code flag outputs one of three exit codes:
* 0 - We're good, no changes were detected
* 1 - damn, something bad happened
* 2 - Oh no! Drift detected! 
_Note: After running `terraform plan -detailed-exitcode`, you can run `echo $?` to output the exit code of the previous command_

You can use these exit codes in automation to alert you when changes and/or problems occur. One way you can automate this process is through github actions. You can create a github actions workflow (which is just a yaml file) to run on a schedule. Github action workflows live in your repo's `.github/workflows` folder.

An example workflow could look like this:

```yml
name: "taccoform-drift"

on:
  schedule:
    - cron: '55 5 * * *'

env:
  TF_VERSION: 1.0.4

defaults:
  run:
    working-directory: taccoform/app

jobs:
  drift:
    name: "Terraform"
    runs-on: ubuntu-20.04    
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          terraform_version: ${{ env.TF_VERSION }}
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}       

      - name: Terraform Version
        id: version
        run: terraform version

      - name: Terraform Format
        id: fmt
        run: terraform fmt -check

      - name: Terraform Init
        id: init
        run: terraform init
        env:
          TF_VAR_do_token: ${{ secrets.TF_VAR_DO_TOKEN }}
        

      - name: Terraform Plan
        id: plan
        run: terraform plan -detailed-exitcode
        continue-on-error: true
        env:
          TF_VAR_do_token: ${{ secrets.TF_VAR_DO_TOKEN }}
        

      - name: Terraform Plan Status
        if: steps.plan.outcome == 'failure'
        run: |
          echo "Drift detected on this terraform workspace"
          exit 1
```          

It's a lot to take in if it's your first time looking at a github action, so we'll go through it piece by piece.


* At the top you'll find general configuration stuff like the github action name, how it is triggered and any variables:


```yml
name: "taccoform-drift"

on:
  schedule:
    - cron: '55 5 * * *'

env:
  TF_VERSION: 1.0.4

defaults:
  run:
    working-directory: taccoform/app
```
This github action is triggered on a schedule and uses cron notation to tell the action when to run. The environment variable for terraform version is created and will be used later down the line. And finally, the `defaults` option tells the github action which folder to run commands in. Remember that on it's own, terraform only reads configuration files from your current directory.

* Next you'll find a `jobs` heading, a job is basically a list of ordered instructions. The job will use a github runner based on Ubuntu 20.04 (pinning the version is important), checkout the github repo's main branch, set up terraform with the environment variable we specified earlier and use the terraform cloud token to fetch the statefile. You may not be using terraform cloud and that's fine, but you're configuration may differ a little bit to fetch your statefile. Also note that the token is prefixed with `secrets.` which is a secret which you'll define at an earlier time. 

```yml
jobs:
  drift:
    name: "Terraform"
    runs-on: ubuntu-20.04    
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          terraform_version: ${{ env.TF_VERSION }}
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}
```          

* If you've ran terraform commands before, the next portion should look familiar. We're verifying the terraform version used (good for debugging), checking the formatting of the terraform code and initializing the terraform workspace. 

```yml
      - name: Terraform Version
        id: version
        run: terraform version

      - name: Terraform Format
        id: fmt
        run: terraform fmt -check

      - name: Terraform Init
        id: init
        run: terraform init
        env:
          TF_VAR_do_token: ${{ secrets.TF_VAR_DO_TOKEN }}
        
```


* Now on to the main course, we run `terraform plan -detailed-exitcode` and tell the job to continue even if the step fails. On the next step, we read the exit code from the plan step and tell it to output "drift detected on this terraform workspace" when the exit code is something other than zero. 
```yml
      - name: Terraform Plan
        id: plan
        run: terraform plan -detailed-exitcode
        continue-on-error: true
        env:
          TF_VAR_do_token: ${{ secrets.TF_VAR_DO_TOKEN }}
        

      - name: Terraform Plan Status
        if: steps.plan.outcome == 'failure'
        run: |
          echo "Drift detected on this terraform workspace"
          exit 1
```          
This is a simple example, but you can also configure github actions to send you a slack alert or email when a problem occurs. After you add this workflow to your `main` branch, the workflow will be activated. You can then go to your repo's `Actions` tab and choose the `taccoform-drift` workflow. The workflow will run at the interval you specified in the cron field. It seems like the lowest interval you can set on a schedule right now is ~7 minutes. You can see an example of the jobs running on a schedule [here](https://github.com/jperez3/taccoform-blog/actions/workflows/taccoform-drift.yml)



It is worth calling out that tools like [atlantis](https://www.runatlantis.io/) and others have drift detection built in, but most of the time require additional servers and/or containers to manage. Some alternatives are subscription based services and might not be in your budget. Github actions aren't free, but they are cheap for now.

### In Review

We've talked about drift, how to remediate it, and how to get ahead of it. By building in drift detection, you and your team will move faster because less time will be spent on fixing things unrelated to your task at hand. 

This post was inspired by [Julie Ng's](https://twitter.com/jng5) work on [Azure DevOps Governance](https://github.com/azure/devops-governance)



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
