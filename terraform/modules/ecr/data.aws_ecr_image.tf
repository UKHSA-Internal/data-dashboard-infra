data "aws_ecr_image" "this" {
  depends_on = [terraform_data.initial_image_provisioner]
  repository_name = module.ecr.repository_name
  most_recent     = true
}
