output "sns_topic_arn" {
  value = module.sns_topic_alarm.topic_arn
}

output "name" {
  value = var.name
}

output "artifact_s3_location" {
  value = aws_synthetics_canary.this.artifact_s3_location
}