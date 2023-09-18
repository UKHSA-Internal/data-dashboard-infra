/* 
 * Athena doesn't support sql variables, so you'll need to find and replace the following tokens before running:
 *  - {ENV NAME}   => environment name
 *  - {ACCOUNT ID} => aws account id you are deploying into
 */
CREATE EXTERNAL TABLE IF NOT EXISTS `uhd-{ENV NAME}-front-end-alb-access-logs` (
    type string,
    time string,
    elb string,
    client_ip string,
    client_port int,
    target_ip string,
    target_port int,
    request_processing_time double,
    target_processing_time double,
    response_processing_time double,
    elb_status_code int,
    target_status_code string,
    received_bytes bigint,
    sent_bytes bigint,
    request_verb string,
    request_url string,
    request_proto string,
    user_agent string,
    ssl_cipher string,
    ssl_protocol string,
    target_group_arn string,
    trace_id string,
    domain_name string,
    chosen_cert_arn string,
    matched_rule_priority string,
    request_creation_time string,
    actions_executed string,
    redirect_url string,
    lambda_error_reason string,
    target_port_list string,
    target_status_code_list string,
    classification string,
    classification_reason string
) PARTITIONED BY (day STRING) ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
WITH
    SERDEPROPERTIES (
        'serialization.format' = '1',
        'input.regex' = '([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) (.*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-_]+) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^ ]*)\" \"([^\s]+?)\" \"([^\s]+)\" \"([^ ]*)\" \"([^ ]*)\"'
    ) LOCATION 's3://uhd-aws-elb-access-logs-{ACCOUNT ID}-eu-west-2/front-end-alb/AWSLogs/{ACCOUNT ID}/elasticloadbalancing/eu-west-2/' TBLPROPERTIES (
        "projection.enabled" = "true",
        "projection.day.type" = "date",
        "projection.day.range" = "2022/01/01,NOW",
        "projection.day.format" = "yyyy/MM/dd",
        "projection.day.interval" = "1",
        "projection.day.interval.unit" = "DAYS",
        "storage.location.template" = "s3://uhd-aws-elb-access-logs-{ACCOUNT ID}-eu-west-2/front-end-alb/AWSLogs/{ACCOUNT ID}/elasticloadbalancing/eu-west-2/${day}"
    )