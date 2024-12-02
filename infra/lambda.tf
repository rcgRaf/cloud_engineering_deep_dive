# resource "aws_iam_role" "lambda_execution_role" {
#   name               = "lambda_execution_role"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy" "lambda_policy" {
#   name   = "lambda_policy"
#   role   = aws_iam_role.lambda_execution_role.id
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "logs:CreateLogGroup",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents"
#       ],
#       "Effect": "Allow",
#       "Resource": "arn:aws:logs:*:*:*"
#     }
#   ]
# }
# EOF
# }

# resource "aws_lambda_function" "hello_world" {
#   function_name = "hello_world_lambda"
#   role          = aws_iam_role.lambda_execution_role.arn
#   runtime       = "nodejs18.x"
#   handler       = "index.handler"

#   s3_bucket = data.aws_s3_bucket.existing_bucket.bucket
#   s3_key    = "lambda.zip"
#   # Fetch the Lambda zip file from S3
#   layers = [
#     aws_lambda_layer_version.node_js_layer.arn ]

#   # Compute the hash from the S3 object
#   source_code_hash = filebase64sha256("../src/lambda/index.js")
# }

# resource "aws_lambda_layer_version" "node_js_layer" {
#   layer_name          = "node_js_layer"
#   description         = "Node layer"
#   compatible_runtimes = ["nodejs18.x"]
#   s3_bucket = data.aws_s3_bucket.existing_bucket.bucket
#   s3_key    = "layer.zip"

#   source_code_hash = filebase64sha256("../src/lambda/nodejs")
# }

# data "aws_s3_bucket" "existing_bucket" {
#   bucket = "rcgrafbucket"  # Replace with your existing bucket name
# }

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
