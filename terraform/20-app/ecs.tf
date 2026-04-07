module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "7.2.0"

  cluster_name = "${local.prefix}-cluster"
}
