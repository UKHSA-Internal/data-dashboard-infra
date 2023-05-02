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

Assume the admin role in our `dev` account:

```
uhd aws login uhd-dev:admin
```

And then test that you can query S3:

```
aws s3 ls
```

## Related repos

These repos contain the app source code:

- [UKHSA-Internal/winter-pressures-frontend](https://github.com/UKHSA-Internal/winter-pressures-frontend)
- [UKHSA-Internal/winter-pressures-api](https://github.com/UKHSA-Internal/winter-pressures-api)
