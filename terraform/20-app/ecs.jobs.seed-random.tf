resource "local_sensitive_file" "ecs_job_seed_random" {
  filename = "ecs-jobs/seed-random.json"
  content = templatefile("ecs-jobs/seed-random.tftpl", {
    aurora_writer_endpoint = local.aurora.app.primary.address
    frontend_url           = local.dns_names.front_end
    cluster_arn            = module.ecs.cluster_arn
    security_group_id      = module.ecs_service_utility_worker.security_group_id
    subnet_ids             = module.vpc.private_subnets
    task_arn               = module.ecs_service_utility_worker.task_definition_arn
  })
}
