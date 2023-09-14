module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${local.prefix}-main"
  cidr = "10.0.0.0/16"

  azs = var.azs

  public_subnets      = ["10.0.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]              #  64 IPs in each subnet
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]                 #  256 IPs in each subnet
  database_subnets    = ["10.0.100.0/26", "10.0.100.64/26", "10.0.100.128/26"]        #  64 IPs in each subnet
  elasticache_subnets = ["10.0.101.0/26", "10.0.101.64/26", "10.0.101.128/26"]        #  64 IPs in each subnet

  create_database_subnet_route_table     = local.enable_public_db
  create_database_internet_gateway_route = local.enable_public_db

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  single_nat_gateway     = var.single_nat_gateway
}
