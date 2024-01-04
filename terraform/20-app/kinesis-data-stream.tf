resource "aws_kinesis_stream" "kinesis_data_stream_ingestion" {
  name = "${local.prefix}-ingestion"
  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}