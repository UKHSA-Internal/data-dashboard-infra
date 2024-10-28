output "image_uri" {
  value = data.aws_ecr_image.this.image_uri
}

output "repo_name" {
  value = module.ecr.repository_name
}

output "repo_url" {
  value = module.ecr.repository_url
}

output "repo_arn" {
  value = module.ecr.repository_arn
}
