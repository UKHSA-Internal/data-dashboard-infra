# Handover Documentation

## Current caching system

There is currently a multi-tiered caching system in place for the platform.
We have the following components:

- AWS Cloudfront CDN which sits in front of the frontend application
- 2 x Elasticache serverless clusters which sit in front of the private API
- AWS Cloudfront CDN which sits in front of the public API

The 2 Elasticache serverless clusters which are in front of the private API, 
allow us to segregate ephemeral short-lived data from long-lived, sometimes more computationally expensive data.

Originally we wanted to simply have the 1 cache for the private API and keep the long-lived data seperate from 
the ephemeral data by way of namespaces. However, there were a few issues with this approach:

- To delete data from the cache, we would have to select the keys we want to delete (i.e. all the ephemeral items)
and issue a delete command one-by-one.
- The problem with this is, for serverless cache clusters which have scaled out. 
When you are connected to the write node of the cluster, you are most likely only connected to a specific shard.
Since the cluster has had to scale out by way of sharding, the data is now distributed across multiple shards.
i.e. it is not replicated but sharded across. 
This means that CRUD operations like SCAN-ITER & DELETE are only respected to the selected shard.
- One way around this would have been to make the application cluster-aware, 
so the application would have to iterate through all the shards in the cluster to ensure the outbound CRUD operations
were headed to the right place. This was deemed as introducing unnecessary complexity at the application level.
- AWS Elasticache also only allows for 1 database number per cache, so we could not switch between multiple
Redis databases in the same cache.
- The simplest solution to this was to set up a logically and physically seperate cache, so that the ephemeral
and long-lived / computationally expensive data could be housed seperately. 
This 2nd cache is referenced as the `reserved` cache throughout both backend and infra codebases. 
This also gave us the added benefit of the caches being able to scale independently 
in accordance with their own traffic profiles.

## Proposed caching approach

The above is however in a state of flux, at the time of writing (Sep 2025), 
the engineering team were testing a new approach whereby:

- AWS Cloudfront CDN sits in front of the frontend application to serve static files and long-lived pages
- 1 Elasticache serverless cluster which sits in front of the frontend
- AWS Cloudfront CDN which sits in front of the public API as previously

The idea being that we would lean on Next.js's inbuilt Incremental Static Regeneration (ISR) caching system.
In this scenario we'd need a central Redis cache which all the frontend container workloads could pull data from.
This cache would act as the single source of truth.
And we could purge and revalidate on an endpoint / page by page basis.

This would also give us the benefit of the blue-green approach to refreshing content 
that Next.js gives us out of the box.
In other words:
- We have version 1 of data currently in the Redis cache
- The frontend containers serve users version 1
- Content authors have published a new page, or we have ingested new data
- Operators trigger a cache flush
- The frontend works in the background to update the data in the cache
- In the meantime, the frontend continues to serve users with version 1
- When version 2 is ready, the frontend will then switch to serving users with version 2

There will of course be a period in which that data is considered stale and outdated.
But this means that the Next.js application will always work to serve users from the cache.

With this we can also adjust how often we want to revalidate based on certain routes.
For example, for weather health alerts we know we have an end to end SLA of 10 minutes.
From the moment the Extreme Events team issue an alert, to the moment that alert is published to the dashboard.
As such, for weather health alert routes we can ask the frontend to revalidate on a more frequent basis 
when compared to other datasets. 

## Outstanding development

The key item to address is how the Next.js-biased caching approach works with the long-lived data (like maps).
This will require an investigation whereby you deploy the application 
with the `caching_v2_enabled` local variable set to `true`.

Set up the childhood-vaccinations topic page in that development environment with the full COVER datasets 
& CMS page content (or at least the global filter + filter linked map CMS components).

With that in place, run the cache flush workflow via Github actions **or** call the following:

```
source uhd.sh
uhd cache flush-v2
```

This will trigger a lambda function to hit the frontend revalidate route. 
This route currently naively revalidates everything in its cache.
Clearly moving forward that revalidate endpoint will need to be readjusted
so that you can revalidate data in the cache depending on what it is you want to refresh.
In most scenarios you will only want to revalidate ephemeral data 
like the charts, tables, downloads that are seen across most of the topic pages.
You wouldn't want to or be interested in revalidating the maps data for COVER which changes only once year.

## CLI 

Note that in the `uhd cache` CLI module, only the current v1 cache flush workflows
are shown in the help text. This is by design, since v2 is still in a testing phase.
