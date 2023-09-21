resource "local_sensitive_file" "upload_files_from_s3" {
  filename = "ecs-jobs/upload-files-from-s3.json"
  content = templatefile("ecs-jobs/upload-files-from-s3.tftpl", {
    cluster_arn             = module.ecs.cluster_arn
    security_group_id       = module.ecs_service_ingestion.security_group_id
    subnet_ids              = module.vpc.private_subnets
    task_arn                = module.ecs_service_ingestion.task_definition_arn
  })
}
