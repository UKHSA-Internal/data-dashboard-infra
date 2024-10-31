module "kms_app_rds" {
	source  = "terraform-aws-modules/kms/aws"
	version = "3.1.0"

	description             = "RDS encryption key"
	key_usage               = "ENCRYPT_DECRYPT"
	deletion_window_in_days = 7
    multi_region            = false

	key_owners          	= ["arn:aws:iam::${var.tools_account_id}:root"]

    aliases                 = ["${local.prefix}-app-rds"]
	aliases_use_name_prefix = true
}


module "kms_secrets_app_operator" {
	source  = "terraform-aws-modules/kms/aws"
	version = "3.1.0"

	description             = "Encryption key secrets needed by application operator"
	key_usage               = "ENCRYPT_DECRYPT"
	deletion_window_in_days = 7
    multi_region            = false

	key_owners          	= ["arn:aws:iam::${var.tools_account_id}:root"]

    aliases                 = ["${local.prefix}-secrets-app-operator"]
	aliases_use_name_prefix = true
}


module "kms_secrets_engineer" {
	source  = "terraform-aws-modules/kms/aws"
	version = "3.1.0"

	description             = "Encryption key secrets needed by application engineers"
	key_usage               = "ENCRYPT_DECRYPT"
	deletion_window_in_days = 7
    multi_region            = false

	key_owners          	= ["arn:aws:iam::${var.tools_account_id}:root"]

    aliases                 = ["${local.prefix}-secrets-app-engineer"]
	aliases_use_name_prefix = true
}


module "kms_secrets_app_operator" {
	source  = "terraform-aws-modules/kms/aws"
	version = "3.1.0"

	description             = "Encryption key secrets needed by application operator"
	key_usage               = "ENCRYPT_DECRYPT"
	deletion_window_in_days = 7
    multi_region            = false

	key_owners          	= ["arn:aws:iam::${var.tools_account_id}:root"]

    aliases                 = ["${local.prefix}-secrets-app-operator"]
	aliases_use_name_prefix = true
}


module "kms_secrets_engineer" {
	source  = "terraform-aws-modules/kms/aws"
	version = "3.1.0"

	description             = "Encryption key secrets needed by application engineers"
	key_usage               = "ENCRYPT_DECRYPT"
	deletion_window_in_days = 7
    multi_region            = false

	key_owners          	= ["arn:aws:iam::${var.tools_account_id}:root"]

    aliases                 = ["${local.prefix}-secrets-app-engineer"]
	aliases_use_name_prefix = true
}
