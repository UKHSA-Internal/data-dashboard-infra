module "kms_app_rds" {
	source  = "terraform-aws-modules/kms/aws"
	version = "3.0.0"

	description             = "RDS encryption key"
	key_usage               = "ENCRYPT_DECRYPT"
	deletion_window_in_days = 7
    multi_region            = false

	key_owners          	= ["arn:aws:iam::${var.tools_account_id}:root"]

    aliases                 = ["${local.prefix}-app-rds"]
	aliases_use_name_prefix = true
}
