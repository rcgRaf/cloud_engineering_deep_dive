# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "github_actions_lambda_deploy_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.github_org}/${local.github_repo_name}:*"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# IAM Policy for Role Permissions
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "github_actions_lambda_deploy_policy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::rcgrafbucket/*"
      }
    ]
  })
}