resource "aws_instance" "github_runner" {
  count         = 0
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  user_data = base64encode(templatefile("${path.module}/scripts/github-runner-setup.sh", {
    github_token = local.github_token,
    runner_label = local.runner_label,
    repo_url     = local.repo_url
  }))

  associate_public_ip_address = true
  key_name                    = aws_key_pair.github_runner_key.key_name

  subnet_id              = aws_subnet.main[0].id
  vpc_security_group_ids = [aws_security_group.github_runner_sg.id]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami,
      associate_public_ip_address,
      user_data_replace_on_change,
    ]
  }

  user_data_replace_on_change = true


  tags = {
    Name = "${local.prefix}-github-runner"
  }
}


resource "aws_security_group" "github_runner_sg" {
  name        = "${local.prefix}-github-runner-sg"
  description = "Security group for GitHub runner."
  vpc_id      = aws_vpc.main.id

  # ingress {
  #   from_port       = 22
  #   to_port         = 22
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.openvpn_sg.id]
  #   description     = "Allow SSH from OpenVPN"
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-github-runner-sg"
  }
}

resource "aws_key_pair" "github_runner_key" {
  key_name   = "${local.prefix}-github-runner-key"
  public_key = local.github_public_key
}

# IAM Instance Profile for the runner
resource "aws_iam_instance_profile" "runner_profile" {
  name = "runner-ec2-profile"
  role = aws_iam_role.runner_role.name
}

# IAM Policy for the runner
resource "aws_iam_policy" "runner_policy" {
  name        = "runner-policy"
  path        = "/"
  description = "Policy for runner EC2 instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "runner_role" {
  name = local.ec2_runner_iam_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.github_org}/${local.github_repo_name}:*"
          }
        }
      },
    ]
  })
}

# Attach the policy to the role 
resource "aws_iam_role_policy_attachment" "runner_policy_attachment" {
  role       = aws_iam_role.runner_role.name
  policy_arn = aws_iam_policy.runner_policy.arn
}
