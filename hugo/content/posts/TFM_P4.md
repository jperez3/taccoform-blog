+++
title =  "Terraform Module Documentation"
tags = ["terraform", "tutorial", "modules", "digitalocean"]
date = "2021-05-19"
+++


![Specials](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tfm_p4/header.jpg)


# Overview

Now on to everyone's favorite topic... Documentation. Some people think documenation is a waste of time and that it's going to be out of date as soon as the ink dries. I understand that frustration, documentation is **not** easy. It takes a lot of effort to create the initial documentation, gather feedback, and update the documentation when changes happen. It can feel like an uphill battle. The alternative is no documenation and everyone steps on the same rake. Today we'll go over why it's important to document your Terraform modules and how to do it. 

## Lesson

* Why document terraform modules
* How to document terraform modules



### Why Document Terraform Modules

Documenting your terraform modules is the best way to get buy-in from your team. Without documentation, your teammates would need to sift through your code to figure out what it's doing and how to use it. This would be like going to a restaurant that doesn't have a menu. Sure you can guess that a Mexican restaurant might have tacos and burritos, but it's not a good use of your time. You'd much rather see a menu to pick out something that you think looks good. The same applies to Terraform modules. You want to make the documentation informative and to the point. You will also benefit from the documentation when you revisit the module later on and need a refresher. Future you will thank you.


### How To Document Terraform Modules

1. Create a `README.md` file in your terraform module directory. You'll place most of your documentation in this file with links to external resouces.
2. Using a module README template can help save time with the documentation process
    * I've been using a module README template that I've developed by seeing other documentation and thinking about what I would like to get out of the README.
    * A template that I use can be found [here](https://raw.githubusercontent.com/jperez3/taccoform-modules/main/docs/README_template.md)
    * The template is written in markdown, more information on markdown can be found [here](https://guides.github.com/features/mastering-markdown/)
3. You can copy the `README_template.md` into your `README.md` file 
4. Start editing by updating the `Module Name` heading to the module that you're documenting
5. Fill out the bullet points under the `General` heading

| Component             | Description                                                                   |
| :-------------------- | :---------------------------------------------------------------------------- |
| Description           | A description of what the Terraform module creates                            |
| Created By            | Who created the module so that consumers know who to go to for support        |
| Module Dependencies   | Dependencies created prior to using this module in other terraform workspaces |
| Provider Dependencies | The terraform providers which will need to be configured to use this module   |
| Terraform Version     | The required terraform version for this module                                |

6. Under the `Usage` heading update the basic example's module name, source and add the minimum required variables that need to be set
    * The module name has to be unique within the terraform workspace, ie you can't have two modules with the same name in one terraform worksapce
    * Update the source path to your terraform module and update the tag to the naming convention you've established. Also remember that you will need to update the tag here every time you update the module. 
    * Add/set all of the module's required variables 
7. Under the _alternate example_ do what you did in step six, but also add/change the optional variables that might be of interest to those who might have different requirements than the defaults. Examples of this would be increasing the virtual machine size, storage, count. 
8. Under the `Inputs` heading, fill out the available variables for the user of this module to change. Be sure to include what the default setting is, the variable type and any constraints.
9. Under the `Output` heading, list the outputs provided by this module. 
    * _Note: put a good amount of thought into the output names because they might be hard to change later if other modules depend on those outputs. Changing output names later on can be a pain to diagnose if you weren't the one who changed them._
10. Under the `Lessons Learned` heading, put things you've learned while developing this terraform module. This will help others understand your design considerations and help them not fall into the same traps that you've already stumbled into. Here are a few examples of things you can add:
    * How you figured out the creation ordering and what's required for your sevice
    * Terraform creation/deletion problems
    * Known bugs with the existing terraform provider version
    * Cloud provider problems
11. Under `References`, you can put links to any documentation, articles, and support tickets. This will help give more context about the creation of the terraform module. 

### In Review

Alright, now that you've created some documentation for your module, you can confidently hand off the module to someone else on your team. Also keep in mind that this is what I've found to be effective. You may find that additional context is required for your business. Go ahead and add that information. Or maybe there's something in the README template that doesn't make sense to you, go ahead and rip that out. The important part is that you and your team have come to an agreement on what makes sense and is useful. 


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
