output "name" {
  value = var.name
}

output "artifact_s3_location" {
  value = try(aws_synthetics_canary.this[0].artifact_s3_location, null)
}

output "eventbridge_rule_arn" {
  value = try(module.eventbridge_canary.eventbridge_rule_arns["${var.name}"], null)
}

output "canary_arn" {
  value = try(aws_synthetics_canary.this[0].arn, null)
}