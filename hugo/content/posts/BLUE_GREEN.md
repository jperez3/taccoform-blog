+++
title =  "Migrating to mysql 8.0 with blue green deployments"
tags = ["blue-green","aws","rds","aurora","mysql","terraform"]
date = "2024-10-07"
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/blue_green/header.jpg)


# Overview


## Lesson


### Prep

#### Parameter Groups

You will need to create all new parameter groups for the cluster and instances because mysql 8 is considered a different "family." If you're managing your database infrastructure via Terraform, you can simply copy the existing resources and change the family attribute and resource name. Something to note is that not all mysql 5.7 parameters are compatible with mysql 8. When creating the new parameter groups, Terraform will yell at you about the the parameters that can't be created. If you run into this, it's best to check with your team to see if those parameters are necessary and do research on each parameter that gives you a problem.



#### Application Changes

You (and your team) may need to make code changes to support any changes in mysql 8. These changes may also need to be backwards compatible to support environments through the upgrade process.



#### Creating a Blue-Green Deployment



#### Stop Incoming Requests

If you are using an ALB with listener rules, you can create a new rule with the highest priority and fixed-response to make sure new connections aren't being made during the upgrade process.



### Switchover to Green Cluster


### Testing


#### Rollback options

##### Option #1: Revert to "old" database

This may be the easiest rollback option with some data loss implications based on how long you wait to revert the database. To rollback, you'd either update the names of the blue and green cluster to make the "old" cluster live again. If you utilize private CNAMEs for the cluster, it would be wise to lower the TTL before the migration and update the record to point to the "old" mysql 5.7 cluster. In this scenario, you would still need to **Temporarily Stop** the "old" cluster and start it again to bring it out of read-only mode.

**MTTR**: 30-60m

##### Option #2: Create an AWS DMS Replication

Prior to upgrading, you could set up the scaffolding for an AWS DMS Replication. AWS Database Migration Service is a tool which allows you to replicate databases from one place to another. Prior to this rollback configuration, familiarity with AWS DMS is highly recommended. You will need experience in network connectivity, replication tasks, and table mapping:
* Network Connectivity: these clusters should reside in the same VPC, so there shouldn't be too much work to get them configured. You will also need to create source/target endpoints and verify connectivity prior to attempting the replication
* Replication Task: You will need to have a job created to monitor changes (Change Data Capture) on the mysql 8.0 cluster and send it to the mysql 5.7 cluster
* Table Mapping: This is just a configuration which tells the replication task what to include (or exclude) in the replication.


When using this rollback method, you should only need to update the CNAME or cluster name to make the mysql 5.7 database live again.


**MTTR**: 1-5m



### IaC clean up


### Gotchas


* Once you switchover to the mysql 8.0 cluster, the mysql 5.7 goes into read-only mode. I'm assuming it's to prevent any random writes to the old cluster. You will need to "Temporarily Stop" the mysql 5.7 cluster and start it up again which can take a while.
* Using the blue-green deployment method means you will be changed double for the duration that both clusters are live.
* Using Terraform to drive the blue-green upgrade is [not supported](https://hashicorp.github.io/terraform-provider-aws/design-decisions/rds-bluegreen-deployments/)
* During the upgrade process, it's important to support both mysql 5.7 and 8.0. If you're using a terraform module to create the database infrastucture, you should leave in both sets of parameter groups and conditionally assign the parameter groups based on database family. This will help in the event of an emergency fix prior to upgrading production.


### Resources



### In Review



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
