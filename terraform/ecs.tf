resource "aws_ecs_cluster" "wp_api_cluster" {
  name = "wp-api-cluster" 
}

resource "aws_ecs_cluster" "wp_frontend_cluster" {
  name = "wp-frontend-cluster" 
}


resource "aws_ecs_task_definition" "wp_api_task" {
  family                   = "wp-api-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "wp-api-task",
      "image": "${aws_ecr_repository.ecr_repository_api.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

resource "aws_ecs_task_definition" "wp_api_frontend_task" {
  family                   = "wp-frontend-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "wp-frontend-task",
      "image": "${aws_ecr_repository.ecr_repository_frontend.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_service_linked_role" "ecs" {
  aws_service_name = "ecs.amazonaws.com"
}

resource "aws_ecs_service" "wp_api_service" {
  name            = "wp-api-service-1"                             # Naming our first service
  cluster         = "${aws_ecs_cluster.wp_api_cluster.id}"             # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.wp_api_task.arn}" # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Setting the number of containers we want deployed to 3
   network_configuration {
    subnets          = [var.subnet_id_1,var.subnet_id_2,var.subnet_id_3]
    assign_public_ip = true # Providing our containers with public IPs
  }
}

resource "aws_ecs_service" "wp_frontend_service" {
  name            = "wp-frontend-service"                             # Naming our first service
  cluster         = "${aws_ecs_cluster.wp_frontend_cluster.id}"             # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.wp_api_frontend_task.arn}" # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Setting the number of containers we want deployed to 3

  load_balancer {
    target_group_arn = "${aws_lb_target_group.wp_target_group.arn}" # Referencing our target group
    container_name   = "${aws_ecs_task_definition.wp_api_frontend_task.family}"
    container_port   = 3000 # Specifying the container port
  }

  network_configuration {
    subnets          = [var.subnet_id_1,var.subnet_id_2,var.subnet_id_3]
    assign_public_ip = true # Providing our containers with public IPs
  }
}

