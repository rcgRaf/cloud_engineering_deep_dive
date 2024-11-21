resource "aws_ecs_cluster" "main" {
  name = "${terraform.workspace}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Attaches both capacity providers to the ECS cluster
# and sets their relative weights and base providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [
    aws_ecs_capacity_provider.ec2.name,
    aws_ecs_capacity_provider.ec2_spot.name
  ]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 1
    capacity_provider = aws_ecs_capacity_provider.ec2.name
  }

  default_capacity_provider_strategy {
    weight            = 2
    capacity_provider = aws_ecs_capacity_provider.ec2_spot.name
  }
}