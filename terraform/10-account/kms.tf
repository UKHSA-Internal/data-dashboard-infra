module "kms_secrets" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  description             = "Account level secrets encryption key"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  multi_region            = false

  key_owners = ["arn:aws:iam::${var.tools_account_id}:root"]

  aliases                 = ["${local.project}-${local.account}-account-secrets"]
  aliases_use_name_prefix = true
}
