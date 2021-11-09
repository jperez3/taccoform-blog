+++
title =  "Packer Detour #1: Packer+Amazon Linux 2+AWS Session Manager "
tags = ["packer", "tutorial", "aws", "session-mana"]
date = "2021-11-09"
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/tts_p1/header.jpg)


# Overview

The year is 2021 and you're still building servers, you read that right. It's not always a bad thing though. There are certain scenarios you might consider using an instance over a container or function. Maybe AWS doesn't provide a hosted solution for the technology you want to use, maybe you want to do multi-cloud and the cloud provider's offerings are too different to manage. No matter the reason, you should familiarize yourself with Hashicorp Packer. 

## Lesson

* What is Packer?
* Why Should I Care About Packer?
* Security Hurdles 
* Packer Files And Components
* Packer Commands 
* Packer Builds  


### What is Packer? 

Packer is brought to you by Hashicorp, the very same people who brought you Terraform. The link between these two products might be a little loose, but can become a superpower when combined. Packer also uses Hashicorp's HCL2 (Hashicorp Configuration Language V2) which should feel similar to writing Terraform code. Packer allows you to build configurations on top of existing images. In our case, we're talking about adding additional configuration to Amazon Linux 2 AMIs. Packer builds AMIs by provisioning an instance on your behalf, uses ssh to log into the instance and configure it based on your specifications. When the configuration completes, packer shuts down the instance and turns it into an AMI and then does a bit of clean up. 

### Why Should I Care About Packer? 

Investing in Packer will bring you closer to immutable infrastructure which is a fancy way of saying you'll have the ability to trash an instance and not freak out about it. Rebuilding a broken/missing/deleted instance is fast and easy because you baked most of your configuration into a custom AMI. I say most of your configuration because you should not store sensitive information like secrets in your custom AMI. 


### Security Hurdles

The default behavior for Packer is to provision a keypair (for ssh access), instance, and security group on your behalf during the Packer build process. This all looks great on the surface, but take a closer look at the security group and you'll notice that it opens up the instance to the public Internet which doesn't feel very secure. The Packer build process can take anywhere from 5-30 minutes depending on the amount of custom configuration you put into your build. A more secure way to do this is by using a [bastion](https://www.learningjournal.guru/article/public-cloud-infrastructure/what-is-bastion-host-server/) instance to tunnel through to get to the private instance for configuration. The cost of using this method is additional configuration and a bastion instance to maintain. An even more secure way to accomplish this is by leveraging AWS's Session Manager to connect into the instance for configuration. Session Manager is its own glorious thing and deserves more praise for all that it gives you. People with other cloud provider experience might shrug it off, but you should definitely check it out if you're working in AWS. 



### Packer Files And Components

Packer uses HCL2 just like terraform and if you've written Terraform code, you know the files end in `.tf`, so naturally packer files end in `.pkr`. LOL not the case, but somewhat close... Packer files end with `.pkr.hcl`. I recommend taking some time to think about how you want to organize your Packer files, rather than throwing everything into something like `main.pkr.hcl`. The two major components of Packer are `builds` and `sources`, so that might be a good line in the sand for file organization.

* Source: a code block which tells Packer where to start which is most likely a cloud provider and how to connect to the instance/droplet/vm for additional configuration 

* Build: a code block which tells packer to invoke a defined source block and run additional configuration on that intance/droplet/vm



#### Source Example

`source.pkr.hcl`

```hcl
source "amazon-ebs" "linux" {

  # AWS AMI data source lookup 
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-ebs"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]

  }

  # AWS EC2 parameters
  ami_name      = "taccoform-burrito-${regex_replace(timestamp(), "[- TZ:]", "")}"
  instance_type = "t3.micro"
  region        = "us-east-1"
  subnet_id     = var.subnet_id
  vpc_id        = var.vpc_id



  # provisioning connection parameters
  communicator                 = "ssh"
  ssh_username                 = "ec2-user"
  ssh_interface                = "session_manager"
  iam_instance_profile         = "taccoform-packer"

  tags = {
    Environment     = "prod"
    Name            = "taccoform-burrito-${regex_replace(timestamp(), "[- TZ:]", "")}"
    PackerBuilt     = "true"
    PackerTimestamp = regex_replace(timestamp(), "[- TZ:]", "")
    Service         = "burrito"
  }
} 
```
_Note: It's a good practice to included the `timestamp` in the Packer AMI name to establish a unique naming convention. This will prevent any naming collision between builds and help you diagnose issues when things go wrong._

#### Build Example


`build.pkr.hcl`

```hcl
build {
  sources = ["source.amazon-ebs.linux"]

  provisioner "shell" {
    scripts = [
      "files/init.sh",
    ]
  }

}
```
_The `build` block invokes a `source` or multiple `source` blocks and then runs additional configuration based on the defined `provisioner` sub-blocks_ 


### Packer Commands 


Packer is similar to Terraform in that the commands are searching the current working directory for configuration files and it uses the command plus subcommand format to run. Here are some of the basic commands to get going:

* `packer init` - intitializes packer plugins. This is similar to how Terraform intializes the configured providers 
* `packer validate` - validates packer configuration files. This is similar to Terraform's validate subcommand and checks for syntax/configuration issues.
* `packer build` - kicks off the packer build process. The build command is like running Terraform apply with the `-auto-approve` flag to bypass the user provided input. 

### Packer Builds


Now that we've gone over the basis, it's time to get our hands dirty and start building some AMIs. We'll be using the same configuration used for `awscli` to provision a packer image with [AWS System Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) (yes it's a long and ridiculous name for an otherwise cool tool.) 

#### Pre-Flight

1. Create a new IAM user with "Access Key - Programmatic Access" then press `Next`
2. Select the "Attach existing policies directly", Select "Administrator Access" and then press `Next`
  - **NOTE** This is for demonstration purposes only and an account with a locked down policy should be created for production applications.
3. Press `Next` at the tags screen
4. Press `Create User` button and then store the Access and Secret keys in your password manager
5. Install [awscli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
6. Configure [awscli](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) and set the default region as `us-east-1`
7. Verify that your credentials work: `aws sts get-caller-identity`
8. Clone [jperez3/taccoform-packer](https://github.com/jperez3/taccoform-packer) and browse to the `basic` folder
9. Install [Packer](https://www.packer.io/downloads)
10. Install [Terraform](https://www.terraform.io/downloads.html)
11. Install the [AWS Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)


#### Terraform

You thought there would be no terraform in this post, I did too. It turns out that you need a few things for this to work. You need a VPC, an IAM policy to allow access to session manager on an instance and a role/profile to attach it to said instance. For a closer look at what is being provisioned, check out [packer.tf](https://github.com/jperez3/taccoform-packer/blob/main/basic/packer.tf)

1. Run `terraform init`
2. Run `terraform apply -auto-approve`
3. Set the VPC ID from the terraform output as an environment variable that packer can read: `export PKR_VAR_vpc_id=$(terraform output -raw vpc_id)`
4. Set the Subnet ID from the terraform output as an environment variable that packer can read: `export PKR_VAR_subnet_id=$(terraform output -raw private_subnet_id)`
5. Verify that both variables were set, eg `echo $PKR_VAR_vpc_id`


#### Packer


Now on to the main attraction, you are now read to build your first Amazon AMI with Packer. From the `basic` directory, run the following:

1. Intialize the AWS Packer plugin: `packer init plugins.pkr.hcl`
2. Kick of image creation: `packer build .`

* During the build process the output will show you what it's doing, here is a general overview:
  * Validating input parameters
  * Generating keypair for build
  * Launching an instance
  * Waiting for SSH to respond over AWS Session Manager
  * Running any defined provisioners
  * Stopping instance
  * Creating AMI from configured instance 
  * Deleting instance 

* You might get an error like the one below, but the build will complete successfully and produce an AMI:

```
==> amazon-ebs.linux: Bad exit status: -1
==> amazon-ebs.linux: Cleaning up any extra volumes...
==> amazon-ebs.linux: No volumes to clean up, skipping
==> amazon-ebs.linux: Deleting temporary security group...
==> amazon-ebs.linux: Deleting temporary keypair...
Build 'amazon-ebs.linux' finished after 6 minutes 25 seconds.

==> Wait completed after 6 minutes 25 seconds

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs.linux: AMIs were created:
us-east-1: ami-0e1fa6b889312345
```

3. Now you can see the AMI in the AWS console, or you can check it out via `awscli`: `aws ec2 describe-images --filters "Name=tag:Service,Values=burrito"`

* If you wanted to reference this AMI in terraform, you can use a data source lookup to fetch the AMI ID and pass it to an AWS instance resource:

```hcl
data "aws_caller_identity" "current" {}

data "aws_ami" "burrito" {
  most_recent = true

  filter {
    name   = "Service"
    values = ["burrito"]
  }

  owners = [data.aws_caller_identity.current.account_id] # your account id 
}

resource "aws_instance" "burrito" {
  ami           = data.aws_ami.burrito.id
  instance_type = "t3.micro"

  tags = {
    Name = "web0-burrito-prod"
  }
}
```


4. After you're done testing/building, dont forget to run `terraform destroy` in the workspace

### In Review

Packer is a great tool for pre-baking images so they be provisioned more quickly and easily replaced. Using Packer with AWS Session Manager feels like a welcome cheat code and I hope this tutorial helps you on your cloud journey. 


---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
