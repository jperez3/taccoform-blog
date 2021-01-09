+++
title =  "Top 5 Ways To Troubleshoot Terraform"
tags = ["terraform", "troubleshooting"]
date = "2021-01-05"
+++


![not_tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/top_5_troubleshooting/header.jpg)


# Top 5 Ways to Troubleshoot Terraform

_You're crying on the floor, `terraform apply` errored out again. You tell yourself that you can't go out like this and pull yourself back into your knock off Herman Miller chair._ 

Whether you're a terraform beginner or seasoned veteran, troubleshooting errors becomes a part of the terraform ritual. It's hard to keep track of all of the Terraform troubleshooting tricks, so hopefully these 5 tips will help you and/or jog your memory.

---



### 5. Check on your provider

Make sure your provider version is up to date, newer versions might address the problem you're seeing. If you cannot update your provider for whatever reason, check out the _Issues_ section of your provider's repository. Here is an example of a provider's Issues page: [DigitalOcean Terraform Provider](https://github.com/digitalocean/terraform-provider-digitalocean/issues). Searching the open and closed issues might help your troubleshooting efforts.


##### Additional Resources
Common Provider Documentation:
* [AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
* [DigitalOcean](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
* [GCP](https://registry.terraform.io/providers/hashicorp/google/latest/docs)


### 4. Use Terraform outputs

Terraform outputs give you a way to see things like public IPs after a `terraform apply`, but it's also a good tool for helping you troubleshoot your code. There have been plenty of times where I've tried to pass the wrong variable type or attribute to another resource (or module) and terraform doesn't give you a great error message. You can verify a resource's available attribute's by visiting the documentation for your specific provider. Here is an example of the available attributes for a DigitalOcean [droplet](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet#attributes-reference). If you wanted to pass the IPv4 address of a droplet to another resource, you could verify it by checking the output 

```hcl
output "droplet_public_ip" {
  value = digitalocean_droplet.web.ipv4_address
}
```

One important thing to note with terraform outputs is that new outputs won't display until you've ran a `terraform apply` which may or may not be a problem with the current state of your terraform

##### Additional Resources
* [Terraform Command - output](https://www.terraform.io/docs/commands/output.html)
* [Terraform output values](https://www.terraform.io/docs/configuration/outputs.html)

### 3. Use Terraform console

Terraform console is probably the most under-utilized tool in your toolbelt, but it can provide a safe way to troubleshoot your problem. Maybe you're having in issue with a built-in terraform function. Drop into the console with `terraform console` and mess around:

```hcl
> title("it's taco tuesday")
"It'S Taco Tuesday"
> format("today is %s", "Monday")
"today is Monday"
> upper(format("today is %s", "Monday"))
"TODAY IS MONDAY"
> replace(upper(format("today is %s", "Monday")), "MONDAY", "TUESDAY")
"TODAY IS TUESDAY"
```

Testing in `terraform console` is a million times quicker than iterating over terraform plan/apply

##### Additional Resources

* [Terraform Command: console](https://www.terraform.io/docs/commands/console.html)


### 2. Don't use Terraform

I'm joking, sort of. Sometimes you won't be able to tell if the problem is a terraform issue, something you're doing wrong or something wrong with the cloud provider. Take a step back and read some documentation (unless it's AWS docs, they're terrible.) You might also want to build a _"point and click"_ proof of concept in your cloud provider's admin console. Your cloud provider might not support what you're trying to build and better errors might surface in the admin console.


### 1. Organize Your Terraform

Terraform code gets complex REAL QUICK. The best way to help you understand your code is to organize it.
* Skip using `main.tf`, it's the terraform equivalent of the junk drawer in your house. When everything is in one file it's hard to make sense of what is going on.
* Use multiple `.tf` files with descriptive names like `droplet.tf` and `load_balancer.tf` and put the right resource definitions in those files. 
    - When creating new modules, you can remove components you're not focusing on by changing the extention (eg. `load_balancer.tfx`) which will make the `terraform` command ignore that file. 
* The naming isn't set in stone, you can change them at any time as long as you keep the `.tf` extension. 
* You can organize your resources into multiple files RIGHT NOW. You still want to be careful when copying existing resources into new files, but moving the resources will not trigger terraform changes.
* Use multiple terraform statefiles/workspaces, don't put all of your resources in a single statefile. Having unrelated resources in the same statefile increases the blast radius when things go wrong and can halt all terraform work until the problem is addressed. 


##### Additional Resources

* [HashiCorp Learn - Separate Development and Production Environments](https://learn.hashicorp.com/tutorials/terraform/organize-configuration)




## Conclusion

This isn't an exhaustive list of ways to troubleshoot terraform, but hopefully these 5 tips will help you along the way. 



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_