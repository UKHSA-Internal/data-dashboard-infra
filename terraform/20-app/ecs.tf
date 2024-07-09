module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.3"

  cluster_name = "${local.prefix}-cluster"
}
