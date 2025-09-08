resource "local_sensitive_file" "ecs_job_crawl_front_end" {
  filename = "ecs-jobs/crawl-front-end.json"
  content  = templatefile("ecs-jobs/crawl-front-end.tftpl", {
    frontend_url      = local.urls.front_end
    cdn_auth_key      = jsonencode(aws_secretsmanager_secret_version.cdn_front_end_secure_header_value.secret_string)
    cluster_arn       = module.ecs.cluster_arn
    security_group_id = module.ecs_service_worker.security_group_id
    subnet_ids        = module.vpc.private_subnets
    task_arn          = module.ecs_service_worker.task_definition_arn
  })
}
