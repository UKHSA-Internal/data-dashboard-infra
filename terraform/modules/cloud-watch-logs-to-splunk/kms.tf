module "kms_splunk" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases    = ["splunk-cloud-watch-logs-kinesis"]
  key_owners = var.kms_key_owners
}
