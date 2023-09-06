module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.2.2"

  cluster_name = "${local.prefix}-cluster"
}
