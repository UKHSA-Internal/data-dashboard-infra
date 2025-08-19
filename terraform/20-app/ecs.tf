module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.2.2"

  cluster_name = "${local.prefix}-cluster"
}
