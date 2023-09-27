resource "local_sensitive_file" "ecs_job_hydrate_public_api_cache" {
  filename = "ecs-jobs/hydrate-public-api-cache.json"
  content  = templatefile("ecs-jobs/hydrate-public-api-cache.tftpl", {
    public_api_url    = local.urls.public_api
    api_key           = jsonencode(aws_secretsmanager_secret_version.cdn_public_api_secure_header_value.secret_string)
    cluster_arn       = module.ecs.cluster_arn
    security_group_id = module.ecs_service_public_api.security_group_id
    subnet_ids        = module.vpc.private_subnets
    task_arn          = module.ecs_service_public_api.task_definition_arn
  })
}
