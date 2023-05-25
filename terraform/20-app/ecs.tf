module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "${local.prefix}-cluster"
}
