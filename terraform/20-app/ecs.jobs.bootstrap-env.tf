resource "local_sensitive_file" "ecs_job_bootstrap_env" {
  filename = "ecs-jobs/bootstrap-env.json"
  content = templatefile("ecs-jobs/bootstrap-env.tftpl", {
    admin_password    = random_password.api_admin_user_password.result
    api_key           = local.api_key
    cluster_arn       = module.ecs.cluster_arn
    security_group_id = module.ecs_service_private_api.security_group_id
    subnet_ids        = module.vpc.public_subnets
    task_arn          = module.ecs_service_private_api.task_definition_arn
  })
}
