# UKHSA Dashboard Infrastructure

This repo contains the infrastructure to bootstrap our AWS accounts and deploy an instance of the UKHSA Dashboard app.

The tooling and scripts in this repo are tested with Linux and Mac. If you're using Windows these may work with WSL2 🤞.

## Prerequisites

Please make sure you have the following software installed:

1. `aws` - `brew install awscli`
2. `jq` - `brew install jq`

## Configure AWS SSO

Sign into AWS and configure your profiles:

```
aws configure sso
```

Follow the prompts and configure the accounts / roles with the following profile names. When prompted for the region, enter `eu-west-2`.

| Account     | Role          | Profile Name      |
| ----------- | ------------- | ----------------- |
| Development | Administrator | `uhd-dev:admin`   |
| Tooling     | Administrator | `uhd-tools:admin` |

### Post config steps

Due to a bug in the AWS Terraform provider ([hashicorp/terraform-provider-aws#28263](https://github.com/hashicorp/terraform-provider-aws/issues/28263#issuecomment-1378369615)), the following manual post config steps are needed:

1. Open your `.aws/config` file
2. Remove the `sso_session` parameter from the profile
3. Add the `sso_start_url` and `sso_region` to the profile

Example:

```
[profile foo]
sso_region = eu-west-2
sso_start_url = https://bar.awsapps.com/start
sso_account_id = 999999999
sso_role_name = Baz
region = eu-west-2
```

## Getting started

Source our CLI tool:

```
source uhd.sh
```

Assume the admin role in our `tools` account:

```
uhd aws login uhd-tools:admin
```

And then test that you can query S3:

```
aws s3 ls
```

## Terraform

We use Terraform to manage the resources we deploy to AWS.

The Terraform code is split into two layers:

1.  For account level resources. We deploy one each of these resources in each AWS account.
2.  For application resources. This is the infrastructure to run an instance of the application. We deploy multiple instances of these resources into each AWS account.

## Initialize

Terraform must be initialized on a new machine. To initialize for all layers:

```
uhd terraform init
```

Or to initialize a specific layer:

```
uhd terraform init <layer>
```

For example:

```
uhd terraform init 10-account
```

## Plan

To run `terraform plan` for the application layer in your dev environment:

```
uhd terraform plan
```

Or to `plan` for a specific layer and environment:

```
uhd terraform plan:layer <layer> <env>
```

For example:

```
uhd terraform plan:layer 20-app foo
```

## Apply

To run `terraform apply` for the application layer in your dev environment:

```
uhd terraform apply
```

To `apply` for all layers:

```
uhd terraform apply:all
```

Or to `apply` for a specific layer and environment:

```
uhd terraform apply:layer <layer> <env>
```

For example:

```
uhd terraform apply:layer 20-app foo
```

## Push containers to your ECR

Until we finalize our strategy for ECR, you'll need to pull the latest container images and push them to your ECR:

First login to ECR:

```
uhd docker ecr:login
```

Then to pull the latest images:

```
uhd docker pull
```

And to push them to your ECR:

```
uhd docker push <account> <env>
```

For example:

```
uhd docker push dev 12345678
```

## Bootstrap your environment

Once your infrastructure is deployed, you'll need to bootstrap your environment. This will set the API key, CMS admin user password, and seed your database with content and metrics.

> **These commands must be run from the `dev` account**

Open a new terminal window and login to AWS:

```
source uhd.sh
uhd aws login uhd-dev:admin
```

Run the bootstrap job:

```
uhd ecs run bootstrap-env
```

Make a note of the task ID. It is the last part of the task ARN. In the example below it is `e3a5dc3fc35546c6980fabe45bc59fe6`

```
arn:aws:ecs:eu-west-2:123456789012:task/uhd-12345678-cluster/e3a5dc3fc35546c6980fabe45bc59fe6
```

You can then tail the logs from the task. It may take a minute or two for the task to start:

```
uhd ecs logs <env> <task id>
```

For example:

```
uhd ecs logs 12345678 d20ee493b97143f293ae6ebb5f7b7c0a
```

## Restart your services

Your environment should now be setup. The final step is to restart your services:

```
uhd ecs restart-services
```

## Related repos

These repos contain the app source code:

- [UKHSA-Internal/winter-pressures-frontend](https://github.com/UKHSA-Internal/winter-pressures-frontend)
- [UKHSA-Internal/winter-pressures-api](https://github.com/UKHSA-Internal/winter-pressures-api)
