resource "aws_kinesis_stream" "kinesis_data_stream_ingestion" {
  name        = "${local.prefix}-ingestion"
  shard_count = 1
}