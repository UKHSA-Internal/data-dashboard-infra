module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.0.1"

  cluster_name = "${local.prefix}-cluster"
}
