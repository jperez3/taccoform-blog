+++
title =  "Taccoform Tutorial Series - Part III"
tags = ["terraform", "tutorial", "digitalocean", "terraform13", "variables", "load_balancer"]
date = "2020-12-13"
+++


![tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tts_p3/header.jpg)

# Overview

Greetings Taccoformers! In the previous tutorial you learned how to create multiple resources with `count` and `for_each`. In _Part III_ of the _Taccoform Tutorial Series_, we'll focus on creating variables to keep our terraform code easy to work on and `DRY` (Don't Repeat Yourself).  

# Lesson 3

Today's lesson will cover:
* Creating variable definitions
* Variable naming
* How to organize variables
* Using variables in resource definitions
* Creating a load balancer
* Using variables across multiple resource definitions
* How to override a variables default value




### Pre-Flight

1. Navigate to the `tutorial-3>app` folder in the `taccoform-tutorial` repo that you forked in _Part I_ of the _Taccoform Tutorial Series_. If you don't see the folder, you may need to update your [fork](https://docs.github.com/en/free-pro-team@latest/github/collaborating-with-issues-and-pull-requests/syncing-a-fork)
2. Copy your `secrets.tf` file from `tutorial-2>app` to `tutorial-3>app`

### Variable creation

##### The Anatomy of a Variable

```hcl
variable "env" {
  description = "short and unique environment name"
  default     = "prod"
}
```

| Component            | Description                                                                              |
| :------------------- | :--------------------------------------------------------------------------------------- |
| description          | an optional parameter, but I strongly suggest assigning one to every variable            |
| default              | an optional parameter that assigns a default value to the variable if one isn't provided |


* In the example above we've created a string variable, but you can also create variables which are booleans, integers, lists and maps.

_list example_

```hcl
variable "private_networks" {
  description = "a list of default private networks"
  default     = ["10.0.0.0/24","10.0.1.0/24","10.0.2.0/24]
}
```

_integer example_

```hcl
variable "droplet_count" {
  description = "the amount of droplets to provision"
  default     = 2
}
```

_boolean example_

```hcl
variable "droplet_monitoring" {
  description = "boolean controlling whether monitoring agent is installed"
  default     = true
}
```

_map example_

```hcl
variable "droplet_names" {
  description = "map of droplet names"
  default = {
        "web0" = "web0-burrito-prod"
        "web1" = "web1-burrito-prod"
    }
}
```

### Variable Naming

Variable naming isn't always easy, but there are a couple things that I've picked up on:


* If there is a variable that you want to set to a paramater in a resource definition, be sure you align the variable name to the parameter.
    - eg.    

```hcl
resource "digitalocean_droplet" "web" {

  image  = var.droplet_image
  ...
  ...

}
```
_Notice the `droplet_` prefix, this helps when you have different resource definitions with similar parameter names._ 

* You will also have variables that will be used by multiple resource definitions. Some of these variables will be consistent across all of your resources which require them. An example of this type of variable in DigitalOcean is `region`. It's likely that you would want to build resources which work together and a common cloud provider constraint is that all complimentary resources must reside in the same geographic region. Each cloud provider has created their own shorthand for the geographic regions they've created to host your resources. 
    - eg.

```hcl
resource "digitalocean_droplet" "web" {

  image  = var.droplet_image
  ...
  region = var.region

}

resource "digitalocean_loadbalancer" "public" {

  ...
  region = var.region
  ...

}
```

* Another type of variable that is used across multiple resource definitions will be specific to you and/or your company. These variables will help inforce standardized naming and provide uniquness to the resources that you have created. Common variables of this type are `service` (or `app`) and `env` (or `environment`)
    - eg.

```hcl
resource "digitalocean_droplet" "web" {

  image  = var.droplet_image
  name   = "web-${var.service}-${var.env}"
  region = var.region

}

resource "digitalocean_loadbalancer" "public" {

  name   = "pub-lb-${var.service}-${var.env}"
  region = var.region
  ...
  
}
```
_The quotes/`$`/curly brackets are necessary because some variable interpolation is happening prior to passing the value to the resource definition's `name` parameter. `droplet_image` and `region` are passed to the resource definition "as-is", so they don't require the extra formatting. You might wonder why we don't just set the interpolation (`"lb-${var.service}-${var.env}"`) as the `default` when creating the variable, but terraform doesn't allow you to do this in regular variables._ 

### Variable Organization

* Start this section by opening your fork of the `taccoform-tutorial` repo and browsing to the `tutorial-3/app.` Copy your `secrets.tf` from the previous tutorial's folder. Open the `droplet.tf` file, uncomment the resource definition (and `output`) which uses `count` and comment out the resource definition (and `output`) that uses `for_each`. Your new `droplet.tf` file should look like this:

`droplet.tf`
```hcl
data "digitalocean_ssh_key" "root" { 
  name = "taccoform-tutorial"
}

resource "digitalocean_droplet" "web" {
  count = 2

  image     = "ubuntu-20-04-x64"
  name      = "web${count.index}-burrito-prod"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [data.digitalocean_ssh_key.root.id]
  user_data = templatefile("templates/user_data_nginx.yaml", { hostname = "web${count.index}-burrito-prod" })
}

output "droplet_public_ips" {
  value = digitalocean_droplet.web.*.ipv4_address
}


# resource "digitalocean_droplet" "web" {
#   for_each = {
#         "web0" = "web0-burrito-prod"
#         "web1" = "web1-burrito-prod"
#     }

#   image     = "ubuntu-20-04-x64"
#   name      = each.value
#   region    = "sfo2"
#   size      = "s-1vcpu-1gb"
#   ssh_keys  = [data.digitalocean_ssh_key.root.id]
#   user_data = templatefile("templates/user_data_nginx.yaml", { hostname = each.value })
# }

# output "droplet_public_ips" {
#   value       = { 
#     for droplet in digitalocean_droplet.web:
#     droplet.name => droplet.ipv4_address 
#   }
# }
```



#### Variable File Organization

* You can put your variable definitions in any `.tf` and the usual _"Hello World"_ Terraform tutorials will usually tell you to create two files. A `main.tf` file for all of your resource definitions and a `variables.tf` file for all of your variable definitions. Don't do this. It's not that you can't fix it later, but the organization in advance will help you a ton with understanding the components of your terraform and there are several advantages that will come later when you are troubleshooting your terraform and/or when you start to create reusable terraform modules. I like to separate resources by their type (eg. `droplets.tf`) and accompanied by a variable file (eg. `droplets_variables.tf`). 

1. Create a new `droplet_variables.tf` file next to your `droplet.tf` file.
2. Take a look at the `web` resource definition in your `droplets.tf` and take note of the parameters that area strings or integers
  - `count`
  - `image`
  - `name`
  - `region`
  - `size`

* Let's create variables for these parameters and place them in their logical variable file.

3. `count` is a parameter that every resource has the ability to assign, but in this particular instance we're concerned with the number of droplets to provision.
  - Create a new variable definition for `droplet_count` in `droplet_variables.tf`:

```hcl
variable "droplet_count" {
  description = "the number of droplets to provision"
  default     = 2
}
```

4. `image` is a parameter which is specific to the droplet creation, so the variable belongs with other droplet variables in `droplet_variables.tf`
  - Under the `count` variable definition, create a new variable definition for `droplet_image` in `droplet_variables.tf`:
  
```hcl
variable "droplet_image" {
  description = "the base image/OS to use for provisioning the droplet"
  default     = "ubuntu-20-04-x64"
}
```
_Notice how the default value was pulled directly from the value assigned to `image` in the droplet resource definition_

5. `name` is an interesting one because it's using variable interpolaion because of the count paramater and because it represents multiple variables, some that can be used by other resource definitions.
 - `web` represents a node/droplet/vm type. 
 - `burrito` represents a unique service and/or application name that can help group related resources.
 - `prod` represents a unique environment/stage name shared by adjacent resources.
```
 name      = "web${count.index}-burrito-prod"
               |                     |      \
               |                     |       \
               |                     |        |
               V                     V        V
            Node Type - #   -     Service - Environment
                                 
```
6. Create a new `droplet_node_type` variable definition in the `droplet_variables.tf` file

```hcl
variable "droplet_node_type" {
  description = "the node/droplet/vm type"
  default     = "web"
}
```

7. For the next string `burrito`, which is the service and/or application name, you will need to create a variable file for variables that are common among all resources. Create a `variables.tf` file for these variables. You're probably rolling your eyes right now because earlier I told you to not use `variables.tf`. Context is important here, in that previous scenario you'd be putting EVERY variable definition in one file. In this scenario, you'll just be storing a few variables in the `variables.tf` file. This file name also isn't set in stone, you could use any `.tf` name tha makes sense to you. 

`variables.tf`
```hcl
variable "service" {
  description = "a short/unique service and/or application name"
  default     = "web"
}
```

8. The next string `prod` is similar to `burrito` (or service name) in that it would be used by multiple resources and that environment variable should live in `variables.tf`
  - Create an `env` variable definition:

```hcl
variable "env" {
  description = "a short/unique environment name"
  default     = "prod"
}
```
9. The next variable in the list after `name` is `region`, this is a variable that could potentially be used by multiple resources to tell DigitalOcean where to provision the infrastructure.
  - Create a `region` variable definition in `variables.tf`:

```hcl
variable "region" {
  description = "a digital ocean provided geographic location"
  default     = "sfo2"
}
```

10. And finally, the `size` parameter is specific to the droplet resource definition and "size" can be a common parameter name for cloud resources, so it's especially important to prefix the variable name with `droplet_` to clearly signify what _this_ size maps to

```hcl
variable "droplet_size" {
  description = "digital ocean provided droplet size"
  default     = "s-1vcpu-1gb"
}
```


* After all is said and done, your `droplet_variables.tf` file should look like this:

```hcl
variable "droplet_count" {
  description = "the number of droplets to provision"
  default     = 2
}

variable "droplet_image" {
  description = "the base image/OS to use for provisioning the droplet"
  default     = "ubuntu-20-04-x64"
}

variable "droplet_node_type" {
  description = "the node/droplet/vm type"
  default     = "web"
}

variable "droplet_size" {
  description = "digital ocean provided droplet size"
  default     = "s-1vcpu-1gb"
}
```

* And your `variables.tf` file should look like this:

```hcl
variable "service" {
  description = "a short/unique service and/or application name"
  default     = "burrito"
}

variable "env" {
  description = "a short/unique environment name"
  default     = "prod"
}

variable "region" {
  description = "a digital ocean provided geographic location"
  default     = "sfo2"
}
```


#### Using Variables in Resource Definitions

* Now that you've defined variables, it's time to plug them into a resource definition.

1. Open the `droplet.tf` file and scroll down to the `count` parameter in the `droplet` resource definition
2. Replace the `count` value of `2` to the `droplet_count` variable you previously created. To call a variable, you need to use `.var` as a prefix. In this case, it would be `var.droplet_count` and it would look like this:

`droplet.tf`
```hcl
resource "digitalocean_droplet" "web" {
  count = var.droplet_count
  ...
  ...
  ...
}
```
3. Replace the `image` parameter value with the `droplet_image` variable you created
  - eg. `image = var.droplet_image`
4. Moving on to the `name` paramter, it requires a little bit more syntax because it will be doing a bit of interpolation or manipulation of the string prior to sending the request to DigitalOcean. 
  - Replace `web` with `${var.droplet_node_type}`. the `$` and curly brackets are required when performing variable interpolation. If you don't put the `$` and curl brackets around the variable, interpret that literally and you'll end up with a droplet named `var.droplet_node_type0-burrito-prod`
  - Replace `burrito` with `${var.service}` 
  - Replace `prod` with `${var.env}`
  - While you are at it, perform the previous three steps on the `user_data` parameter in the `web` droplet's resource definition
5. Replace the `region` parameter's value to the `region` variable you defined earlier
6. Replace the `size` parameter's value to the `droplet_size` variable you created previously and save the `droplet.tf` file


* Your `web` droplet's resource definition should look like this now:

`droplet.tf`
```hcl
resource "digitalocean_droplet" "web" {
  count = var.droplet_count

  image     = var.droplet_image
  name      = "${var.droplet_node_type}${count.index}-${var.service}-${var.env}"
  region    = var.region
  size      = var.droplet_size
  ssh_keys  = [data.digitalocean_ssh_key.root.id]
  user_data = templatefile("templates/user_data_nginx.yaml", { hostname = "${var.droplet_node_type}${count.index}-${var.service}-${var.env}" })
}
```

7. Run `terraform init` then `terraform plan` to verify that your substitutions have worked. If you get errors from either command, double-check your spelling on the variable definitions and where they are called in the resource definitions. Another thing to check is the syntax when calling variables, especially on the `name` parameter where it requires multiple sets of `$` sign and curly brackets `{}`.

* And now you're saying to yourself, _"Ok I'm exactly where I was before with the terraform provisioning, I don't think it's worth all that extra work."_ I don't blame that line of thought. Where this becomes interesting is when you're managing more resources and troubleshooting.


#### Adding a Load Balancer

* At some point your application will become super popular and you're on your way to becoming a millionaire, but first you need to make sure your application can scale. Adding a load balancer in front of your droplets will allow you to add more droplets as your traffic increases. In the default configuration, a load balancer will send traffic in a _round-robin_ fashion to each of your droplets. If you configure _round-robin_ with three droplets, the load balancer will send the first request to the first droplet, second request to the second droplet, third request to the third droplet, fourth request to the first droplet, fifth request to the second droplet, etc, etc. 

1. Create `loadbalancer.tf` and `loadbalancer_variables.tf` in `tutorial-3>app`
  - Your directory should look like this now:

```
├── droplet.tf
├── droplet_variables.tf
├── loadbalancer.tf
├── loadbalancer_variables.tf
├── provider.tf
├── secrets.tf
├── templates
│   └── user_data_nginx.yaml
└── variables.tf
```  
2. Open the `loadbalancer.tf` file, paste in the following, and save it:

```hcl
resource "digitalocean_loadbalancer" "public" {
  name   = "loadbalancer-1"
  region = "nyc3"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_ids = [digitalocean_droplet.web.id]
}
```
_This was pulled directly from the terraform documentations for DigitalOcean's [load balancer](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/loadbalancer)_

3. Now we're gonna use some of the same variables we've used previously. Starting with `name`, lets try to keep naming consistent by changing the value to `"pub-lb-${var.service}-${var.env}"`
  - This will align the droplet name of `web0-burrito-prod` to `pub-lb-burrito-prod`
4. Moving on to the `region` parameter, we already have a `region` variable defined, so we can just use it again here
5. Things get a little different when you get to the `forwarding_rule`. If you created a variable definition with the full unique name, it would be something like `loadbalancer_forwarding_rule_entry_port_http` which is a bit excessive and there's definitely a character limit. I usually shorten these variable names to `lb_fr_entry_port_http`. Create a variable for each of these forwarding rule parameters in `loadbalancer_variables.tf`.

* Your `loadbalancer_variables.tf` file should look similar to this, with different descriptions:

```hcl
variable "lb_fr_entry_port_http" {
    description = "the TCP port which outside users are allowed to connect to on the load balancer"
    default     = 80 
}

variable "lb_fr_entry_protocol_http" {
    description = "the protocol which outside users are allowed to connect to on the load balancer"
    default     = "http"
}

variable "lb_fr_target_port_http" {
    description = "after the initial connection to the load balancer, request will be forwarded to this TCP on a droplet"
    default     = 80
}

variable "lb_fr_target_protocol_http" {
    description = "after the initial connection to the load balancer, request will be forwarded as this protocol on a droplet"
    default     = "http" 
}
```
_Note: Try to create descriptions that are more verbose to help you with understanding the shortened variable names_


6. Replace the forwarding rule parameters with the variables you've created for it:

```hcl
  forwarding_rule {
    entry_port     = var.lb_fr_entry_port_http
    entry_protocol = var.lb_fr_entry_protocol_http

    target_port     = var.lb_fr_target_port_http
    target_protocol = var.lb_fr_target_protocol_http
  }
```

7. Now looking at the `healthcheck` parameters, there's something that bugs me a bit. This is telling the load balancer to send web requests to droplets when the load balancer can connect to the droplet via SSH. With this logic, a droplet is deemed healthy when it can be reached by SSH. This is a problem in the event that the droplet is online, but the web service or application is not responding. Let's fix this by using the previously defined forwarding rule target variables:


```hcl
  healthcheck {
    port     = var.lb_fr_target_port_http
    protocol = var.lb_fr_target_protocol_http
  }
```

8. You will also need to add a new `path` parameter to the `healthcheck` parameters because it's required when doing a `http` health check. Create a `lb_hc_path` variable in the `loadbalancer_variables.tf` file

`loadbalancer.tf`
```hcl
  healthcheck {
    path     = var.lb_hc_path
    port     = var.lb_fr_target_port_http
    protocol = var.lb_fr_target_protocol_http
  }
```

`loadbalancer_variables.tf`
```hcl
variable "lb_hc_path" {
  description = "the path to perform the http healtcheck on"
  default     = "/"
}
```
_Note: the default value is the base path, eg `http://www.taccoform.com`, but it's common to use a dedicated healthcheck path like `http://www.taccoform.com/health`_


9. Create an `output` for the load balancer public IP address so that you can easily retrieve it.

```hcl
output "lb-pub-ip" {
  value = digitalocean_loadbalancer.public.ip
}
```
10. Make sure all of your files are saved, then run `terraform plan`

* Your `terraform plan` should show that it's creating two droplets and a load balancer:

```hcl
Terraform will perform the following actions:

  # digitalocean_droplet.web[0] will be created
  + resource "digitalocean_droplet" "web" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-20-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + ipv6_address_private = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "web0-burrito-prod"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + ssh_keys             = [
          + "28662501",
        ]
      + status               = (known after apply)
      + urn                  = (known after apply)
      + user_data            = "1234567890"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

  # digitalocean_droplet.web[1] will be created
  + resource "digitalocean_droplet" "web" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + id                   = (known after apply)
      + image                = "ubuntu-20-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + ipv6_address_private = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "web1-burrito-prod"
      + price_hourly         = (known after apply)
      + price_monthly        = (known after apply)
      + private_networking   = (known after apply)
      + region               = "sfo2"
      + resize_disk          = true
      + size                 = "s-1vcpu-1gb"
      + ssh_keys             = [
          + "28662501",
        ]
      + status               = (known after apply)
      + urn                  = (known after apply)
      + user_data            = "1234567890"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

  # digitalocean_loadbalancer.public will be created
  + resource "digitalocean_loadbalancer" "public" {
      + algorithm                = "round_robin"
      + droplet_ids              = (known after apply)
      + enable_backend_keepalive = false
      + enable_proxy_protocol    = false
      + id                       = (known after apply)
      + ip                       = (known after apply)
      + name                     = "pub-lb-burrito-prod"
      + redirect_http_to_https   = false
      + region                   = "sfo2"
      + status                   = (known after apply)
      + urn                      = (known after apply)
      + vpc_uuid                 = (known after apply)

      + forwarding_rule {
          + entry_port      = 80
          + entry_protocol  = "http"
          + target_port     = 80
          + target_protocol = "http"
          + tls_passthrough = false
        }

      + healthcheck {
          + check_interval_seconds   = 10
          + healthy_threshold        = 5
          + path                     = "/"
          + port                     = 80
          + protocol                 = "http"
          + response_timeout_seconds = 5
          + unhealthy_threshold      = 3
        }

      + sticky_sessions {
          + cookie_name        = (known after apply)
          + cookie_ttl_seconds = (known after apply)
          + type               = (known after apply)
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + droplet_public_ips = [
      + (known after apply),
      + (known after apply),
    ]
```
10. Run `terraform apply` and confirm to provision the droplets and load balancer

```hcl
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

droplet_public_ips = [
  "5.5.5.5",
  "5.5.5.6",
]
lb-pub-ip = "4.5.6.7"
```

11. Wait a minute for the droplets to finish provisioning, then browse to the load balancer's IP address provided by `lb-pub-ip`. You should see `web0-burrito-prod IS ALIVE!!!` or `web1-burrito-prod IS ALIVE!!!` and if you furiously refresh, you should see the output changing back and forth between the two droplets.


#### Overriding variables

* Now that you've variable-ized all the things, you can do some fun stuff like:

1. Increase number of droplets without changing the `.tf` files: `terraform plan -var 'droplet_count=5'`
2. Remove all the droplets without destroying the load balancer: `terraform plan -var 'droplet_count=0'`
  - _This is great for iterating over changes to the user data provisioning script_
3. Change the environment: `terraform plan -var 'env=stg'`
4. You can also override multiple variables by creating a `.tfvars` 

`custom.tfvars`
```hcl
droplet_count = 1
service       = "tacos"

```
_Now run `terraform plan -var-file="custom.tfvars"` and review how it changes the infrastructure._ 


5. For fun, run `terraform apply -var 'droplet_node_type=carneasada'` 

* After a few minutes, browse to the `lb-pub-ip` and you should see how the page has changed. Refreshing the page multiple times shows how the traffic is being distributed to each droplet.



6. As always, run `terraform destroy` to delete all of the resources you've created in this lesson to stop being charged for them




## In Review

![load_balanced_application_on_droplets](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tts_p3/load_balanced_application_on_droplets.png)

* You've learned how to create variables and the different types of variables you can define
* You learned how to use variables in resource definitions
* You reused variables (eg. env, service, region)
* You created a load balanced application 
* You learned how to override default variable values



## Conclusion 

* Variables can be difficult to name and they eat up a bunch of your time, but it's a worthy investment in the long run. What you have now is reuseable code which can be copied to other terraform workspaces. You are also a few short steps away from creating a terraform module.

Check out the next entry in the [Taccoform Tutorial Series](https://www.taccoform.com/posts/tts_p4/) which will go over Terraform `statefiles` and how to use them.


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
