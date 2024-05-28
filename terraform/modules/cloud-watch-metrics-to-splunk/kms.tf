module "kms_splunk" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.0.0"

  aliases    = ["splunk-cloud-watch-metrics-kinesis"]
  create     = var.create
  key_owners = var.kms_key_owners
}
