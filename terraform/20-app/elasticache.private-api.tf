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
    },
    {
      description              = "utility worker tasks to cache"
      rule                     = "redis-tcp"
      source_security_group_id = module.ecs_service_utility_worker.security_group_id
    }
  ]
}

resource "aws_elasticache_serverless_cache" "app_elasticache" {
  engine = "redis"
  name   = "${local.prefix}-app-serverless-redis"

  major_engine_version     = "7"
  snapshot_retention_limit = 1
  security_group_ids       = [module.app_elasticache_security_group.security_group_id]
  subnet_ids               = module.vpc.elasticache_subnets
}
