resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_execution_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name   = "LambdaSQSPolicy"
  role   = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = [
          for queue in aws_sqs_queue.queues : queue.arn
        ]
      }
    ]
  })
}


resource "aws_lambda_function" "product_lambdas" {
  for_each = toset(local.queue_names)

  function_name = "${each.value}_Handler"
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = "nodejs18.x"
  handler       = "index.handler"

  s3_bucket = data.aws_s3_bucket.existing_bucket.bucket
  s3_key    = "lambda.zip"
  # Fetch the Lambda zip file from S3
  layers = [
    aws_lambda_layer_version.node_js_layer.arn ]


  environment {
    variables = {
      QUEUE_NAME = aws_sqs_queue.queues[each.key].name
    }
  }

  # Compute the hash from the S3 object
  source_code_hash = filebase64sha256("../src/lambda/src/index.js")
}

# Add SQS triggers for each Lambda function
resource "aws_lambda_event_source_mapping" "lambda_sqs_trigger" {
  for_each = toset(local.queue_names)

  event_source_arn = aws_sqs_queue.queues[each.key].arn
  function_name    = aws_lambda_function.product_lambdas[each.key].arn
  batch_size       = 10
  enabled          = true
}

resource "aws_lambda_layer_version" "node_js_layer" {
  layer_name          = "node_js_layer"
  description         = "Node layer"
  compatible_runtimes = ["nodejs18.x"]
  s3_bucket = data.aws_s3_bucket.existing_bucket.bucket
  s3_key    = "layer.zip"

  source_code_hash = filebase64sha256("../src/lambda/src/index.js")
}

data "aws_s3_bucket" "existing_bucket" {
  bucket = "rcgrafbucket"  # Replace with your existing bucket name
}