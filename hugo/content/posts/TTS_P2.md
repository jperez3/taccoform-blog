<!-- +++
title =  "Taccoform Tutorial Series - Part II"
tags = ["terraform", "tutorial", "digitalocean", "terraform13"]
date = "2020-10-26"
+++ -->


# Overview



* DRY 
* `count`
* splat
* `for_each`


### Don't Repeat Yourself (DRY)

Let's add another nearly identical droplet/server to the mix. With the information you have right now, you might think to copy/paste the resource and change the names like below: 

`droplet.tf`
```hcl

resource "digitalocean_droplet" "web1" {
  image     = "ubuntu-20-04-x64"
  name      = "web1-burrito-prod"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [data.digitalocean_ssh_key.root.id]
  user_data = templatefile("templates/user_data_nginx.yaml", { hostname = "web1-burrito-prod" })
}

resource "digitalocean_droplet" "web2" {
  image     = "ubuntu-20-04-x64"
  name      = "web2-burrito-prod"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [data.digitalocean_ssh_key.root.id]
  user_data = templatefile("templates/user_data_nginx.yaml", { hostname = "web2-burrito-prod" })
}

```

Keeping things DRY and simple can be difficult at times. Lucky for us, terraform resource definitions have a built in parameter called `count`. Count helps simplify the scenario above with the help of `count.index`.


## Count

The `count` parameter tells terraform to loop over the resource definition based on a provided numeric value. We also use the `count.index` to help the resource with unique naming. If add the `count` parameter and leave the name as `web1-burrito-prod`, terraform will try to create two resources with the same name (`web1-burrito-prod`.) Terraform might error out on the creation of the second droplet because a droplet with that name already exists. Even if terraform was to let you create two instances with the same name, it is not ideal to support two droplets with the same name.

1. Go to the `tutorial-2` folder in the `taccoform-tutorial` repo that you forked in the first tutorial. If you don't see the folder, you may need to update your fork.

2. Edit the `droplet.tf` file's `web` resource definition to include `count = 2`, replace the 1 in `web1` on the `name` and `user_data` parameters:

`droplet.tf`
```hcl
resource "digitalocean_droplet" "web" {
  count = 2

  image     = "ubuntu-20-04-x64"
  name      = "web${count.index}-burrito-prod"
  region    = "sfo2"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [data.digitalocean_ssh_key.root.id]
  user_data = templatefile("templates/user_data_nginx.yaml", { hostname = "web${count.index}-burrito-prod" })
}
```

3. Edit the `output` below the `web` resource definition to include `.*` afer `web` in the value. Also add an `s` to the end of the output name `droplet_public_ip`:

```hcl
output "droplet_public_ips" {
  value = digitalocean_droplet.web.*.ipv4_address
}
```

* The `*` or "splat" is used in conjunction with the `count` parameter in the `web` resource definition. The splat tells the output to expect a list of values. In this case you are retreiving a list of IP addresses, but you can retrieve a list of any availabe [droplet attribute](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet#attributes-reference). For example, you can retrieve the droplet names:

```hcl
output "droplet_names" {
  value = digitalocean_droplet.web.*.name
}
```
_Note: you don't have to add the `droplet_names` output to the `droplet.tf` file, but it also won't hurt anything if you do._


4. Save the `droplet.tf` file.


5. Running a `terraform plan` will show you what will be provisioned:

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
      + user_data            = "331465f904afe38c2787224a5c3958cb0b83e184"
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
      + user_data            = "f61ed69ba1092537492203cb4472cf66a13eb763"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

* Notice how an index is appended to the end of the resource, this is how terraform helps you keep track of unique resources. 
 -  eg. `digitalocean_droplet.web[0] will be created`

* The count index starts at `0` and maps directly to your naming at `web0`. You can do something like `"web${count.index+1}-burrito-prod"` to start the droplet naming at `web1`, but then the index `0` would map to `web1`. My personal preference is to align index and droplet name. 

6. Run a `terraform apply` and approve changes when prompted:

```hcl
data.digitalocean_ssh_key.root: Refreshing state...
digitalocean_droplet.web[1]: Creating...
digitalocean_droplet.web[0]: Creating...
digitalocean_droplet.web[0]: Still creating... [10s elapsed]
digitalocean_droplet.web[1]: Still creating... [10s elapsed]
digitalocean_droplet.web[1]: Still creating... [20s elapsed]
digitalocean_droplet.web[0]: Still creating... [20s elapsed]
digitalocean_droplet.web[0]: Still creating... [30s elapsed]
digitalocean_droplet.web[1]: Still creating... [30s elapsed]
digitalocean_droplet.web[0]: Creation complete after 34s [id=111111110]
digitalocean_droplet.web[1]: Still creating... [40s elapsed]
digitalocean_droplet.web[1]: Creation complete after 45s [id=111111111]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

droplet_public_ips = [
  "169.99.0.1",
  "169.99.0.2",
]
```

* The `droplet_public_ips` output shows you the public IPs of your two droplets, but doesn't tell you which IP corresponds to which droplet. In this situation, you can assume the first IP maps to `web0` and the second maps to `web1`. This works for a few droplets, but can become confusing when supporting many droplets. 

### Managing droplets with count 

1. Since these are near identical droplets serving the same traffic, you can increase or decrease the number of instances depending on how many users are going to your website
2. Lets bump the `count` parameter to 3, save the `droplet.tf` file and run `terraform apply`:

```hcl
data.digitalocean_ssh_key.root: Refreshing state... [id=123456789]
digitalocean_droplet.web[0]: Refreshing state... [id=111111110]
digitalocean_droplet.web[1]: Refreshing state... [id=111111111]
digitalocean_droplet.web[2]: Creating...
digitalocean_droplet.web[2]: Still creating... [10s elapsed]
digitalocean_droplet.web[2]: Still creating... [20s elapsed]
digitalocean_droplet.web[2]: Still creating... [30s elapsed]
digitalocean_droplet.web[2]: Creation complete after 33s [id=111111112]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

droplet_public_ips = [
  "169.99.0.1",
  "169.99.0.2",
  "169.99.0.3",
]
```
_As you can see, the third IP address which maps to `web2` has been added and your public IPs can vary greatly._

* In the scenario where something bad happens to `web1` (eg stops serving web traffic), you can lower the `count` parameter to `1`, but this would also destroy the healthy `web2` which is not ideal if one droplet cannot support the traffic to your website. A better choice is to use `terraform taint`. The `taint` subcommand tells terraform to mark a chosen resource as needing to be rebuilt. A resource is uniquely identified in terraform plan/apply output and/or by using `terraform show` which will show you all of the resources which have been provisioned. The naming pattern follows the naming provided by the resource definition:

```
resource "digitalocean_droplet" "web" { ...
                     |            |
    count =  3 -----------------------  # count parameter's droplet list index
                     |            |  |
                     |            |  |
                     V            V  V
            digitalocean_droplet.web[1]
```                   

* To `taint` the `web1` resource, run `terraform taint digitalocean_droplet.web[1]`:

```hcl
$ terraform taint digitalocean_droplet.web[1]
Resource instance digitalocean_droplet.web[1] has been marked as tainted.
```
* Run `terraform plan` to see if terraform will execute the changes that you expect. You should see something similar to the output below:

```hcl
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

data.digitalocean_ssh_key.root: Refreshing state... [id=123456789]
digitalocean_droplet.web[1]: Refreshing state... [id=111111111]
digitalocean_droplet.web[0]: Refreshing state... [id=111111110]
digitalocean_droplet.web[2]: Refreshing state... [id=111111112]

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # digitalocean_droplet.web[1] is tainted, so must be replaced
-/+ resource "digitalocean_droplet" "web" {
        backups              = false
        ...
        ...
        ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  ~ droplet_public_ips = [
        "169.99.0.1",
      - "169.99.0.2",
      + (known after apply),
        "169.99.0.3",
    ]
```
_You can see `web1` has been tainted and `web1`'s public IP will be removed from `droplet_public_ips` output_

* Now to rebuild `web1`, run `terraform apply` and confirm the changes when prompted:

```hcl
data.digitalocean_ssh_key.root: Refreshing state... [id=123456789]
digitalocean_droplet.web[2]: Refreshing state... [id=111111112]
digitalocean_droplet.web[1]: Refreshing state... [id=111111111]
digitalocean_droplet.web[0]: Refreshing state... [id=111111110]
digitalocean_droplet.web[1]: Destroying... [id=111111111]
digitalocean_droplet.web[1]: Still destroying... [id=111111111, 10s elapsed]
digitalocean_droplet.web[1]: Still destroying... [id=111111111, 20s elapsed]
digitalocean_droplet.web[1]: Destruction complete after 22s
digitalocean_droplet.web[1]: Creating...
digitalocean_droplet.web[1]: Still creating... [10s elapsed]
digitalocean_droplet.web[1]: Still creating... [20s elapsed]
digitalocean_droplet.web[1]: Still creating... [30s elapsed]
digitalocean_droplet.web[1]: Creation complete after 34s [id=111111116]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

droplet_public_ips = [
  "169.99.0.1",
  "169.99.1.65",
  "169.99.0.3",
]
```
_Notice how `web1`'s rebuild causes the unique `id` to change and it gives the new `web1` a different public IP address in the `droplet_public_ips` output_

#### Pros
* Adheres to DRY (Don't Repeat Yourself)
* Simple to implement
* Droplets follow strict number incrementing naming convention
* Great for creating identical resource (eg. web servers)

#### Cons
* Terraform can sometimes get into a non-ideal state when adding/removing resources due to list iteration
* Can become tricky with more complex configurations
* Terraform plan/apply output is not as clear because it uses the droplet index rather than the name


## For Each

* Count has been around for a while in terraform, but due to the inability to handle more complex inputs, the `for_each` parameter has been introduced to the terraform resource definition. 

```hcl
  # digitalocean_droplet.web["web0"] will be created
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
      + user_data            = "9af6308fba3c408e311eea495a9d288fae5e84b6"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

  # digitalocean_droplet.web["web1"] will be created
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
      + user_data            = "331465f904afe38c2787224a5c3958cb0b83e184"
      + vcpus                = (known after apply)
      + volume_ids           = (known after apply)
      + vpc_uuid             = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy
```

2. Run a `terraform apply` and approve changes when prompted:

```hcl
data.digitalocean_ssh_key.root: Refreshing state... [id=28662501]
digitalocean_droplet.web["web1"]: Creating...
digitalocean_droplet.web["web0"]: Creating...
digitalocean_droplet.web["web1"]: Still creating... [10s elapsed]
digitalocean_droplet.web["web0"]: Still creating... [10s elapsed]
digitalocean_droplet.web["web0"]: Still creating... [20s elapsed]
digitalocean_droplet.web["web1"]: Still creating... [20s elapsed]
digitalocean_droplet.web["web1"]: Still creating... [30s elapsed]
digitalocean_droplet.web["web0"]: Still creating... [30s elapsed]
digitalocean_droplet.web["web0"]: Creation complete after 33s [id=111111111]
digitalocean_droplet.web["web1"]: Still creating... [40s elapsed]
digitalocean_droplet.web["web1"]: Creation complete after 44s [id=111111112]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

droplet_public_ips = {
  "web0" = "169.99.1.1"
  "web1" = "169.99.1.2"
}
```
* 

#### Pros
* Adheres to DRY (Don't Repeat Yourself)
* Allows for more complex configurations
* Doesn't get tripped up by adding/removing resources
* Loose naming convention

#### Cons
* Syntax can get messy
* Harder to follow what's going on
* Outputs are way more complicated than `count`