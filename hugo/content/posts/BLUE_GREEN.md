+++
title =  "Upgrading to mysql 8.0 with blue green deployments"
tags = ["blue-green","aws","rds","aurora","mysql","terraform"]
date = "2024-10-25"
+++


![Tacos](https://taccoform-blog.sfo2.digitaloceanspaces.com/static/post/blue_green/header.jpg)


# Overview

It's everyone's favorite task, database upgrade time. I think we're all are inheritely afraid of messing up a production database. Some of us have even been through the fire and lived to tell about it. Either way, upgrades need to happen and this time is no different. AWS has made a very compelling case to upgrade from mysql 5.7 to 8.0 by introducing extended support for Aurora database clusters. All mysql 5.7 aurora database will be automatically enrolled in extended support at the end of October 2024. After enrollment, you can expect to expect to find some new unpleasant charges on your AWS bill.



## Lesson

* Parameter Groups
* Application Changes
* Creating a Blue-Green Deployment
* Stop Incoming Requests
* Switch Over to Green Cluster
* Testing
* Rollback Options
* Reconciling Infrastructure-as-Code
* Gotchas
* Resources



### Parameter Groups

You will need to create all new parameter groups for the cluster and instances because mysql 8 is considered a different "family." If you're managing your database infrastructure via Terraform, you can simply copy the existing parameter group resources and change the `family` attribute and resource name. Something to note is that not all mysql 5.7 parameters are compatible with mysql 8. When creating the new parameter groups, Terraform will yell at you about the the parameters that can't be created. If you run into this, it's best to check with your team to see if those parameters are necessary and do research on each parameter that gives you a problem. You should also keep around the older parameter groups during the transition, this will help in the event that you have to do an emergency fix while you're in the middle of database upgrades.



### Application Changes

You (and your team) may need to make code changes to support any changes in mysql 8. These changes may also need to be backwards compatible to support environments through the upgrade process. You might have situations where there are changes required in columns/tables or you might get lucky and not have any issues. I've experienced both. Some of these problems arise when you attempt to switch over to the new green cluster and this is why it's important to have a non-production database to test on.



### Creating a Blue-Green Deployment

From the AWS Console (or awscli), you will be able to create a blue-green cluster resource. This resource will provision an all new "green" cluster, copy data over to it and continue replication until you decide to switchover. Please bear with me (Captain Obvious) for a moment, you will be paying double while the old and new clusters exist. In my experience, it usually takes an hour or so for the blue-green deployment to become ready to failover. You may have a different experience based on things like the amount of data being replicated and overall database activity. AWS also makes the green cluster's endpoint available in read-only mode so that you can validate the data for yourself. This is strongly recommended.



### Stop Incoming Requests

If you are using an ALB with Listener Rules, you can create a new rule with the highest priority and fixed-response to make sure new connections aren't being made during the upgrade process. You may also have cron tasks interacting with the database cluster, these will need to be skipped and/or temporarily stopped during the scheduled upgrade.



### Switch Over to Green Cluster

Initiating the switching over to the green cluster is easy, you just have to select the blue-green deployment within the RDS console, select _Actions_ in the upper-right corner of the screen and select "Switch over." AWS will start by running pre-checks to make sure the green cluster is ready to take over, stops incoming database connections, syncs over any remaining changes, and promotes the green cluster. AWS promotes the green cluster by renaming it to blue cluster's name and renaming the blue cluster by appending "-old1" to the end.



### Testing


### Rollback Options

#### Option #1: Revert to "old" database

This may be the easiest rollback option with some data loss implications based on how long you wait to revert the database. To rollback, you can update the names of the blue and green cluster to make the "old" cluster live again. If you utilize private DNS CNAMEs for the cluster endpoints, you should lower the TTLs before the migration and update the records to point to the "old" mysql 5.7 cluster. In this scenario, you would need to delete the blue-green deployment and **Temporarily Stop** the "old" cluster and start it again to bring it out of read-only mode.

**MTTR**: 1-5m
**Risk**: High-ish



#### Option #2: Create an AWS DMS Replication

Prior to upgrading, you could set up the scaffolding for an AWS DMS Replication. AWS Database Migration Service is a tool which allows you to replicate databases from one place to another. Prior to this rollback configuration, familiarity with AWS DMS is highly recommended. You will need experience in network connectivity, replication tasks, and table mapping:
* Network Connectivity: these clusters should reside in the same VPC, so there shouldn't be too much work to get them configured. You will also need to create source/target endpoints and verify connectivity prior to attempting the replication
* Replication Task: You will need to have a job created to monitor changes (Change Data Capture) on the mysql 8.0 cluster and send it to the mysql 5.7 cluster
* Table Mapping: This is just a configuration which tells the replication task what to include (or exclude) in the replication.


When using this rollback method, you should only need to update the CNAME or cluster name to make the mysql 5.7 database live again.


**MTTR**: 1-5m
**Risk**: low



### Reconciling Infrastructure-as-Code

If you've worked with AWS and IaC long enough, you're probably aware of the problems and drift that happens when you start changing Terraform managed resources outside of Terraform. I was expecting a lot of statefile manipulation, but I'm happy to report that there's not too much in terms of state surgery. The new cluster takes on the ARN/name of the previous cluster and there have been minor applies to update the statefile.



### Gotchas

* In order to move to mysql 8, both blue and green clusters need to have a minimum of `db.t3.medium` as the database instance size.
* Once you switchover to the mysql 8 cluster, the mysql 5.7 goes into read-only mode. I assume it's to prevent applications from writing to the old cluster. You will need to remove the blue-green deployment and "Temporarily Stop" the mysql 5.7 cluster and start it up again which can take a while.
* Using the blue-green deployment method means you will be charged double for the duration that both clusters are live.
* Using Terraform to drive the blue-green upgrade is [not supported](https://hashicorp.github.io/terraform-provider-aws/design-decisions/rds-bluegreen-deployments/)
* During the upgrade process, it's important to support both mysql 5.7 and 8.0. If you're using a terraform module to create the database infrastucture, you should leave in both sets of parameter groups and conditionally assign the parameter groups based on database family. This will help in the event of an emergency fix prior to upgrading production.
* If you're already leveraging AWS DMS for reporting, you will not be able to "resume" your replication because the underlying infrastructure for the cluster has changed and so have the bin logs required for the replication. You will need to establish a CDC replication and start it prior to allowing clients to connect to the database again.



### Resources

* [Blue/Green Deployments: The New Norm for MySQL Upgrades and Schema Changes](https://www.123cloud.st/p/bluegreen-deployments-the-new-norm)
  * _Note: A great walk-through of blue-green deployments and setting up a lab to test outside of your existing databases_
* [Upgrading Uber's MySQL Fleet to version 8.0](https://www.uber.com/blog/upgrading-ubers-mysql-fleet/)
  * _Note: An interesting read-through on how this kinda stuff is accomplished at scale_



### In Review



---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
