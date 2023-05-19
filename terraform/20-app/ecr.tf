resource "aws_ecr_repository" "api" {
  name = "${local.prefix}-api"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "frontend" {
  name = "${local.prefix}-front-end"

  image_scanning_configuration {
    scan_on_push = true
  }
}