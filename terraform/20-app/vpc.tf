module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${local.prefix}-main"
  cidr = "10.0.0.0/16"

  azs = var.azs

  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]           # 256 IPs in each subnet
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]     # 256 IPs in each subnet
  elasticache_subnets = ["10.0.200.0/26", "10.0.200.64/26", "10.0.200.128/26"]  #  64 IPs in each subnet
  database_subnets    = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]     # 256 IPs in each subnet

  create_database_subnet_route_table     = local.enable_public_db
  create_database_internet_gateway_route = local.enable_public_db

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  single_nat_gateway     = var.single_nat_gateway
}
