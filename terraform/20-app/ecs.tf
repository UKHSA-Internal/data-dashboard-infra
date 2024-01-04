module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.7.4"

  cluster_name = "${local.prefix}-cluster"
}
