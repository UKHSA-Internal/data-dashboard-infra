resource "local_sensitive_file" "ecs_job_hydrate_private_api_cache_reserved_namespace" {
  filename = "ecs-jobs/hydrate-private-api-cache-reserved-namespace.json"
  content = templatefile("ecs-jobs/hydrate-private-api-cache-reserved-namespace.tftpl", {
    cluster_arn             = module.ecs.cluster_arn
    security_group_id       = module.ecs_service_worker.security_group_id
    subnet_ids              = module.vpc.private_subnets
    task_arn                = module.ecs_service_worker.task_definition_arn
  })
}
