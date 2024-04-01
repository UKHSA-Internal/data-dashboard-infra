module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.10.1"

  cluster_name = "${local.prefix}-cluster"
}
