output "ecs" {
  value = {
    cluster_name = module.ecs.cluster_name
    service_names = {
      cms_admin     = module.ecs_service_cms_admin.name
      feedback_api  = module.ecs_service_feedback_api.name
      private_api   = module.ecs_service_private_api.name
      public_api    = module.ecs_service_public_api.name
      front_end     = module.ecs_service_front_end.name
      feature_flags = module.ecs_service_feature_flags.name
    }
    task_definitions = {
      cms_admin    = module.ecs_service_cms_admin.task_definition_family
      feedback_api = module.ecs_service_feedback_api.task_definition_family
      private_api  = module.ecs_service_private_api.task_definition_family
      public_api   = module.ecs_service_public_api.task_definition_family
      front_end    = module.ecs_service_front_end.task_definition_family
    }
  }
}

output "passwords" {
  value = {
    private_api_key         = local.private_api_key
    cms_admin_user_password = random_password.cms_admin_user_password.result
  }
  sensitive = true
}

locals {
  urls = {
    archive          = "https://${local.dns_names.archive}"
    cms_admin        = "https://${local.dns_names.cms_admin}"
    feedback_api     = "https://${local.dns_names.feedback_api}"
    front_end        = "https://${local.dns_names.front_end}"
    front_end_lb     = "https://${local.dns_names.front_end_lb}"
    legacy_dashboard = "https://${local.dns_names.legacy_dashboard}"
    private_api      = "https://${local.dns_names.private_api}"
    public_api       = "https://${local.dns_names.public_api}"
    public_api_lb    = "https://${local.dns_names.public_api_lb}"
    feature_flags    = "https://${local.dns_names.feature_flags}"
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
    repo_names = {
      ingestion = module.ecr_ingestion_lambda.repo_name
      back_end  = module.ecr_back_end_ecs.repo_name
      front_end = module.ecr_front_end_ecs.repo_name

    }
    repo_urls = {
      ingestion = module.ecr_ingestion_lambda.repo_url
      back_end  = module.ecr_back_end_ecs.repo_url
      front_end = module.ecr_front_end_ecs.repo_url
    }
  }
}

output "lambda" {
  value = {
    ingestion_lambda_arn = module.lambda_ingestion.lambda_function_arn
  }
}

