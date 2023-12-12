output "ecs" {
  value = {
    cluster_name  = module.ecs.cluster_name
    service_names = {
      cms_admin    = module.ecs_service_cms_admin.name
      feedback_api = module.ecs_service_feedback_api.name
      private_api  = module.ecs_service_private_api.name
      public_api   = module.ecs_service_public_api.name
      front_end    = module.ecs_service_front_end.name
    }
  }
}

output "passwords" {
  value = {
    rds_db_password         = random_password.rds_db_password.result
    private_api_key         = local.private_api_key
    cms_admin_user_password = random_password.cms_admin_user_password.result
  }
  sensitive = true
}

locals {
  urls = {
    cms_admin     = "https://${local.dns_names.cms_admin}"
    front_end     = "https://${local.dns_names.front_end}"
    front_end_lb  = "https://${local.dns_names.front_end_lb}"
    feedback_api  = "https://${local.dns_names.feedback_api}"
    private_api   = "https://${local.dns_names.private_api}"
    public_api    = "https://${local.dns_names.public_api}"
    public_api_lb = "https://${local.dns_names.public_api_lb}"
  }
}

output "urls" {
  value = local.urls
}

output "environment" {
  value = local.environment
}

output "cloud_front" {
  value = {
    front_end  = module.cloudfront_front_end.cloudfront_distribution_id
    public_api = module.cloudfront_public_api.cloudfront_distribution_id
  }
}

output "s3" {
  value = {
    ingest_bucket_id = module.s3_ingest.s3_bucket_id
  }
}

output "ecr" {
  value = {
    ingestion_image_uri = "${module.ecr_ingestion.repository_url}:latest"
  }
}

output "lambda" {
  value = {
    ingestion_lambda_arn = module.lambda_ingestion.lambda_function_arn
  }
}
