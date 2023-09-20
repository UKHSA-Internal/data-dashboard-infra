/* 
 * Athena doesn't support sql variables, so you'll need to find and replace the following tokens before running:
 *  - {ENV NAME}   => environment name
 *  - {ACCOUNT ID} => aws account id you are deploying into
 */
CREATE EXTERNAL TABLE IF NOT EXISTS `uhd-{ENV NAME}-front-end-cloud-front-logs` (
    `date` DATE,
    time STRING,
    location STRING,
    bytes BIGINT,
    request_ip STRING,
    method STRING,
    host STRING,
    uri STRING,
    status INT,
    referrer STRING,
    user_agent STRING,
    query_string STRING,
    cookie STRING,
    result_type STRING,
    request_id STRING,
    host_header STRING,
    request_protocol STRING,
    request_bytes BIGINT,
    time_taken FLOAT,
    xforwarded_for STRING,
    ssl_protocol STRING,
    ssl_cipher STRING,
    response_result_type STRING,
    http_version STRING,
    fle_status STRING,
    fle_encrypted_fields INT,
    c_port INT,
    time_to_first_byte FLOAT,
    x_edge_detailed_result_type STRING,
    sc_content_type STRING,
    sc_content_len BIGINT,
    sc_range_start BIGINT,
    sc_range_end BIGINT
) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LOCATION 's3://uhd-aws-cloud-front-access-logs-{ACCOUNT ID}-eu-west-2/uhd-{ENV NAME}-front-end/' TBLPROPERTIES ('skip.header.line.count' = '2')