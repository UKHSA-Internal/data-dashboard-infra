output "name" {
  value = var.name
}

output "artifact_s3_location" {
  value = aws_synthetics_canary.this[0].artifact_s3_location
}

output "eventbridge_rule_arn" {
  value = module.eventbridge_canary.eventbridge_rule_arns["${var.name}"]
}

output "canary_arn" {
  value = aws_synthetics_canary.this[0].arn
}