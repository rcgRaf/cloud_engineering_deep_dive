# IAM Role for ECS EC2 Instances
# This role allows EC2 instances to:
# - Register themselves with ECS cluster
# - Pull container images
# - Report container health and metrics
# - Communicate with other AWS services
resource "aws_iam_role" "ecs_instance" {
  name = "${terraform.workspace}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attaches the AWS managed policy for ECS EC2 instances
# This policy provides necessary permissions for ECS agent operations
# without requiring manual policy management
resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Add ECR access for ECS instances
resource "aws_iam_role_policy_attachment" "ecs_instance_ecr" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance Profile for EC2 instances
# Required to assign the IAM role to EC2 instances
# Allows instances to assume the role and get necessary permissions
resource "aws_iam_instance_profile" "ecs" {
  name = "${terraform.workspace}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
}

# Launch Template for ECS EC2 Instances
# Defines the blueprint for EC2 instances that will join the ECS cluster
# Includes:
# - ECS-optimized AMI
# - Instance type and size
# - User data script for ECS agent configuration
# - Network and security settings
resource "aws_launch_template" "ecs" {
  name = "${terraform.workspace}-ecs-lt"

  image_id      = "ami-05df9ff28520b44e8"
  instance_type = "t3.nano"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.main.name}" >> /etc/ecs/ecs.config
    echo "ECS_ENABLE_SPOT_INSTANCE_DRAINING=true" >> /etc/ecs/ecs.config
  EOF
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_instances.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${terraform.workspace}-ecs-instance"
    }
  }

  monitoring {
    enabled = true
  }

  key_name = aws_key_pair.core_instance_access.key_name
}

# Security Group for ECS Instances
# Controls network traffic to/from ECS container instances
# Allows:
# - Inbound traffic from ALB
# - All outbound traffic for container operations
# - Communication between containers and AWS services
resource "aws_security_group" "ecs_instances" {
  name        = "${terraform.workspace}-ecs-instances"
  description = "Security group for ECS instances"
  vpc_id      = aws_vpc.core.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-ecs-instances"
  }
}

# Auto Scaling Group for On-Demand Instances
# Manages the fleet of EC2 instances for the ECS cluster
# Provides:
# - Automatic scaling based on demand
# - Self-healing by replacing unhealthy instances
# - Distribution across AZs for high availability
resource "aws_autoscaling_group" "ecs" {
  name                = "${terraform.workspace}-ecs-asg"
  vpc_zone_identifier = aws_subnet.core_private[*].id
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 5
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

# Auto Scaling Group for Spot Instances
# Provides cost-optimized compute capacity using Spot instances
# Features:
# - Mixed instance types for better availability
# - Spot instance termination handling
# - Capacity-optimized allocation strategy
resource "aws_autoscaling_group" "ecs_spot" {
  name                = "${terraform.workspace}-ecs-spot-asg"
  vpc_zone_identifier = aws_subnet.core_private[*].id
  health_check_type   = "EC2"
  min_size            = 0
  max_size            = 0
  desired_capacity    = 0

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs.id
        version            = "$Latest"
      }

      override {
        instance_type = "t3.nano"
      }
      # Add more instance types for better spot availability
      override {
        instance_type = "t3.micro"
      }
      override {
        instance_type = "t3a.nano"
      }
    }
  }

  # Important: Add instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

# ECS Capacity Provider for On-Demand Instances
# Links the Auto Scaling Group with ECS cluster
# Manages:
# - Scaling based on ECS task demands
# - Instance lifecycle with ECS cluster
# - Capacity optimization and distribution
resource "aws_ecs_capacity_provider" "ec2" {
  name = "${terraform.workspace}-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

# ECS Capacity Provider for Spot Instances
# Similar to on-demand provider but for Spot instances
# Provides:
# - Cost-optimized task placement
# - Automatic spot instance replacement
# - Graceful task migration on spot interruption
resource "aws_ecs_capacity_provider" "ec2_spot" {
  name = "${terraform.workspace}-ec2-spot"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_spot.arn

    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}




# spin up ec2 intsance in public subnet
resource "aws_instance" "ecs" {
  ami                         = "ami-0c7217cdde317cfec"
  instance_type               = "t3.nano"
  subnet_id                   = aws_subnet.core_public[0].id
  key_name                    = aws_key_pair.core_instance_access.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ecs_instances.id]
}


# resource "aws_autoscaling_policy" "scale_out" {
#   name                   = "${terraform.workspace}-ecs-scale-out"
#   scaling_adjustment     = 1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 300
#   autoscaling_group_name = aws_autoscaling_group.ecs.name
# }