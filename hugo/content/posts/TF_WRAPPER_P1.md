+++
title =  "Terraform Wrappers - Simplify Your Workflow"
tags = ["terraform", "tutorial", "terraform1.x", "wrapper", "bash", "envsubst"]
date = "2022-11-09"
+++


![Tortillas](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tf_wrapper_p1/header.jpg)


# Overview

Cloud providers are complex. You'll often ask yourself three questions: "Is it me?", "Is it Terraform?", and "Is it AWS?" The answer will be yes to at least one of those questions. Fighting complexity can happen at many different levels. It could be standardizing the tagging of cloud resources, creating and tuning the right abstraction points (Terraform modules) to help engineers build new services, or streamlining the IaC development process with wrappers. Deeper understanding of the technology through experimentation can lead to amazing breakthroughs for your team and business.


## Lesson

* Terraform Challenges
* Terraform Wrappers
* Creating Your Own Wrapper
* Wrapper Example


### Terraform Challenges

As you experiment more with Terraform, you start to see where things can break down. Terraform variables can't be used in the backend configuration, inconsistencies grow as more people contribute to the Terraform codebase, dependency differences between provisioners, etc.

### Terraform Wrappers

You may or may not be familiar with the fact that you can create a wrapper around the terraform binary to add functionality or that several open source terraform wrappers have existed for several years already. The most well-known terraform wrapper being [terragrunt](https://terragrunt.gruntwork.io/) which was ahead of its time by filling in gaps in Terraform's features and provided things like provisioning entire environments. I tried using terragrunt around 2016 and found the documentation to be confusing and incomplete. I encountered terragrunt again in 2019 and found it be confusing and frustrating to work on. I didn't see the utility in using a wrapper and decided to steer away from wrappers, favoring "vanilla" terraform. I created separate service workspaces/modules and leaned heavily into tagging/data-sources to scale our infrastructure codebase. In 2022, we've started to support developers writing/maintaing their own IaC with our guidance. In any shared repo, you will notice that people naturally have different development techniques and/or styles. We're all about individualiiy when it comes interacting with people, but cloud providers are less forgiving. Inconsistencies across environments slow down teams, destroys deployment confidence, and makes it verify difficult to debug problems when they arise.

### Creating Your Own Wrapper

It may be difficult to figure out at first, but only you and your team know the daily pain points when dealing with terraform. You also know how organized (or disorganized) your IaC can be. At the very least, the following requirements should be met:
1. You have a well-defined folder structure for your terraform workspaces. This will allow you to cherry-pick information from the folder path and predictably source scripts or other files.
2. Your modules and workspaces have a 1:1 mapping, which means for every folder with terraform files, you're only deploying one terraform module. No indivial resource defintions are created. This helps with keeping consistency across across environments.

Once you've gotten the prereqs out of the way, you can start thinking about what you want the wrapper to do that isn't already built into the terraform binary. Start by picking one or two features and your programming language of choice. You can jump right into using something like python or go, but I would actually recommend starting with `bash`. It will work on most computers, so you don't have to worry about specific dependencies if you want a teammate to kick the tires on your terraform wrapper. If and when your terarform wrapper blows up with functionality, then you can decide to move it to a proper programming language and think about shoving it into a container image.


### Wrapper Example

#### Organization and Requirements Gathering

I've created a repo called [terraform-wrapper-demo](https://github.com/jperez3/taccoform-wrapper-demo) and inside I've created a service called `burrito`. The `burrito` service has a well-organized folder structure:

```bash
burrito
├── modules
│   └── base
│       └── workspace-templates
├── scripts
└── workspaces
    ├── dev
    │   └── base
    └── prod
        └── base
```

I also have a 1:1 mapping between my `base` workspaces and modules. The burrito module is very basic and for demonstration purposes only includes an s3 bucket. If this were a real service, it would have more specifics on compute, networking, and database resources.

Ok, this set up is great, but even with the 1:1 mapping of workspaces to modules, we're still seeing inconsistencies across environments. Some inconsistencies are small like misspelled tags and others are big like a security group misconfigurations. As a member of the team who contributes to the `burrito` service's codebase, I want things to be consistent across environments. Advancing changes across nearly identical environments gives a developer confidence that the intended change will be uneventful once it reaches production.

It sounds like templates can help mitigate fears of inconsistency across environments. Let's put together some requirements:
1. The wrapper should be similar to the existing terraform workflow to make it easy to use
2. Workspace templates should be pulled from a centralized location, injected with environment specific variables, and placed into their respective workspaces.


#### Starting The Wrapper Script

We want the wrapper script to act similar to the `terraform` command. So the script will start with a command (the script name) and we'll call it `tee-eff.sh`. We'll also expect it to take a subcommand. If you're familiar with Terraform, this is stuff like `init`, `plan`, `apply`. Using the script would look something like `tee-eff.sh plan`.

1. Ok now to start the script and lets begin with the input:

`tee-eff.sh`
```bash
#!/bin/bash

SUBCOMMAND=$1
```
* Now any argument supplied to the script will be set as the `SUBCOMMAND` variable.

2. Now we can focus on the variables we need to interpolate by looking at the `provider.tf` file:

```hcl
terraform {
    backend "s3" {
        bucket = "$TF_STATE_BUCKET_NAME-$ENV"
        key    = "$REPO_NAME/$SERVICE_PATH/terraform.tfstate"
        region = "$BUCKET_REGION"
    }

}

provider "aws" {
    region = "$AWS_REGION"

    default_tags {
        tags = {
            Terraform_Workspace = "$REPO_NAME/$SERVICE_PATH"
            Environment         = "$ENV"
        }
    }
}

terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
    }

    required_version = "~> 1.0"
}
```
* We'll want to replace any variables denoted with a `$` at the beginning with values from our `tee-eff.sh` script. The same goes for variables in the `burrito_base.tf` file which can be found below:

`burrito_base.tf`
```hcl
module "$SERVICE_$MODULE_NAME" {
    source = "../../../modules/$MODULE_NAME"

    env = "$ENV"
}
```
_Note: Things like the backend values and module name cannot rely on terraform variables because those variables are loaded too late in the terraform execution process to be used._

3. After we've tallied up the required variables, we can come back to the `tee-eff.sh` script to set those variables as environment variables:

`tee-eff.sh`
```bash
#!/bin/bash

SUBCOMMAND=$1

echo "***SETTING VARIABLES***"
# Terraform Backend S3 Bucket
export TF_STATE_BUCKET_NAME='taccoform-tf-backend'

# current working directory matches module name
export MODULE_NAME=$(basename $PWD)

# Retrieve absolute path for repo
export REPO_PATH=$(git rev-parse --show-toplevel)

# Parse out repository name from repository path
export REPO_NAME=$(basename ${REPO_PATH})

# grab service path name, eg. "burrito/workspaces/dev/base"
export SERVICE_PATH=${PWD#*$REPO_NAME/}

# remove everything after service path's first slash to retrieve service name
export SERVICE=${SERVICE_PATH%/workspaces*}

# Remove everything before workspace and split string to get environment name
export ENV=$(echo ${SERVICE_PATH#*/workspaces/} | cut -d "/" -f 1)

# Constructing module path for template files to be listed and rendered
export TEMPLATE_PATH="${REPO_PATH}/${SERVICE}/modules/${MODULE_NAME}"
```

4. Make sure you have `envsubst` installed, if not, I believe you can install it via `pip install envsubst`
5. While in a terrform workspace (or folder), you want to add a `render` command to push our environment variables into the template files and place them into the current working directory. We can accomplish this by adding the following if/for loop:

`tee-eff.sh`
```bash
...
...
...
if [[ $SUBCOMMAND == *"render"* ]]; then
    echo "removing any existing terraform files in current working directory"
    echo ""
    rm -rf $PWD/*.tf

    echo "***RENDERING TEMPLATE FILES***"
    export TEMPLATE_FILES=$(ls $TEMPLATE_PATH/workspace-templates/*.tf)

    for FILE_PATH in $TEMPLATE_FILES; do
        export FILE_NAME=$(basename ${FILE_PATH})
        echo "File Name: ${FILE_NAME}"
        envsubst < ${FILE_PATH} | tee ./${FILE_NAME}
        echo ""
    done
...
...
...
```

6. We also want this script to be able to run terraform `init`, `plan`, and `apply`

`tee-eff.sh`
```bash
...
...
...
elif [[ $SUBCOMMAND == *"init"* || $SUBCOMMAND == *"plan"* || $SUBCOMMAND == *"apply"* ]]; then
    terraform $SUBCOMMAND
else
    echo "$SUBCOMMAND isn't an available terraform subcommand"
fi
```
7. I'll now save the `tee-eff.sh` script and make sure that it's executable via `chmod +x tee-eff.sh`
8. Now I'll navigate to `burrito>workspaces>dev>base` directory in my `taccoform-wrapper-demo` repo and run `./tee-eff.sh render`:

```bash
./tee-eff.sh render
***SETTING VARIABLES***
Module Name:  base
Repo Name:    taccoform-wrapper-demo
Repo Path:    REDACTEDGITPATH/taccoform-wrapper-demo
Service Path: burrito/workspaces/dev/base
Service:      burrito
Environment:  dev
Template Path: REDACTEDGITPATH/taccoform-wrapper-demo/burrito/modules/base

removing any existing terraform files in current working directory

***RENDERING TEMPLATE FILES***
File Name: burrito_base.tf
module "base" {
    source = "../../../modules/base"

    env = "dev"
}

File Name: provider.tf
terraform {
    backend "s3" {
        bucket = "taccoform-tf-backend-dev"
        key    = "taccoform-wrapper-demo/burrito/workspaces/dev/base/terraform.tfstate"
        region = ""
    }

}

provider "aws" {
    region = ""

    default_tags {
        tags = {
            Terraform_Workspace = "taccoform-wrapper-demo/burrito/workspaces/dev/base"
            Environment         = "dev"
        }
    }
}

terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
    }

    required_version = "~> 1.0"
}
```

9. Now I can run `./tee-eff.sh init` to continue working with Terraform **OR** I can just use `terraform init`. That flexibility is super helpful when debugging Terraform problems.

* You can find this code [here](https://github.com/jperez3/taccoform-wrapper-demo/tree/main/burrito) and the `burrito` `prod` folder is set up for you test without the generated files. You will also have to update the `tee-eff.sh` script's `TF_STATE_BUCKET_NAME` variable to a bucket you own and the `provider.tf` bucket name.

### In Review

Hopefully this demo gives you an idea about how a terraform wrapper can be a quality of life improvement. Of course you can go wild with it, but remember that you're already dealing with distributed systems, Terraform, AWS and who knows what else. Keep it simple.

---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
