+++
title =  "Migrating To Multi-Cloud And Reducing My Personal Cloud Bill By 80%"
tags = ["terraform","cloudflare","digitalocean","multi-cloud"]
date = "2023-8-14"
+++


![Chilaquiles](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/g_p1/header.jpg)


### Moving Taccoform

When I started this blog, I wanted to lower the barrier to entry for learning Terraform. One of the main hurdles of teaching others about Terraform is helping them learn a major cloud providers at the same time. There's a lot of complexity to deal with up front. I decided to start with DigitalOcean instead of AWS for this reason. With this, I had to learn about how things worked in DigitalOcean and did so with this blog. I learned about droplets, load balancers, DNS, and storage (again.) After getting the basics down, I proceeded to glue things together with Terraform in the most reasonable way for a personal blog.

I knew I wanted a cheap droplet with a deployment process that would allow me to bring up a new droplet to replace the existing one when a new post was published. I somewhat accomplished this by setting up droplets to pull the blog repo, build the docker container for [hugo](https://gohugo.io/) and run it. I also set `create_before_destory` in Terraform to give the new droplet time to boot and configure itself, but it was often not fast enough and would result in ~5 minutes of downtime. This is something that's acceptable for a personal blog, but it wouldn't fly in the real world. While not perfect, Terraform and Github Actions served me well for 2+ years. At some point in the last couple of months, this process broke down and I was tired of continuing to give DigitalOcean $25/month for a static website.

After looking around for a bit, I decided to check out Cloudflare Pages. It appears to be free (for now) and the set up was so simple that I didn't even use Terraform :scream:. Full disclosure, for larger and real business cases, I would always recommend codifying this kind of stuff. Cloudflare Pages also has additional benefits. I've been able to fix a broken redirect problem that was plaguing my DigitalOcean setup, it comes with WAF/CDN built in, and most importantly it hooks directly into github. Now I create a new branch, write a post, create a pull request, high five myself and merge. This will kick off a Cloudflare pages deployment and my updated site is live in less than a minute. Not everything is perfect though. I did run into a problem with Cloudflare Pages running a super old version of Hugo which resulted in a broken deployment. This was fixed by adding an environment variable to the deployment to specify a newer version of Hugo.


### Cost

After the Taccoform blog was moved over to Cloudflare Pages, the only remaining DigitalOcean service used was Spaces to host static assets for the site. My DigitalOcean bill went from $25 to $5 and now I'm doing the coveted "multi-cloud" (lul.) I have not received a bill from Cloudflare yet and hoping it stays that way. I'll continue to support DigitalOcean where I can, but I do want to check out Cloudflare's R2 at some point which may move Taccoform completely off of DigitalOcean.


### In Review

If you are starting a new blog, check out Hugo and Cloudflare. Writing blog posts in markdown and hosting via Cloudflare Pages is a low-maintenance setup. Other than reach, I think it's a better option than platforms like Medium. Cloudflare did not pay me for this post and I still have a lot of love for DigitalOcean and their products.


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
