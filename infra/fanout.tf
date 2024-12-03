resource "aws_sns_topic" "new_product_topic" {
  name = "NewProductTopic"
}

resource "aws_sqs_queue" "dlqs" {
  for_each = toset(local.queue_names)

  name = "${each.value}-DLQ"
}

# Create SQS queues with individual DLQs
resource "aws_sqs_queue" "queues" {
  for_each = toset(local.queue_names)

  name = each.value

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlqs[each.key].arn
    maxReceiveCount     = 5
  })
}

# Grant SNS permission to send messages to each SQS queue
resource "aws_sqs_queue_policy" "sns_to_sqs_policy" {
  for_each = aws_sqs_queue.queues

  queue_url = each.value.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "sqs:SendMessage",
        Resource  = each.value.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.new_product_topic.arn
          }
        }
      }
    ]
  })
}

# Subscribe each SQS queue to the SNS topic
resource "aws_sns_topic_subscription" "sns_to_sqs_subscriptions" {
  for_each = aws_sqs_queue.queues

  topic_arn = aws_sns_topic.new_product_topic.arn
  protocol  = "sqs"
  endpoint  = each.value.arn
}
