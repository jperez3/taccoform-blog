+++
title =  "Using LocalStack with AWS RDS"
tags = ["terraform","aws","rds","LocalStack"]
date = "2026-01-12"
+++


![Tacos](https://static.taccoform.com/static/post/aws_localstack/header.jpg)


# Background


Several years ago, I took LocalStack for a test drive. The concept alone was wild. LocalStack allows you to provision infrastructure locally and interact with it via a seemingly identical API as AWS. I commended the team behind LocalStack for such an ambitious project and couldn't fault them for the rough edges.

5+ years later, I decided to try them out again after spending way too much time rebuilding RDS clusters. If you've spent any amount of time with RDS, you know that provisioning and destroying resources takes way too long, sometimes over an hour.

## Getting Started

I needed to find out how to install the tool, so I went to the [LocalStack Website](https://www.LocalStack.cloud/) and clicked on _"Get started for free"_ (I should have went to the docs.) After creating an account, I saw the pricing for the first time :grimacing:, $40-80/mo billed annually. More on this later. The gettings started guide was pretty straight-forward and it also suggested installing two of their tools [awscli-local](https://github.com/LocalStack/awscli-local) and [terraform-local](https://github.com/LocalStack/terraform-local). The former is a wrapper around `awscli` to help you interact with LocalStack and the latter is a wrapper around `terraform` to help you interact with LocalStack. After settings this up in a new [github repo](https://github.com/jperez3/taccoform-localstack), I was ready to start provisioning databases.


## Working with RDS

After striking out looking for an [Terraform RDS Example](https://github.com/localstack-samples/localstack-terraform-samples), I just started building an RDS cluster from resources:

`rds.tf`
```hcl
resource "aws_rds_cluster" "default" {
  cluster_identifier        = "aurora-cluster-demo"
  engine                    = "aurora-postgresql"
  availability_zones        = ["us-east-1a", "us-east-1b", "us-east-1c"]
  database_name             = var.db_name
  master_username           = var.db_user
  master_password           = aws_secretsmanager_secret_version.db_creds.secret_string
  skip_final_snapshot       = true
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "aurora-cluster-demo-${count.index}"
  cluster_identifier = aws_rds_cluster.default.id
  instance_class     = "db.t4g.large"
  engine             = aws_rds_cluster.default.engine
  engine_version     = aws_rds_cluster.default.engine_version
}
```

I then borrowed a provider example from the docs:

`provider.tf`
```hcl
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = false
  skip_credentials_validation = true
  skip_metadata_api_check     = true

  endpoints {
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}
```
_This redirects requests to your local-LocalStack_

I also had to create an AWS Secrets Manager secret to connect to the database via the RDS API:

```hcl
resource "aws_secretsmanager_secret" "db_creds" {
  name                    = "db_creds"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id     = aws_secretsmanager_secret.db_creds.id
  secret_string = "plzdontdothis"
}
```
_Being a local test, this is fine, but never do this in a real AWS environment._


Once this was all set up, I was able to provision the resources:

```bash
aws_secretsmanager_secret.db_creds: Creating...
aws_secretsmanager_secret.db_creds: Creation complete after 0s [id=arn:aws:secretsmanager:us-east-1:000000000000:secret:db_creds-OHbYwW]
aws_secretsmanager_secret_version.db_creds: Creating...
aws_secretsmanager_secret_version.db_creds: Creation complete after 0s [id=arn:aws:secretsmanager:us-east-1:000000000000:secret:db_creds-OHbYwW|terraform-20260112014641853000000002]
aws_rds_cluster.default: Creating...
aws_rds_cluster.default: Still creating... [00m10s elapsed]
aws_rds_cluster.default: Still creating... [00m20s elapsed]
aws_rds_cluster.default: Still creating... [00m30s elapsed]
aws_rds_cluster.default: Creation complete after 38s [id=aurora-cluster-demo]
aws_rds_cluster_instance.cluster_instances[1]: Creating...
aws_rds_cluster_instance.cluster_instances[0]: Creating...
aws_rds_cluster_instance.cluster_instances[0]: Still creating... [00m10s elapsed]
aws_rds_cluster_instance.cluster_instances[1]: Still creating... [00m10s elapsed]
aws_rds_cluster_instance.cluster_instances[1]: Still creating... [00m20s elapsed]
aws_rds_cluster_instance.cluster_instances[0]: Still creating... [00m20s elapsed]
aws_rds_cluster_instance.cluster_instances[0]: Still creating... [00m30s elapsed]
aws_rds_cluster_instance.cluster_instances[1]: Still creating... [00m30s elapsed]
aws_rds_cluster_instance.cluster_instances[0]: Creation complete after 30s [id=aurora-cluster-demo-0]
aws_rds_cluster_instance.cluster_instances[1]: Creation complete after 30s [id=aurora-cluster-demo-1]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

 **30 seconds is impressive**

From here, you can use `awslocal` to run a query on the cluster:

```bash
$ uv run awslocal rds-data execute-statement \
    --database taco \
    --resource-arn arn:aws:rds:us-east-1:000000000000:cluster:aurora-cluster-demo \
    --secret-arn arn:aws:secretsmanager:us-east-1:000000000000:secret:db_creds-OHbYwW \
    --include-result-metadata --sql 'SELECT 123'
{
    "columnMetadata": [
        {
            "arrayBaseColumnType": 0,
            "isAutoIncrement": false,
            "isCaseSensitive": false,
            "isCurrency": false,
            "isSigned": true,
            "label": "?column?",
            "name": "?column?",
            "nullable": 1,
            "precision": 10,
            "scale": 0,
            "schemaName": "",
            "tableName": "",
            "type": 4,
            "typeName": "int4"
        }
    ],
    "numberOfRecordsUpdated": 0,
    "records": [
        [
            {
                "longValue": 123
            }
        ]
    ]
}
```

You can also just use `psql` to connect to the database:

```bash
$ psql -d taco -U chef -p 4510 -h localhost -W
Password:
psql (18.1, server 17.7 (Debian 17.7-3.pgdg13+1))
Type "help" for help.

taco=#
```

One thing I noticed is that LocalStack wants you to view resources via their web interface, you can't browse to it locally. When I followed the instructions to go to `https://app.localstack.cloud/inst/default/resources` to view the resources, I was met with an error:

>Could not connect to running LocalStack instance. Make sure LocalStack is running and that its endpoint is accessible from this browser.
Update the endpoint URL in the above configuration if you are running LocalStack on a non-standard port or on a remote host.

This was just the default installation, I'm not doing anything tricky or different to be difficult. I had to resort to using the `awscli-local` tool to get details, eg `uv run awslocal rds describe-db-clusters`.

I appreciated how I didn't have to set up a VPC for the database. It happened so seamlessly that I almost forgot that it was a prereq for creating a database in RDS.


After I was done messing with the database, destroying resources was just as fast provisioning them:

```bash
aws_rds_cluster_instance.cluster_instances[0]: Destroying... [id=aurora-cluster-demo-0]
aws_rds_cluster_instance.cluster_instances[1]: Destroying... [id=aurora-cluster-demo-1]
aws_rds_cluster_instance.cluster_instances[1]: Still destroying... [id=aurora-cluster-demo-1, 00m10s elapsed]
aws_rds_cluster_instance.cluster_instances[0]: Still destroying... [id=aurora-cluster-demo-0, 00m10s elapsed]
aws_rds_cluster_instance.cluster_instances[0]: Still destroying... [id=aurora-cluster-demo-0, 00m20s elapsed]
aws_rds_cluster_instance.cluster_instances[1]: Still destroying... [id=aurora-cluster-demo-1, 00m20s elapsed]
aws_rds_cluster_instance.cluster_instances[1]: Still destroying... [id=aurora-cluster-demo-1, 00m30s elapsed]
aws_rds_cluster_instance.cluster_instances[0]: Still destroying... [id=aurora-cluster-demo-0, 00m30s elapsed]
aws_rds_cluster_instance.cluster_instances[1]: Destruction complete after 30s
aws_rds_cluster_instance.cluster_instances[0]: Destruction complete after 30s
aws_rds_cluster.default: Destroying... [id=aurora-cluster-demo]
aws_rds_cluster.default: Still destroying... [id=aurora-cluster-demo, 00m10s elapsed]
aws_rds_cluster.default: Still destroying... [id=aurora-cluster-demo, 00m20s elapsed]
aws_rds_cluster.default: Still destroying... [id=aurora-cluster-demo, 00m30s elapsed]
aws_rds_cluster.default: Destruction complete after 33s
aws_secretsmanager_secret_version.db_creds: Destroying... [id=arn:aws:secretsmanager:us-east-1:000000000000:secret:db_creds-OHbYwW|terraform-20260112014641853000000002]
aws_secretsmanager_secret_version.db_creds: Destruction complete after 0s
aws_secretsmanager_secret.db_creds: Destroying... [id=arn:aws:secretsmanager:us-east-1:000000000000:secret:db_creds-OHbYwW]
aws_secretsmanager_secret.db_creds: Destruction complete after 0s
```


### Pricing


If you want to provision RDS resources, you will need the `base` subscription. The [LocalStack pricing page](https://www.localstack.cloud/pricing) says it is $39/month and billed annually. This means it's not actually a per month subscription and costs $468/year. If you perform migrations and build data pipelines via AWS Database Migration Service, you will need to bump up to the `ultimate` subscription which is ~~$89/mo~~ $1068/year.


### Who benefits from using LocalStack for RDS?

If you work for a big company and your main focus is to support RDS databases or data pipelines, this is your savior. No need to check in terraform code, log into VPN, run Terraform job against your branch, wait a long time and pray that your changes fixes the problem. The feedback loop on your computer with LocalStack is exponentially faster.

If you work at a company where you're bouncing between AWS services a lot and leaning heavily into open source tooling, you would still benefit from using LocalStack, but you might have trouble getting management on board with the cost (eg 4 engineers * $1068 = $4272/year.)



### Final Thoughts

I still think LocalStack is a bold and ambitious project. It has some rough edges in the software and pricing, but I want to believe they are operating in good faith. On most occasions it's pretty easy and quick to interact with an AWS account, so it makes sense to just validate in a lower environment. The problem remains with RDS provisioning time and maybe AWS will be able fix this in the future.


If you'd like to try it out for yourself, [here's the code](https://github.com/jperez3/taccoform-localstack)

---
_As always, feel free to reach out on twitter via [@taccoform](https://twitter.com/taccoform) for questions and/or feedback on this post_
