# Handover Documentation

## Previous cost optimisations analysis

This document outlines the potential cost optimisations which could be achieved.
The last time a thorough cost optimisations analysis was completed would have been in May 2024.
So take the following with a pinch of salt.
Nonetheless, you can find that analysis report [here](https://ukhsa.atlassian.net/wiki/spaces/DPD/pages/168073847/AWS+Cost+Optimisation).

## What we already have in place

### ARM64-based images

We have already switched to using Graviton ARM64-based images across all of our application workloads

### Overnight scheduling of ECS workloads

All of our non-production ECS workloads scale down at 8pm and back up at 8am, Monday to Friday.
This means that they remain scaled down over the weekend.
It should be noted that this also applies to the non-public prod environment since that is not currently in use.

### Overnight scheduling of Aurora DB clusters

All of our non-production database clusters scale down at 8.10pm and back up at 7.30am, Monday to Friday.
This means they also remain scaled down over the weekend.

The reason they are staggered is so that the database cluster for a given environment is always in a ready state
by the time the ECS workloads come online.
It should be noted that this also applies to the non-public prod environment since that is not currently in use.

The schedule for this can be found at `terraform/20-app/eventbridge.scheduled-scaling.tf`.

### Cleanup of ephemeral CI environments

Individual ephemeral CI environments are torn down at the end of their corresponding CI pipeline run.
In the event that the cleanup build fails, then there is also a cronjob which runs at midnight every night.
This cronjob will try to tear down any leftover CI environments that it can find.

### Sizing of ECS tasks

The ECS workloads are sized to differentiate between production-grade environments and lower-grade environments.
Where there is a number of replicas for each workload 
for production-grade environments for redundancy and availability.

## Potential cost optimisations

### Spinning down caches overnight

Out of all the application infrastructure components, `Aurora DB`, application load balancers and `Elasticache`
are the biggest costs. All 3 of which are integral to the system.

Spinning `Elasticache` could be explored. However, those caches are ephemeral by nature especially when compared
to the databases and container workloads, in that one cannot easily stop an `Elasticache` cluster and spin it back up
with no break in service.

To stop `Elasticache`, there would be complete data loss and the cache would have to be filled again.
For personal development environments this may be deemed acceptable, but likely not for the well known environments.

One way around this could be to take a snapshot of `Elasticache` at the point of closing it down.
And then restore it from that snapshot in the morning.

### ALBs

Application load balancers cost considerably more than our other services.
It may be possible for non-production environments to tear them down overnight 
and spin them back up again in the morning.
However, this would need considerable testing to ensure that the DNS records are assigned correctly in the morning.
We would also need to make sure that enough time is allowed for the ALBs, then the db, then containers to spin up
before the working day starts so as to minimize any disruption to the people using these environments.

### Decrease number of frontend & private API ECS tasks

The number of frontend and private API ECS tasks was increased from 3 -> 6 in Aug 2025.
This was done in relation to the COVER topic page which is different from the other pages as it is quite request heavy.
The COVER topic page includes user-driven dynamically generated charts and as such, 
we expect more requests going from the frontend to the private API.

The problem is that the frontend has an unresolved memory leak tied to the `fetch` library, which means it cannot
clean up memory allocation which builds up in conjunction with the number of outbound requests it makes.

As a short-term fix the base number of container workloads was increased from 3 to 6.
This represents an area of potential cost savings. 
Once the frontend memory leak is fixed it should be possible to reduce the number of frontend and private API 
ECS tasks back down to the baseline of 3 replicas.

### Monitoring of personal development environments

We make use of personal development environments in the dev account. 
We often spin up new environments when testing pull requests.

At the time of writing (November 2025), there is no targeted monitoring on this.
So it is feasible for an engineer to create an environment to test a specific PR but forget to tear it down afterwards.

It could be worth adding monitoring to the personal development environments.
Perhaps a report that gets published to slack regularly to say which environments are currently deployed 
and how long it has been since they were last deployed to.

This might at least bring about more awareness of the personal dev / PR testing environments.
Enforcing a hard deletion of these environments after a set period of time could also be useful 
but might also feel a little draconian.
