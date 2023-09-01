resource "local_sensitive_file" "ecs_job_bootstrap_env" {
  filename = "ecs-jobs/bootstrap-env.json"
  content = templatefile("ecs-jobs/bootstrap-env.tftpl", {
    cms_admin_user_password = random_password.cms_admin_user_password.result
    private_api_key         = local.private_api_key
    cluster_arn             = module.ecs.cluster_arn
    security_group_id       = module.ecs_service_private_api.security_group_id
    subnet_ids              = module.vpc.private_subnets
    task_arn                = module.ecs_service_private_api.task_definition_arn
  })
}
