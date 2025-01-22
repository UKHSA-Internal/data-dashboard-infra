provider "aws" {
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${var.assume_account_id}:role/${var.assume_role_name}"
  }

  default_tags {
    tags = {
      project_name = local.project
      env          = terraform.workspace
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.assume_account_id}:role/${var.assume_role_name}"
  }

  default_tags {
    tags = {
      project_name = local.project
      env          = terraform.workspace
    }
  }
}

terraform {
  backend "s3" {
    region         = "eu-west-2"
    bucket         = "uhd-terraform-states"
    dynamodb_table = "terraform-state-lock"
    key            = "app/state.tfstate"
  }
}

module "cognito" {
  source = "../modules/cognito"

  user_pool_name    = "app-${terraform.workspace}-user-pool"
  client_name       = "app-${terraform.workspace}-client"
  user_pool_domain  = "app-${terraform.workspace}-auth"

  callback_urls = ["https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk/callback"]
  logout_urls   = ["https://${terraform.workspace}.dev.ukhsa-dashboard.data.gov.uk/logout"]
}

resource "aws_security_group" "app_security_group" {
  name        = "app-security-group"
  description = "Security group for the application"
  vpc_id = module.vpc.vpc_id

  ingress {
    description      = "Allow traffic from app to RDS"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = [module.aurora_db_app.security_group_id]
    self             = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "rds_connection_info" {
  description = "Connection details for the Aurora RDS cluster"
  value = {
    endpoint   = module.aurora_db_app.cluster_endpoint
    port       = module.aurora_db_app.cluster_port
    db_name    = module.aurora_db_app.cluster_database_name
    username   = module.aurora_db_app.cluster_master_username
    password   = module.aurora_db_app.cluster_master_password
  }
  sensitive = true
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}