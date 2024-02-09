module "kms_splunk" {
  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.0"

  aliases    = ["splunk-cloud-watch-logs-kinesis"]
  key_owners = var.kms_key_owners
}
