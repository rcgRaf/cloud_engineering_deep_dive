resource "aws_sqs_queue" "events_queue" {
  name = "events-queue"
}

data "archive_file" "sqs_lambda" {
  type        = "zip"
  source_dir  = "../src/sqsLambda/"
  output_path = "../src/dist/sqsLambda/sqs_lambda.zip"
}

data "archive_file" "dynamo_stream_lambda" {
  type        = "zip"
  source_dir  = "../src/dynamoLambda/"
  output_path = "../src/dist/dynamoLambda/dynamo_lambda.zip"
}

resource "aws_dynamodb_table" "events_table" {
  name         = "events-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  attribute {
    name = "event_id"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ]
        Resource = [
          aws_dynamodb_table.events_table.arn,
          aws_dynamodb_table.events_table.stream_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.events_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "process_sqs_lambda" {
  filename         = data.archive_file.sqs_lambda.output_path
  function_name    = "process-sqs-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.sqs_lambda.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.events_table.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.events_queue.arn
  function_name    = aws_lambda_function.process_sqs_lambda.arn
}

resource "aws_lambda_function" "process_dynamodb_stream_lambda" {
  filename         = data.archive_file.dynamo_stream_lambda.output_path
  function_name    = "process-dynamodb-stream-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.dynamo_stream_lambda.output_path
}

resource "aws_lambda_event_source_mapping" "dynamodb_to_lambda" {
  event_source_arn  = aws_dynamodb_table.events_table.stream_arn
  function_name     = aws_lambda_function.process_dynamodb_stream_lambda.arn
  starting_position = "LATEST"
}

# Upload sample Lambda code and push events manually
