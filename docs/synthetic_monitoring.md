# Handover Documentation

## Synthetic monitoring

Previously UKHSA were providing synthetic monitoring via Splunk.
Splunk was decommissioned by UKHSA and as such teams were told to handroll their own solution.

For this, we built a module which uses AWS [Synthentic Canaries](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries.html)
to provide synthetic monitoring.

This module hits the `/sitemap.xml` of the frontend, parses all the URLs and then sends a request to each URL.
If the URL returns anything above a 400 status code, then it is considered a failure.
The synthetic canary will take a screenshot of the page and upload it to a designated s3 bucket.
If just 1 URL fails, then the overall run is considered to be a failure.

For failed runs, the system will capture the failed event 
and the notification lambda will send a message to the given Slack channel with the URLs 
and screenshots of the failed page(s).

## Outstanding work

The problem was when we deployed it, we got a bunch of false positives.
We found a memory leak with the `fetch` library in the frontend application.
Which meant that periodically the frontend container workloads would have a kill signal sent to them and restarted.
Resulting in 504 type errors.

The branch for the synthetic monitoring can be found at `task/raise-alarm-for-failed-canary-run/CDD-2109`.
This branch contains a module which wraps around the `aws_synthetics_canary` resource as well as the requisite
s3 bucket for reports, `eventbridge` for consuming failed run events and a lambda function which takes the failed run
and posts a message to a given Slack channel.

Moving forward, you will need to:

1. Fix the memory leak in the frontend, this may be as simple as bumping to the latest version of `React` and `Next.js`
2. When deploying the branch at `task/raise-alarm-for-failed-canary-run/CDD-2109`, 
make sure you provide the channel ID, the webhook URL and the token to the secret in `AWS Secrets Manager`.

## Failed run notifications

The branch `task/raise-alarm-for-failed-canary-run/CDD-2109` gives you notifications to a given Slack channel 
when a canary run fails.
The next step, will likely be to hook this up to a designated Teams channel so that the DPD team have visibility too.
