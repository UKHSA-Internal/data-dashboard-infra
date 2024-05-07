module "kms_app_aurora" {
	source  = "terraform-aws-modules/kms/aws"
	version = "2.2.1"

	description             = "Aurora encryption key"
	key_usage               = "ENCRYPT_DECRYPT"
	deletion_window_in_days = 7
    multi_region            = false
	
	key_owners          	= ["arn:aws:iam::${var.tools_account_id}:root"]
	
    aliases                 = ["${local.prefix}-app-aurora"]
	aliases_use_name_prefix = true
}
