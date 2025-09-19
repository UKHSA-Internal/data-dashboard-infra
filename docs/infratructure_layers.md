# Handover Documentation

## Deploying infrastructure

Hand-rolled / click-ops via the AWS console should be avoided.
The system is deployed in to AWS via terraform only.

The CLI module which can be accessed via:
```
source uhd.sh
```

And then the following command to list all the available CLI modules.
```
uhd
```
See the README at the root of this repo for more information on this.

## Infrastructure layers

The infrastructure is split into 2 main layers:

- `10-acccount` - Account level components which are deployed into the account.
This includes things foundational services which are shared across the account
like IAM assumable roles and DNS configurations.
This is only done a per-account basis.
- `20-app` - Environment level components which are deployed in to the account on a per-environment basis. 
We can and often do have multiple environments in the same account which are logically seperate.

For the most part you will likely be interested in deploying changes to the `20-app` layer.
This is where you will find all the application workloads, databases, caches, CDNs.

Summarising this, we have something that looks like the following:
```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS Organization                                   │
└───────────────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────┐      ┌───────────────────────────────────────┐
│            Dev AWS Account            │      │           Prod AWS Account            │
│                                       │      │                                       │
│  ┌─────────────────────────────────┐  │      │  ┌─────────────────────────────────┐  │
│  │        10-account Layer         │  │      │  │        10-account Layer         │  │
│  │     (Once per AWS Account)      │  │      │  │     (Once per AWS Account)      │  │
│  │                                 │  │      │  │                                 │  │
│  │  • IAM Roles & Policies         │  │      │  │  • IAM Roles & Policies         │  │
│  │  • DNS (Route 53) Configuration │  │      │  │  • DNS (Route 53) Configuration │  │
│  │  • SSL Certificates (ACM)       │  │      │  │  • SSL Certificates (ACM)       │  │
│  │  • Cost & Usage Reports         │  │      │  │  • Cost & Usage Reports         │  │
│  │  • Shield Advanced Roles        │  │      │  │  • Shield Advanced Roles        │  │
│  │  • S3 Buckets for logs          │  │      │  │  • S3 Buckets for logs          │  │
│  └─────────────────────────────────┘  │      │  └─────────────────────────────────┘  │
│                                       │      │                                       │
│  ┌─────────────────────────────────┐  │      │  ┌─────────────────────────────────┐  │
│  │        20-app Layer             │  │      │  │        20-app Layer             │  │
│  │   (Multiple per AWS Account)    │  │      │  │     (Single Environment)        │  │
│  │                                 │  │      │  │                                 │  │
│  │ ┌─────────────────────────────┐ │  │      │  │  ┌─────────────────────────────┐│  │
│  │ │        Dev Environment      │ │  │      │  │  │       Prod Environment      ││  │
│  │ │                             │ │  │      │  │  │                             ││  │
│  │ │  • ECS Services & Tasks     │ │  │      │  │  │  • ECS Services & Tasks     ││  │
│  │ │  • Aurora DB Instances      │ │  │      │  │  │  • Aurora DB Instances      ││  │
│  │ │  • ElastiCache Clusters     │ │  │      │  │  │  • ElastiCache Clusters     ││  │
│  │ │  • Application Load Balancer│ │  │      │  │  │  • Application Load Balancer││  │
│  │ │  • CloudFront Distributions │ │  │      │  │  │  • CloudFront Distributions ││  │
│  │ │  • Lambda Functions         │ │  │      │  │  │  • Lambda Functions         ││  │
│  │ │  • API Gateway              │ │  │      │  │  │  • API Gateway              ││  │
│  │ │  • S3 Buckets               │ │  │      │  │  │  • S3 Buckets               ││  │
│  │ │  • Cognito User Pools       │ │  │      │  │  │  • Cognito User Pools       ││  │
│  │ │  • CloudWatch Monitoring    │ │  │      │  │  │  • CloudWatch Monitoring    ││  │
│  │ │  • Kinesis Data Streams     │ │  │      │  │  │  • Kinesis Data Streams     ││  │
│  │ └─────────────────────────────┘ │  │      │  │  │                             ││  │
│  │                                 │  │      │  │  │  • Production-scale         ││  │
│  │ ┌─────────────────────────────┐ │  │      │  │  │    configuration            ││  │
│  │ │  Personal Dev Environments  │ │  │      │  │  │  • Enhanced monitoring      ││  │
│  │ │                             │ │  │      │  │  │    & alerting               ││  │
│  │ │  • Developer-specific       │ │  │      │  │  │  • High availability setup  ││  │
│  │ │    environments             │ │  │      │  │  │  • Backup & disaster        ││  │
│  │ │  • Feature branch testing   │ │  │      │  │  │    recovery                 ││  │
│  │ │    instances                │ │  │      │  │  │  • Stricter security        ││  │
│  │ └─────────────────────────────┘ │  │      │  │  │    controls                 ││  │
│  │                                 │  │      │  │  └─────────────────────────────┘│  │
│  │                                 │  │      │  |                                 |  │
│  └─────────────────────────────────┘  │      │  └─────────────────────────────────┘  │
└───────────────────────────────────────┘      └───────────────────────────────────────┘
```