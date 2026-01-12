+++
title =  "Using Python and Claude to Wrangle Infrastructure"
tags = ["terraform","terraform1dot5"]
date = "2023-11-07"
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tts_p1/header.jpg)


# Overview




## Lesson

* Pre-Flight 
* Setting up Project
* Creating Terraform Module And Workspaces
* Creating Automation Scripts With Claude 
* 

### Pre-Flight

1. Install your Terraform version of choice
2. Install [Docker](https://docs.docker.com/engine/install/)
3. Install `uv` by running: `curl -LsSf https://astral.sh/uv/install.sh | sh`

### Setting Up Project

We're going to be using python to drive the terraform automation, so that means we're gonna use [uv](https://docs.astral.sh/uv/) to handle our python project because all the cool kids are doing it. 
1. Create a new git repo named `terraform-claude` and open the terminal
2. Initialize your project: `uv init .`
3. Add your first dependency `ruff` (a python linter): `uv add ruff`
4. Run `ruff` via `uv` to make sure things are working: `uv run ruff check`
```BASH
❯ uv run ruff check
All checks passed!
```
5. You can also run `main.py` which is initialized with an output:
```BASH
❯ uv run main.py
Hello from terraform-claude!
```


### Creating Terraform Module And Workspaces

#### Terraform Module

Now we need some Terraform code and workspaces to run our code against. We're going to be using Terraform to create some local docker images and containers. This is easier than having to set up authentication to a cloud provider and has the added benefit of being free.

1. Create the module directory and module files: `mkdir -p terraform/burrito/module && cd terraform/burrito/module && touch docker.tf Dockerfile variables.tf versions.tf`
2. We need to specify a docker provider that will interact with our local docker process. Add the following to the `versions.tf` file:

```bash
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.16.0"
    }
  }
}
```
3. Now we need to define a `docker_image` and `docker_container` resource:
```bash
resource "docker_image" "burrito" {
  name = "burrito-${var.environment}"
  build {
    path = "${path.module}/."
    dockerfile = "Dockerfile"
    tag  = ["burrito:${var.environment}"]

  }
}

resource "docker_container" "burrito" {
  name  = "burrito-${var.environment}"
  image = flatten(docker_image.burrito.build[*].tag)[0]
  ports {
      external = var.port
      internal = 5678
  }
  env = [
    "ECHO_TEXT='Hello from the ${var.environment} burrito!'",
  ]
}
```
4. Create the `environment` and `port` variables in the `variables.tf` file which will be exposed via the terraform module:
```bash
variable "environment" {
  description = "The environment for the Burrito module, e.g., dev, prod."
  type        = string
  
}

variable "port" {
  description = "The external port to expose for the Docker container."
  type        = number
  default     = 5678
  
}

```
5. Update `Dockerfile` to use a slim image. We're using a simple web service maintained by Hashicorp for testing purposes:
```Dockerfile
FROM hashicorp/http-echo

ENV ECHO_TEXT="python testing"

ENTRYPOINT ["/http-echo"]
```

#### Terraform Workspaces

We're going to create to workspaces in separate folders. I know that some people don't love this way of doing things, but it adds more flexibility to the when/how things can be changed.

1. Create the `dev` and `prod` workspace directories: `cd $(git rev-parse --show-toplevel) && mkdir -p terraform/burrito/environments/{dev,prod}`
2. Create `docker.tf` and `provider.tf` files in each workspace: `touch terraform/burrito/environments/dev/{provider.tf,docker.tf} && touch terraform/burrito/environments/prod/{provider.tf,docker.tf}`
3. Open the `provider.tf` file in each environment and add the docker provider:
```bash
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.16.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
```
4. Open the `docker.tf` file in `dev` and add: 
```bash
module "python_terraform" {
  source = "../../module"

  environment = "dev"
  port        = 4678
}
```
5. Open the `docker.tf` file in `prod` and add: 
```bash
module "python_terraform" {
  source = "../../module"

  environment = "dev"
  port        = 5678
}
```
6. Go into the `dev` workspace and run `terraform init && terraform apply`
```bash
Terraform will perform the following actions:

  # module.python_terraform.docker_container.burrito will be created
  + resource "docker_container" "burrito" {
      + attach           = false
      + bridge           = (known after apply)
      + command          = (known after apply)
      + container_logs   = (known after apply)
      + entrypoint       = (known after apply)
      + env              = [
          + "ECHO_TEXT='Hello from the dev burrito!'",
        ]
      + exit_code        = (known after apply)
      + gateway          = (known after apply)
      + hostname         = (known after apply)
      + id               = (known after apply)
      + image            = "burrito:dev"
      + init             = (known after apply)
      + ip_address       = (known after apply)
      + ip_prefix_length = (known after apply)
      + ipc_mode         = (known after apply)
      + log_driver       = (known after apply)
      + logs             = false
      + must_run         = true
      + name             = "burrito-dev"
      + network_data     = (known after apply)
      + read_only        = false
      + remove_volumes   = true
      + restart          = "no"
      + rm               = false
      + security_opts    = (known after apply)
      + shm_size         = (known after apply)
      + start            = true
      + stdin_open       = false
      + tty              = false

      + ports {
          + external = 4678
          + internal = 5678
          + ip       = "0.0.0.0"
          + protocol = "tcp"
        }
    }

  # module.python_terraform.docker_image.burrito will be created
  + resource "docker_image" "burrito" {
      + id          = (known after apply)
      + latest      = (known after apply)
      + name        = "burrito-dev"
      + output      = (known after apply)
      + repo_digest = (known after apply)

      + build {
          + dockerfile = "Dockerfile"
          + path       = "../../module/."
          + remove     = true
          + tag        = [
              + "burrito:dev",
            ]
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```
7. Type `yes` to continue with the apply
8. After the apply completes, you can `curl` localhost with the container's port to see the response:
```bash
❯ curl localhost:4678
'Hello from the dev burrito!'
```
9. You can now run `terraform destroy` to remove the container and image.
10. Do the same validation in the `prod` workspace to make sure it is also working correctly. After you apply, you can use `curl` again with the `prod` port:
```bash
curl localhost:5678
'Hello from the prod burrito!'
```


### In Review



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
