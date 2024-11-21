# Task Definition - Initial/base version
resource "aws_ecs_task_definition" "backend" {
  family                   = "${terraform.workspace}-backend"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 256
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  # This container definition will be overridden by CI/CD
  container_definitions = jsonencode([
    {
      name      = "backend"
      cpu       = 256
      memory    = 256
      image     = "${aws_ecr_repository.backend_repos.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 4444
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_backend.name
          "awslogs-region"        = local.core_region
          "awslogs-stream-prefix" = "backend"
        }
      },

      environment = [
        {
          name  = "BASIC_AUTH_USERNAME"
          value = "admin"
        },
        {
          name  = "BASIC_AUTH_PASSWORD"
          value = "password"
        }
      ]
    },
  ])


  tags = {
    Environment = terraform.workspace
  }
}

resource "aws_ecs_service" "backend" {
  name            = "${terraform.workspace}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = "${aws_ecs_task_definition.backend.family}:${max(aws_ecs_task_definition.backend.revision, data.aws_ecs_task_definition.backend.revision)}"
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
    base              = 1
  }
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2_spot.name
    weight            = 1
  }

  network_configuration {
    subnets          = aws_subnet.core_private[*].id
    security_groups  = [aws_security_group.backend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 4444
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# Add this data source to fetch the latest task definition
data "aws_ecs_task_definition" "backend" {
  task_definition = aws_ecs_task_definition.backend.family
}

resource "aws_security_group" "backend" {
  name        = "${terraform.workspace}-backend-service"
  description = "Security group for backend service"
  vpc_id      = aws_vpc.core.id

  ingress {
    from_port       = 4444
    to_port         = 4444
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_iam_role" "ecs_task" {
  name = "${terraform.workspace}-backend-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}


# resource "aws_iam_role_policy" "ecs_task" {
#   name = "${terraform.workspace}-backend-ecs-task-policy"
#   role = aws_iam_role.ecs_task.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject",
#         ]
#         Resource = ["*"]
#       }
#     ]
#   })
# }


resource "aws_cloudwatch_log_group" "ecs_backend" {
  name              = "/ecs/${terraform.workspace}/backend"
  retention_in_days = 30 # Adjust retention as needed

  tags = {
    Environment = terraform.workspace
  }
}