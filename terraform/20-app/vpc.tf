module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "${local.prefix}-main"
  cidr = "10.0.0.0/16"

  azs              = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  create_database_subnet_route_table     = local.enable_public_db
  create_database_internet_gateway_route = local.enable_public_db

  enable_dns_hostnames = true
  enable_dns_support   = true
}
