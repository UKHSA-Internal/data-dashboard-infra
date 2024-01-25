module "kms_splunk" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.5.0"

  aliases    = ["splunk-cloud-watch-metrics-kinesis"]
  create     = var.create
  key_owners = var.kms_key_owners
}
