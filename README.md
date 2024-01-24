# UKHSA Data Dashboard Infrastructure

This repo contains the infrastructure to bootstrap our AWS accounts and deploy an instance of the [UKHSA Data Dashboard](https://ukhsa-dashboard.data.gov.uk) app.

The tooling and scripts in this repo are tested with Linux and Mac. If you're using Windows these may work with WSL2 🤞.

## Prerequisites

There are a few steps needed before you can get started:

1. [Setup an SSH key for GitHub](#setup-an-ssh-key-for-github)
2. [Clone this repo](#clone-this-repo)
3. [Install tools](#install-tools)
4. [Configure AWS SSO](#configure-aws-sso)
5. [Login to the GitHub CLI](#login-to-the-github-cli)
6. [Enable multi-platform Docker builds](#enable-multi-platform-docker-builds)

### Setup an SSH key for GitHub

Please follow the instructions here to [setup an SSH key for GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

### Clone this repo

Open a terminal and run the following commands:

```
git clone git@github.com:UKHSA-Internal/winter-pressures-infra.git
cd winter-pressures-infra
```

### Install tools

We use homebrew to manage our software dependencies. If you don't already have it installed:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then run the following commands to install the software dependencies:

```
brew install awscli
brew install --cask docker
brew install gh
brew install jq
brew install python@3.11
brew install tfenv
```

### Configure AWS SSO

You need to sign into AWS and configure your profiles. You can either do this via the AWS CLI or by editing your config files directly. For UKHSA engineers we recommend editing your config files directly.

#### Using the AWS CLI

Sign into AWS and configure your profiles:

```
aws configure sso
```

Follow the prompts and configure the accounts / roles with the following profile names. When prompted for the region, enter `eu-west-2`.

| Account     | Role      | Profile Name |
| ----------- | --------- | ------------ |
| Development | Developer | `uhd-dev`    |
| Tooling     | Developer | `uhd-tools`  |

#### Post config steps

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

You will also need to add the `assumed-role` profiles the CLI is expecting for both the `dev` and `tools` accounts:

```
[profile foo/assumed-role]
role_arn = arn:aws:iam::foo:role/Developer
source_profile = foo
region = eu-west-2
```

#### Updating the config files directly

The `~/.aws/config` should be updated with the profile names we use. Please follow the [instructions in Confluence](https://digitaltools.phe.org.uk/confluence/display/DPD/Configuring+the+AWS+CLI).

### Login to the GitHub CLI

We use the GitHub CLI to check out pull request branches. To enable this feature you must login to the GitHub CLI:

```
gh auth login
```

### Enable multi-platform Docker builds

We use `docker buildx` to enable us to produce `amd64` images on Apple Silicon. You'll need to enable it if you haven't already:

```
docker buildx create --use
```

## Getting started

Source our CLI tool:

```
source uhd.sh
```

Assume the Developer role in our `tools` and `dev` accounts:

```
uhd aws login
```

And then test that you can query `whoami`

```
uhd aws whoami
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
uhd aws login uhd-dev
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

## Update your dev environment

The update command can be used to run all the previous steps together to simplify updating your environment. This command requires you to be logged in to both the `tools` and `dev` accounts at the same time. This can be done with the following command:

```
uhd aws login
```

Now that you are logged in to both accounts, you can run the update command:

```
uhd update
```

The update command will perform the following tasks:

1. Switch to the tools account
2. Run `terraform init`
3. Run `terraform apply`
4. Run `Docker ECR login`
5. Run `Docker pull` to grab the latest images
6. Run `Docker push` to deploy the latest images to your environment
7. Switch to the dev account
8. Restart ecs services
9. Switch back to tools account

## Flushing caches

We cache very aggressively in the app to maximize performance. The trade off is that at the moment we must flush the caches if we make changes to CMS content or metric data. We have three caches:

1. A Redis cache which sits between the private API and the database
2. A CloudFront cache which sits in front of the public API load balancer
3. A CloudFront cache which sits in front of the front end load balancer

Depending on what has changed, there are a couple of options:

### Flushing caches for CMS content changes

Both the Redis and front end CloudFront caches must be flushed.

First sign into AWS and switch to the `dev` account:

```
uhd aws login
uhd aws use uhd-dev
```

Then flush the caches:

```
uhd cache flush-redis
uhd cache flush-front-end
uhd cache fill-front-end
```

### Flushing caches for metric data changes

All caches must be flushed for metric data changes:

```
uhd cache flush-redis
uhd cache flush-front-end
uhd cache flush-public-api
uhd cache fill-front-end
uhd cache fill-public-api
```

## Flush all caches

Flushing the caches one by one, and waiting for each one to finish before starting the next one is tedious. To flush them all in one command:

```
uhd cache flush
```

## Testing a feature branch in your dev environment

There are a few steps to test feature branch in your dev environment:

1. [Clone all repos](#clone-all-repos)
2. [Pull the latest code](#pull-the-latest-code)
3. [Deploy the latest infra](#deploy-the-latest-infra)
4. [Cut a custom image and push it (for API and front end changes)](<#cut-a-custom-image-and-push-it(for-api-and-front-end-changes)>)
5. [Apply infra changes (for infra changes)](<#apply-infra-changes(for-infra-changes)>)
6. [Test it](#test-it)

### Clone all repos

Firstly, clone all the repos if you don't have them already. Our tooling expects the other repos to be cloned as siblings of this repo.

```
uhd gh clone
```

### Pull the latest code

If you have been working on other tickets, it's recommended to switch all branches back to `main` and pull the latest code:

```
uhd gh main
```

If for some reason you don't want to do that, at least pull the latest infra:

```
git checkout main && git pull
```

### Deploy the latest infra

This will pull the latest prod images, and update your env to use the latest infra:

```
uhd aws login
uhd update
```

### Cut a custom image and push it (for API and front end changes)

> Only use this step if you're testing API or front end changes.

Now we can checkout the branch for pull request. The pattern is:

```
uhd gh co [repo] [pull request number | url | branch]
```

For example:

```
uhd gh co api 123
```

Next, build and push a custom image:

```
uhd docker build [repo]
```

For example:

```
uhd docker build api
```

And finally restart the ECS services:

```
uhd aws use uhd-dev
uhd ecs restart-services
```
Flush the cache to reflect Front-end changes
```
uhd cache flush
```
### Apply infra changes (for infra changes)

> Only use this step if you're testing infra changes

First, checkout the branch for the pull request. For example:

```
uhd gh co infra 123
```

If you would like to preview the infra changes that Terraform will make:

```
uhd terraform plan
```

Then apply the changes:

```
uhd terraform apply
```

### Test it

You can now commence testing the pull request in your dev environment.

## Related repos

These repos contain the app source code:

- [UKHSA-Internal/winter-pressures-frontend](https://github.com/UKHSA-Internal/winter-pressures-frontend)
- [UKHSA-Internal/winter-pressures-api](https://github.com/UKHSA-Internal/winter-pressures-api)
