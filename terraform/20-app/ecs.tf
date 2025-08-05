module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.1.3"

  cluster_name = "${local.prefix}-cluster"
}
