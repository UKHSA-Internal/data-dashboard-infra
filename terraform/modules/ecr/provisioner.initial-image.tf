resource "terraform_data" "initial_image_provisioner" {
  depends_on = [module.ecr]
  provisioner "local-exec" {
    command = <<EOF
      aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.eu-west-2.amazonaws.com
      docker pull gcr.io/distroless/static:nonroot
      docker tag gcr.io/distroless/static:nonroot ${module.ecr.repository_url}:initial
      docker push ${module.ecr.repository_url}:initial
    EOF
  }
}
