# Handover Documentation

## Key outstanding tech debt items 

This document lists and outlines the major outstanding tech debt items 
which should be considered by the next engineering team taking ownership of the UKHSA data dashboard.

### CI/CD pipeline flakiness

There is currently a flaky bug in the VPC flow logs which rears its head infrequently during the `build-base-env` build.
```
api error 400: Access Denied for LogDestination: uhd-aws-vpc-flow-logs-<>>-eu-west-2. Please check LogDestination permission
with module.vpc.aws_flow_log.this[0]
    on .terraform/modules/vpc/vpc-flow-logs.tf line 36, in resource "aws_flow_log" "this":
    resource "aws_flow_log" "this"
```

### AWS provider version bump

Both the application and account layer infrastructure currently use the terraform AWS provider version `5.98.0`.
At the time of writing (Sep 2025), the latest version `6.12.0` 
contains breaking changes for the version of the ECS terraform module which is currently in use.
As such the dependabot PR for bumping the AWS provider version will break until this has been rectified.

### Ephemeral ~~persistent~~ CI environments

For every CI pipeline run in this repo, we do the following:

- Checkout `main`
- Run `terraform apply`
- Checkout the feature branch
- Run `terraform apply` (so that we apply the difference)
- Build and push the container images to the relevant ECRs
- Restart the application workloads
- Run `terraform destroy` to tear down the infra
- Final cleanups - e.g. force delete secrets from AWS secrets manager

If the cleanup builds fail, then we have a cronjob that runs every night.
This cronjob is defined at `.github/workflows/cleanup-ci-test-environments.yml`.
This job wraps around the CLI command `uhd terraform cleanup` which runs `terraform destroy` on all remaining
ephemeral CI environments.

However, there are a handful of environments which hang indefinitely until timing out when they are being deleted.
This appears to be a flaky dependency violation around Elasticache, its security groups and subnets.
We've spoken to AWS engineers about this. 
And unfortunately they could not give us an answer as to why this was happening.
