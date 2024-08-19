output "name" {
  value = var.name
}

output "artifact_s3_location" {
  value = aws_synthetics_canary.this.artifact_s3_location
}

output "eventbridge_rule_arn" {
  value = module.eventbridge.eventbridge_rule_arns["${var.name}"]
}
