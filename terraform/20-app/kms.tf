module "kms_app_rds" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  description             = "RDS encryption key"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  multi_region            = false

  key_owners = ["arn:aws:iam::${var.tools_account_id}:root"]

  aliases                 = ["${local.prefix}-app-rds"]
  aliases_use_name_prefix = true
}

module "kms_secrets_app_engineer" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  description             = "Encryption key secrets needed by application engineers"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  multi_region            = false

  key_owners = [
    "arn:aws:iam::${var.tools_account_id}:root"
  ]
  key_service_users = [
    module.ecs_service_front_end.task_exec_iam_role_arn,
    module.ecs_service_feedback_api.task_exec_iam_role_arn,
    module.ecs_service_public_api.task_exec_iam_role_arn,
    module.ecs_service_private_api.task_exec_iam_role_arn,
    module.ecs_service_cms_admin.task_exec_iam_role_arn,
  ]

  aliases                 = ["${local.prefix}-secrets-app-engineer"]
  aliases_use_name_prefix = true
}

module "kms_secrets_app_operator" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  description             = "Encryption key secrets needed by application operator"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  multi_region            = false

  key_owners = [
    "arn:aws:iam::${var.tools_account_id}:root"
  ]
  key_service_users = [
    module.ecs_service_front_end.task_exec_iam_role_arn,
    module.ecs_service_feature_flags.task_exec_iam_role_arn,
    module.ecs_service_cms_admin.task_exec_iam_role_arn,
  ]

  aliases                 = ["${local.prefix}-secrets-app-operator"]
  aliases_use_name_prefix = true
}
