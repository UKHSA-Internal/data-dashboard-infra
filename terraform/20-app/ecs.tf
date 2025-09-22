module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.4.0"

  cluster_name = "${local.prefix}-cluster"
}
