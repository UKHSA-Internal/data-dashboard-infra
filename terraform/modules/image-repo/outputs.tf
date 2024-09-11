output "image_uri" {
  value = data.aws_ecr_image.this.image_uri
}

output "repository_arn" {
  value = module.ecr.repository_arn
}
