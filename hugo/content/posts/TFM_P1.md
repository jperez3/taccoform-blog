+++
title =  "The Who, What, Where, When, and Why of Terraform Modules"
tags = ["terraform", "modules","terraform-modules"]
date = "2021-03-17"
+++


![Photo By Lisa W. on Yelp](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfm_p1/header.jpg)


# Overview

* What are Terraform modules?
* Why should I care about Terraform modules?
* When do I start writing Terraform modules? 
* Who benefits from Terraform modules?
* Where do I store Terraform modules?
* BONUS: How do I structure Terraform modules?


### What are Terraform modules?

When I first started writing Terraform, I got lost in the existing Terraform modules created at my employer. With little context, I started interacting with these modules and I quickly lost sight of which way is up. This did not help me learn Terraform. For beginners, I would recommend building Terraform resources on their own and gain a solid understanding of resource definitions, variables, and Terraform CLI commands.

Terraform modules are templates composed of resource definitions, variables, and data source lookups. You can think of this as a ready to eat taco compared to having a taco's individual ingredients. 



### Why should I care about Terraform modules?

At first, it's hard to see the benefit of creating terraform modules because they take more time to create. Iterating in the beginning might be frustrating because you may not understand how everything is connected. Where things get interesting is when you get the hang of building modules and reach that tipping point where the majority of your services have an associated terraform module. You will also see the benefit of standardized naming for resource definitions, variables, and tagging when you're wiring things together and troubleshooting problems.


### When do I start writing Terraform modules?

Start today with something small that you understand, this will help lower the barrier of entry. It will also establishing how you and your team creates modules. Don't choose something related to an in-flight company project. The last thing you want to do is slow down the delivery of a product.  

Here are a few Terraform module ideas:
* a droplet and dns record
* a droplet and load balancer
* a private s3 bucket


### Who benefits from Terraform modules?

Your team and customers benefit from terraform modules. Your team will be able to spin up new services more quickly after that initial module creation. They won't need to search for a recipe online, rush to the grocery store to buy ingredients, go back home, and make the tacos. With the proper documentation, they will just point to a menu and say "I want 2 tacos." Your customers will order through you and they will be happy their food got to them while it was still hot.


### Where do I store Terraform modules?

Terraform modules belong in a git repository. Whether that's github, gitlab or some other hosted service. You'll want to do this because it will help you track changes, manage versions, and solicit feedback from your peers.


### BONUS: How do I structure Terraform modules?

 I split modules into two camps: 
* vendor-specific
* composed-services

Vendor-specific modules are modules comprised of related resource definitions from the same Terraform provider. This is like going to [Leo's Tacos](https://www.leostacostruck.com/) and ordering an al pastor taco. Leo's would be the provider and the al pastor taco is their (delicious) resource. In terms of a cloud provider, this would be a droplet resource from the DigitalOcean provider.

Composed-service modules are modules comprised of multiple vendor-specific modules. Using Leo's Tacos again, this would be ordering 2 al pastor tacos, 1 burrito, and a Mexican Coke. As you may have noticed, the Mexican Coke isn't something Leo's "made", they just sell it. Composed-services can be made up of vendor specific modules from one or multiple providers. An example of this would be a blog (composed-service) module, which would include a DigitalOcean droplet (vendor-specific) module and Cloudflare [WAF](https://www.cloudflare.com/learning/ddos/glossary/web-application-firewall-waf/) (vendor-specific) module.


### In Review

We've talked about the five double-u's of Terraform modules. Check out the next [post](https://www.taccoform.com/posts/tfm_p2) which will dive into creating your first terraform module.


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
