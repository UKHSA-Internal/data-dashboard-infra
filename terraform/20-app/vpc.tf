module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.prefix}-main"
  cidr = "10.0.0.0/16"

  azs               = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  database_subnets  = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  private_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets    = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  create_database_subnet_route_table     = var.environment_type == "dev"
  create_database_internet_gateway_route = var.environment_type == "dev"

  enable_dns_hostnames = var.environment_type == "dev"
  enable_dns_support   = var.environment_type == "dev"
}