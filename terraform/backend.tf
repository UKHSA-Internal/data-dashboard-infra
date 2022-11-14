terraform {
  backend "s3" {
    encrypt = true    
    bucket = "wp-dynamo"
    dynamodb_table = "terraform-state-lock-dynamo"
    key    = "terraform.tfstate"
    region = var.aws_region
  }
}