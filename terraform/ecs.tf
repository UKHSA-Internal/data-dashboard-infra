# Task definition
data "template_file" "django_app" {
  template = file("./task-definition.json")
  vars = {
    app_name       = var.project_name
    app_image      = "${var.docker_image_name}:${var.docker_image_revision}"
    app_port       = 8000
    app_db_address = aws_db_instance.app_rds.address
    app_db_port    = aws_db_instance.app_rds.port
    fargate_cpu    = "256"
    fargate_memory = "512"
    aws_region     = var.aws_region
  }
}
resource "aws_ecs_task_definition" "django_app" {
  container_definitions    = data.template_file.django_app.rendered
  family                   = var.project_name
  requires_compatibilities = [var.launch_type]
  task_role_arn            = aws_iam_role.app_execution_role.arn
  execution_role_arn       = aws_iam_role.app_execution_role.arn

  cpu          = "256"
  memory       = "512"
  network_mode = "awsvpc"
}




