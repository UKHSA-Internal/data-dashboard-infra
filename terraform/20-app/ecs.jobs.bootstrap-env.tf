resource "local_sensitive_file" "ecs_job_bootstrap_env" {
  filename = "ecs-jobs/bootstrap-env.json"
  content  = templatefile("ecs-jobs/bootstrap-env.tftpl", {
    cms_admin_user_password = random_password.cms_admin_user_password.result
    aurora_writer_endpoint  = local.aurora.app.primary.address
    frontend_url            = local.dns_names.front_end
    cluster_arn             = module.ecs.cluster_arn
    security_group_id       = module.ecs_service_utility_worker.security_group_id
    subnet_ids              = module.vpc.private_subnets
    task_arn                = module.ecs_service_utility_worker.task_definition_arn
  })
}
