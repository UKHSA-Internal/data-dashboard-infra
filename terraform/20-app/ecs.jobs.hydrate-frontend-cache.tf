resource "local_sensitive_file" "ecs_job_hydrate_frontend_cache" {
  filename = "ecs-jobs/hydrate-frontend-cache.json"
  content  = templatefile("ecs-jobs/hydrate-frontend-cache.tftpl", {
    frontend_url    = local.urls.front_end
    cdn_auth_key      = jsonencode(aws_secretsmanager_secret_version.cdn_front_end_secure_header_value.secret_string)
    cluster_arn       = module.ecs.cluster_arn
    security_group_id = module.ecs_service_private_api.security_group_id
    subnet_ids        = module.vpc.private_subnets
    task_arn          = module.ecs_service_private_api.task_definition_arn
  })
}
