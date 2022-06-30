+++
title =  "Bootstrapping a new service in 60 seconds with Github, IAM, ECR, and OpenID Connect"
tags = ["terraform", "tutorial", "aws", "terraform1.0", "openidconnect", "ecr","github", "githubactions"]
date = "2022-03-01"
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfc_p1/header.jpg)


# Overview

You've built a few containerized services in AWS and there's still a lot of work that needs to get done before you can have a new service ready to deploy onto ECS or EKS. You may need to create a new Github repo, write a `Jenkinsfile` for the build process, provision a new service account, and build a new ECR repo in terraform. All this work adds up and is error-prone when done in manual steps. Today we'll go over how to quickly build a new and secure service. The first service may take a little longer to create, but depending on your copy/paste skills, you can create the 2nd/3rd/4th service in 60 seconds or less.


## Lesson

1. OpenID Connect
2. Create New Bootstrap Module
3. ECR
4. AWS IAM
5. Github
6. Deploying the Module


### OpenID Connect

OpenID Connect (OIDC) is the new thing all the kids are raving about. Previously with Github Actions, you would need to create an AWS IAM service account for a Github Actions runner to perform tasks like uploading a container image to ECR. With OpenID Connect, you just need to create an OpenID Connect Provider and IAM role/policy resources to allow Github Actions runners to create resources in AWS. When a Github Action runs, it authenticates via the OpenID Connect provider with the assumed IAM role and receives a temporary token to perform changes in AWS. I am not an expert in OpenID Connect, so [here's a video](https://www.youtube.com/watch?v=6DxRTJN1Ffo) that explains it better than I can.

#### Creating the OIDC Provider

1. You will need to create a terraform workspace separate from the new service that you want to bootstrap. Ideally this is a place where other "global" or account level AWS resources live.
2. Once that is created, you need to follow [these awful instructions](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html) to grab the thumbprint for the OIDC provider resource. You will need to remove all `:`'s from the thumbprint.
3. You will deploy the OpenID Provider resource in the previously mentioned workspace:

```hcl
resource "aws_iam_openid_connect_provider" "github_actions" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["THUMBPRINTWITHOUTCOLONSGOESHERE"]
  url             = "https://token.actions.githubusercontent.com"
}
```
_Note: You only need to create the OpenID Connect Provider resource once per AWS environment_

### Create New Bootstrap Module

After the OpenID Connect Provider has been created, you will need to create an ECR repo, IAM Role/Policy, and Github repo. Ideally all the resources related to bootstrapping a new service would live in the same module so that it can be used over and over again.
1. Create a new folder in a learning repo that you've created called `terraform-bootstrap`. In this folder create the file names `data_source.tf`, `ecr.tf`, `github.tf`, `iam.tf`, `variables.tf`, and `versions.tf`.
2. Add data source lookups for the AWS Account ID and Region to your `data_source.tf` file. You will need these later.

```hcl
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
```
3. Add common variables to the `variables.tf` file

```hcl
variable "env" {
  description = "short and unique environment name"
}

variable "service" {
  description = "unique service name which will be applied to the github and ECR repos"
}

variable "organization" {
  description = "Name of the Github Organization."
  default     = "jperez3" #this can be changed/updated after the demo
}

variable "repo_visibility" {
  description = "sets repo to public or private"
  default     = "public"
}

variable "template_repository" {
  description = "github repo name to use as template"
  default     = "repo-template-docker"
}

variable "repo_default_branch_name" {
  description = "sets the default branch name"
  default     = "main"
}


locals {
  # Name for AWS resources (gha = github actions)
  name = "gha-${var.organization}-${var.service}-${var.env}"

  common_tags = {
    Environment = var.env
    Managed-By  = "terraform"
    Service     = var.service
    TF-Module   = "${var.organization}/terraform-bootstrap/service"
  }
}
```

4. Add AWS and Github providers to the `versions.tf` file:

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.20.0"
    }
  }
}
```

### ECR

You're gonna need a place to store the container images built by Github Actions, so lets create an ECR repo.

#### Creating an ECR repo

1. In the `ecr.tf` file, create an ECR repo resource:

```hcl
resource "aws_ecr_repository" "service" {

  name = var.service

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = var.service
    })
  )
}
```
_Note: The ECR repo and Github repo use the same name to enforce consistency across the service_



### AWS IAM

You can now start to build out the IAM Role and Policy for the Github Action Runner to assume. The IAM conditions can be tricky to get right, but it's important to make sure that it's locked down as much as possible.

#### Creating an IAM Role and Policy for Github Actions

1. In the `iam.tf` file, create a new policy document for the IAM role and the IAM role itself:

```hcl
data "aws_iam_policy_document" "gha_assume_role_default" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    # This only allows builds on the default branch, another role will needed to be created for pushing to other branches
    # and releases
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${github_repository.service.full_name}:ref:refs/heads/${var.repo_default_branch_name}"]
    }
    # If you are using the official github action for docker build push, you need the condition below
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gha_default" {
  name               = "${local.name}-${var.repo_default_branch_name}"
  assume_role_policy = data.aws_iam_policy_document.gha_assume_role_default.json

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${local.name}-${var.repo_default_branch_name}"
    })
  )
}

```
_Note: Under the first conditional statement of the policy document, it requires the source to be the `main` or default branch of the repo. This helps in a situation where an untrusted entity tries to use this role_


2. In the `iam.tf` file, create the policy document for the IAM Policy and the IAM Policy itself:

```hcl
data "aws_iam_policy_document" "ecr_allow_push" {
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [aws_ecr_repository.service.arn]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_allow_push" {
  name        = "${local.name}-ecr-allow-push"
  description = "Grant Github Actions the ability to push to ${var.service} ECR repo from ${github_repository.service.full_name} github repo"
  policy      = data.aws_iam_policy_document.ecr_allow_push.json

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${local.name}-ecr-allow-push"
    })
  )
}
```
_Note: The policy will allow the role to push container images to only the ECR repo for this service._

3. In the `iam.tf` file, attach the IAM Policy to the IAM Role:

```hcl
resource "aws_iam_role_policy_attachment" "gha_default" {
  role       = aws_iam_role.gha_default.name
  policy_arn = aws_iam_policy.ecr_allow_push.arn
}
```
_Note: If you wanted to allow another branch to push containers, you would just create another role with a conditional matching on that branch name and attach it to the existing IAM Policy_


### Github

This is the first time I've used the Github Terraform Provider and I'm pretty impressed with what it can do. It can create new repos based on template repos, commit new files, configure settings, and create secrets.

#### Creating a Github Repo

1. In the `github.tf` file, create a new github repo resource:

```hcl
resource "github_repository" "service" {
  name        = var.service
  description = "github repo for ${var.service} service"

  visibility = var.repo_visibility

  template {
    owner      = var.organization
    repository = var.template_repository
  }
}
```
_Note: This is creating a repo based on a [template repo](https://github.com/jperez3/repo-template-docker) with the github action workflow and basic nginx docker container. After the demo, you can change this to your own template repo to mess around with how it works._

2. Create github action secrets in the `github.tf` file:

```hcl
resource "github_actions_secret" "aws_region" {
  repository      = github_repository.service.name
  secret_name     = "AWS_REGION"
  plaintext_value = data.aws_region.current.name
}

resource "github_actions_secret" "gha_default_role_arn" {
  repository      = github_repository.service.name
  secret_name     = "GHA_DEFAULT_ROLE_ARN"
  plaintext_value = aws_iam_role.gha_default.arn
}

resource "github_actions_secret" "ecr_repo_url" {
  repository      = github_repository.service.name
  secret_name     = "ECR_REPO_URL"
  plaintext_value = aws_ecr_repository.service.repository_url
}
```
_Note: Creating these secrets helps streamline the process of creating new services with the same github repo template and github action workflow._

3. Add outputs to make it easier for you to interact with the repo later:

```hcl
output "ssh_clone_url" {
  description = "clone url to start working witih repo"
  value       = github_repository.service.ssh_clone_url
}

output "gha_url" {
  description = "link to repo's github action tab"
  value       = "${github_repository.service.html_url}/actions"
}
```

#### Github Action Workflow

Github actions are a blessing and a curse. They are a blessing because you can build automation in github where you couldn't before and they're a curse because iterating over workflows is terrible. Tools like [ACT](https://github.com/nektos/act) help with some of the pain of testing locally, but it doesn't always work and wouldn't work for this usecase. I would normally use the official Github Action to log into ECR and use a `Makefile` to run the commands I want so that it can be tested locally, but I decided to rely soley on github actions this time.

* You don't have to do anything for this because it's built into the github template repo, but it's good to take a look at the workflow to see what it's doing:

```yaml
name: ecr-push-default

on:
  push:
    branches: ['main']

jobs:
  ecr-push:
    name: Push to ECR
    runs-on: ubuntu-latest

    # these settings are required for OpenID Connect
    permissions:
      id-token: write
      contents: read

    steps:
    - name: Checkout
      uses: actions/checkout@v2

    - name: Set up QEMU
      uses: docker/setup-qemu-action@v1

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@master
      with:
        role-to-assume: ${{ secrets.GHA_DEFAULT_ROLE_ARN }}
        aws-region: ${{ secrets.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Extract metadata (tags, labels) for Docker
      id: meta
      uses: docker/metadata-action@v3
      with:
        images: ${{ secrets.ECR_REPO_URL }}
        tags: |
          type=sha,prefix=
          type=ref,event=branch
          type=raw,value={{branch}}-{{sha}}
    - name: Build and push Docker image
      uses: docker/build-push-action@v2
      with:
        context: .
        push: true
        platforms: linux/amd64,linux/arm64
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
```
_Note: The extract metadata step is pulling out the SHA and branch name to apply them as container image tags prior to being uploaded to ECR_


### Deploying the Module

Ok this first one takes longer than expected, but you're almost there.

1. Create a new folder called `burrito` next to the `terraform-boostrap` folder.
2. Create the following files in the `burrito` folder:
   1. `provider.tf`
   2. `burrito.tf`
   3. `variables.tf`
3. Add the AWS provider and Github providers to `provider.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.2.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.20.0"
    }
  }
}


provider "github" {
  token = var.github_token
}

provider "aws" {
  region = "us-east-1"
}
```
_Note: You can change the region to your personal preference and add a backend for your statefile_

4. Add a `github_token` variable to the `variables.tf` file:

```hcl
variable "github_token" {
    description = "github personal access token"
}
```
5. Add your module to the `burrito.tf` file:

```hcl
module "burrito" {
  source = "../terraform-bootstrap"

  env     = "prod"
  service = "burrito"
}
```

6. Add the Github repo outputs to the `burrito.tf` file:

```hcl
output "ssh_clone_url" {
    value = module.burrito.ssh_clone_url
}

output "gha_url" {
    value = module.burrito.gha_url
}
```

7. You will need to create a github [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with the ability to create and delete repos
8. You will need to set that personal access token as an environment variable: `export TF_VAR_github_token='YOURPERSONALACCESSTOKENGOESHERE'`
9. Intialize your workspace: `terraform init`
10. Apply changes: `terraform apply`
11. You should see the github clone URL and actions URL in the terraform output. Click on the github actions link.
12. The first job you see probably failed, but click on the workflow itself and select "Re-run all jobs". It should work on the second try.
13. Now you can log into the AWS Console, browse to [ECR Repos](https://console.aws.amazon.com/ecr/repositories?region=us-east-1) and see your new `burrito` repo. Click on the repo and you'll see the image that was uploaded by github actions.


Now you can use this module over and over again for new services. Play around with adding new services, extending the module with new github workflows and IAM roles, and destroy them when you're done.

You can find the official code for this module [here](https://github.com/jperez3/terraform-bootstrap). A special thanks goes out to [Robert Hafner](https://twitter.com/tedivm) and [Jerry Chang](https://twitter.com/jerry__chang) for their awesome articles which helped me put this together. The articles are linked below:

* [Using Github Actions OpenID Connect to push to AWS ECR without Credentials](https://blog.tedivm.com/guides/2021/10/github-actions-push-to-aws-ecr-without-credentials-oidc/)
* [Security harden Github Action deployments to AWS with OIDC](https://www.jerrychang.ca/writing/security-harden-github-actions-deployments-to-aws-with-oidc)


### In Review

You just built the first half of this containerized puzzle by making IAM, ECR, and Github work in harmony. Now it's up to you (and me) to build how to run that container image. Depending on your goal. you can run the container via a container orchestration service like ECS or EKS. Another option would be to deploy it as a [lambda](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html). I'm looking forward to what you and your team builds, cheers!


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
