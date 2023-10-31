module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.4.0"

  cluster_name = "${local.prefix}-cluster"
}
