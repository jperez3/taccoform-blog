+++
title =  "Multiple Provider Orchestration"
tags = ["terraform", "tutorial", "digitalocean", "aws", "cloudflare", "providers"]
date = "2022-11-16"
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tts_p1/header.jpg)


# Overview

When working in our respective cloud service providers, we tend to get tunnel vision and think only in terms of compute, networking, and storage for our task at hand. This may be feasible for all in scenarios, but the reality is that we most likely leverage multiple SaaS offerings to get the best experience possible. Using DigitalOcean for infrastructure, Cloudflare for CDN/WAF, GitHub for code repositories, and Datadog for logging/metrics. This is only an example of a possible setup, your stack may vary based on your company’s needs, past employees, and your current team’s experience. Pulling all this together into a reproducible stack can be difficult and have different configuration requirements. Some SaaS platforms may be driven by "click-ops", some might have an API, and the most cloud-focused companies will see the value in building a Terraform provider.

Moving from one provider to multiple providers is a super power. If this were cooking, it would be like going from store bought ceviche tostadas to creating your own with all the flavors you love and none of the flavors you don’t. Yes it’s more work in the beginning, but by the end you’ll have a recipe (or module) to impress family, friends and colleagues.

## Lesson

* Organization
* Demo


### Organization

In order to leverage multiple providers, you will need to create provider blocks for each SaaS you want to leverage. In some scenarios, you might want to use the same provider twice. A common situation where two of the same providers is when provisioning across multiple cloud service provider accounts. In this case, you will need to configure an alias for each of those providers. The alias is important for telling modules and resources which credentials to use or where to provision the resources.

You can tell a module or resource to use a specific provider by passing the alias to the reserved module/resource parameter `provider`. If you’re using a SaaS platform that doesn’t allow you to have separate accounts for different environments, you will never need to use an alias.

On the topic of SaaS providers, there might also be scenarios where you only need to provision one resource to support all of your environments. A good example of this is the GitHub repository for a service. You won’t be creating a repo for your staging environment. You’ll more than likely use the same codebase for all of your environments. I would recommend grouping these “one and done” resources together in a global module. This will also help enforce consistent naming and tagging across your company’s services. These modules will also require a 1:1 relationship with your terraform workspace. I know “workspace” is a loaded term and to be clear. This is a directory with your provider, statefile storage and called module information. Putting multiple services in the same workspace creates unintentional dependencies between services and increases the blast radius when things go wrong.

When it comes to SaaS providers which allow multiple accounts or require separate resources for supporting different environments, you will need to create a dedicated “base” module. A common scenario for this would be to create the network connectivity between a CDN service and your cloud service provider load balancer (or origin.) Deploying this module will again be a 1:1 mapping with a Terraform workspace. The organization of these different environment deployments depends on your company. Some companies have monorepos and deploy them nested inside specific environment root directories. Other companies will deploy these workspaces from with the application code repositories. There’s pros and cons to each of these approaches, but that’s outside the scope of this current topic.


### Demo

To show how you can leverage multiple cloud providers, I will be creating a small web service. The web service will include a DigitalOcean droplet, a Cloudflare DNS record to take advantage of Cloudflare's CDN/WAF, and a CNAME record in AWS's Route53. You might ask, why the two DNS records? This scenario is good when you don't want Cloudflare to be your authoratative DNS for your domain name. You can select if and when individual services use Cloudflare's Web Application Firewall.



#### Creating The Module And Workspace

1. Starting in a terraform module, we'll create a `versions.tf` file to store the required provider information:

`versions.tf`
```hcl
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
        cloudflare = {
          source  = "cloudflare/cloudflare"
          version = "~> 3.0"
        }
        digitalocean = {
          source = "digitalocean/digitalocean"
          version = "~> 2.0"
        }
    }

    required_version = "~> 1.0"
}
```
_Note: If you don't create this file in the module, when you run the terraform workspace, any providers not maintained by Hashicorp will error because it's looking for `hashicorp/3rdpartyname` instead of `3rdpartyname/3rdpartyname`_

2. We'll need to create a variables file to require specific variable inputs when module is called and optional override variables:

`variables.tf`
```hcl
variable "env" {
    description = "unique/short environment name"
}

variable "domain" {
    description = "domain name to use for provisioning"
    default     = "tacoform.com"
}
```

3. Now I'll create some data source lookups to pull information on existing resources:


`data_source.tf`
```hcl
data "aws_route53_zone" "selected" {
  name = "${var.domain}."
}

data "cloudflare_zone" "selected" {
  name = var.domain
}

data "digitalocean_ssh_key" "root" {
  name = "taccoform-tutorial"
}
```
_Note: Notice how it's pulling information from all three cloud providers_

4. And finally, I can create the two DNS records and the droplet:

`infra.tf`
```hcl
resource "aws_route53_record" "cloudflare_cname" {
  name    = "salsa.${var.domain}"
  records = ["salsa.${var.domain}.cdn.cloudflare.net"]
  ttl     = 300
  type    = "CNAME"
  zone_id = data.aws_route53_zone.selected.zone_id
}

resource "cloudflare_record" "origin" {
  name    = "salsa"
  value   = digitalocean_droplet.web.ipv4_address
  type    = "A"
  ttl     = 3600
  zone_id = data.cloudflare_zone.selected.id
}

resource "digitalocean_droplet" "web" {
  image     = "ubuntu-20-04-x64"
  name      = "web1-salsa-${var.env}"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [data.digitalocean_ssh_key.root.id]
  user_data = templatefile("${path.module}/templates/user_data_nginx.yaml", { hostname = "web1-salsa-${var.env}" })
}
```
_Note: Compare the two DNS record resources. They are similar, but different. Differences like these make it harder to migrate from one cloud provider to the next. They all have different naming and parameter requirements which means IaC alone can't be a fully cloud agnostic solution._


5. We can now move on to the workspace, eg. `taccoform-multi-provider-demo/workspaces/prod/base`

`provider.tf`
```hcl
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
        cloudflare = {
          source  = "cloudflare/cloudflare"
          version = "~> 3.0"
        }
        digitalocean = {
          source = "digitalocean/digitalocean"
          version = "~> 2.0"
        }
    }

    required_version = "~> 1.0"
}

variable "cloudflare_api_token" {}
variable "do_token" {}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "digitalocean" {
  token = var.do_token
}
```
_Note: The additional provider blocks allow us to pass tokens to the providers through environment variables like `export TF_VAR_do_token=1234567890`_


6. And finally, I'll create a terraform file to call the module to create the resources:

`multi_provider_base.tf`
```hcl
module "multi_provider_base" {
  source = "../../../modules/base"

  env = "prod"
}
```

#### Provisioning Workspace

1. Now that the module and workspace have been flushed out, we can initialize terraform:


```bash
❯ terraform init
Initializing modules...
- multi_provider_base in ../../../modules/base

Initializing the backend...

Initializing provider plugins...
- Finding cloudflare/cloudflare versions matching "~> 3.0"...
- Finding digitalocean/digitalocean versions matching "~> 2.0"...
- Finding hashicorp/aws versions matching "~> 4.0"...
- Installing cloudflare/cloudflare v3.28.0...
- Installed cloudflare/cloudflare v3.28.0 (signed by a HashiCorp partner, key ID DE413CEC881C3283)
- Installing digitalocean/digitalocean v2.24.0...
- Installed digitalocean/digitalocean v2.24.0 (signed by a HashiCorp partner, key ID F82037E524B9C0E8)
- Installing hashicorp/aws v4.39.0...
- Installed hashicorp/aws v4.39.0 (signed by HashiCorp)

```

2. After we initialize, we can apply our changes:
```bash
❯ terraform apply -auto-approve

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.multi_provider_base.aws_route53_record.cloudflare_cname will be created
  + resource "aws_route53_record" "cloudflare_cname" {
      + allow_overwrite = (known after apply)
      + fqdn            = (known after apply)
      + id              = (known after apply)
      + name            = "salsa.tacoform.com"
      + records         = [
          + "salsa.tacoform.com.cdn.cloudflare.net",
        ]
      + ttl             = 300
      + type            = "CNAME"
      + zone_id         = "REDACTED"
    }

  # module.multi_provider_base.cloudflare_record.origin will be created
  + resource "cloudflare_record" "origin" {
      + allow_overwrite = false
      + created_on      = (known after apply)
      + hostname        = (known after apply)
      + id              = (known after apply)
      + metadata        = (known after apply)
      + modified_on     = (known after apply)
      + name            = "salsa"
      + proxiable       = (known after apply)
      + ttl             = 3600
      + type            = "A"
      + value           = (known after apply)
      + zone_id         = "REDACTED"
    }

  # module.multi_provider_base.digitalocean_droplet.web will be created
  + resource "digitalocean_droplet" "web" {
      + backups              = false
      + created_at           = (known after apply)
      + disk                 = (known after apply)
      + graceful_shutdown    = false
      + id                   = (known after apply)
      + image                = "ubuntu-20-04-x64"
      + ipv4_address         = (known after apply)
      + ipv4_address_private = (known after apply)
      + ipv6                 = false
      + ipv6_address         = (known after apply)
      + locked               = (known after apply)
      + memory               = (known after apply)
      + monitoring           = false
      + name                 = "web1-salsa-prod"
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
      + user_data            = "b1199511f42a7281db5616cb1005ac8090f54007"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.
module.multi_provider_base.digitalocean_droplet.web: Creating...
module.multi_provider_base.aws_route53_record.cloudflare_cname: Creating...
module.multi_provider_base.digitalocean_droplet.web: Still creating... [10s elapsed]
module.multi_provider_base.aws_route53_record.cloudflare_cname: Still creating... [10s elapsed]
module.multi_provider_base.digitalocean_droplet.web: Still creating... [20s elapsed]
module.multi_provider_base.aws_route53_record.cloudflare_cname: Still creating... [20s elapsed]
module.multi_provider_base.aws_route53_record.cloudflare_cname: Creation complete after 27s [id=REDACTED_salsa.tacoform.com_CNAME]
module.multi_provider_base.digitalocean_droplet.web: Still creating... [30s elapsed]
module.multi_provider_base.digitalocean_droplet.web: Still creating... [40s elapsed]
module.multi_provider_base.digitalocean_droplet.web: Still creating... [50s elapsed]
module.multi_provider_base.digitalocean_droplet.web: Creation complete after 52s [id=REDACTED]
module.multi_provider_base.cloudflare_record.origin: Creating...
module.multi_provider_base.cloudflare_record.origin: Creation complete after 2s [id=REDACTED]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```


3. After a few minutes, we can check on the web service and the DNS:

```bash
❯ curl http://salsa.tacoform.com
<html><body><h1>web1-salsa-prod IS ALIVE!!!</h1></body></html>
❯ curl -I http://salsa.tacoform.com
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Thu, 17 Nov 2022 03:55:02 GMT
Content-Type: text/html
Content-Length: 63
Last-Modified: Thu, 17 Nov 2022 03:11:30 GMT
Connection: keep-alive
ETag: "6375a662-3f"
Accept-Ranges: bytes
❯ dig salsa.tacoform.com +noall +answer

; <<>> DiG 9.10.6 <<>> salsa.tacoform.com +noall +answer
;; global options: +cmd
salsa.tacoform.com.     300     IN      CNAME   salsa.tacoform.com.cdn.cloudflare.net.
salsa.tacoform.com.cdn.cloudflare.net. 3600 IN A 138.68.5.70
```
_Note: `curl` and `dig` are great tools to have in your arsenal for debugging/validating your provisioned infrastructure_

* For the full code, check out the [taccoform-multi-provider-demo](https://github.com/jperez3/taccoform-multi-provider-demo) repo.



### In Review

You probably already leverage multiple cloud providers, but use different provisioning methods for those services. Using multiple Terraform providers at the same time allows you to orchestrate services across clouds and SaaS providers. This kind of orchestration is extremely powerful and gives you a consistent (and predictable) platform to build upon. If you'd like to see another example of this, you can check out my [service bootstrapping](https://www.taccoform.com/posts/tfc_p1/) post or Hashicorp's [Host a Static Website with S3 and Cloudflare](https://developer.hashicorp.com/terraform/tutorials/applications/cloudflare-static-website) tutorial.


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
