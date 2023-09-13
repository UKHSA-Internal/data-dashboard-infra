resource "aws_elasticache_subnet_group" "app_elasticache_subnet" {
  name       = "${local.prefix}-app-elasticache-subnet"
  subnet_ids = module.vpc.public_subnets

}

module "app_elasticache_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "${local.prefix}-app-elasticache"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "private api tasks to cache"
      rule                     = "redis-tcp"
      source_security_group_id = module.ecs_service_private_api.security_group_id
    }
  ]
}


resource "aws_elasticache_cluster" "app_elasticache" {
  cluster_id           = "${local.prefix}-app-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.app_elasticache_subnet.name
  security_group_ids   = [module.app_elasticache_security_group.security_group_id]
}