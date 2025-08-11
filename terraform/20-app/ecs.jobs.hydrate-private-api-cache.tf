resource "local_sensitive_file" "ecs_job_hydrate_private_api_cache" {
  filename = "ecs-jobs/hydrate-private-api-cache.json"
  content = templatefile("ecs-jobs/hydrate-private-api-cache.tftpl", {
    cluster_arn             = module.ecs.cluster_arn
    security_group_id       = module.ecs_service_worker.security_group_id
    subnet_ids              = module.vpc.private_subnets
    task_arn                = module.ecs_service_worker.task_definition_arn
  })
}
