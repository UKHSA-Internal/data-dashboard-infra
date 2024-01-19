# splunk-aws-cloudwatch-streaming-metrics-processor

The processor helps ingest AWS Cloudwatch Metrics streams data in JSON format in to Splunk
via kinesis firehose delivery streams by properly transforming data to Splunk specific sourcetype formats.

NOTE: If source format is set to OTEL (v0.7) the function does not perform any Splunk specific sourcetype transformations.
It simply converts the protobuf data into JSON and sends it to Splunk HEC endpoint.

## Environment Variables

ENV var **SPLUNK_CLOUDWATCH_SOURCETYPE** can be set to either `aws:cloudwatch` if events are being sent to a Splunk events
index or `aws:cloudwatch:metric` if events are being sent to a Splunk metric index.

ENV var **METRICS_OUTPUT_FORMAT** can be set to either `json` or `otel` based on the output format set in the stream.

## Source

https://github.com/splunk/splunk-aws-cloudwatch-streaming-metrics-processor
