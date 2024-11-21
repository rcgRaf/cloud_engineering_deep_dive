# resource "aws_cloudwatch_metric_alarm" "ecs_pending_tasks" {
#   alarm_name          = "${terraform.workspace}-ecs-pending-tasks"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "PendingTaskCount"
#   namespace           = "AWS/ECS"
#   period              = "60"
#   statistic           = "Average"
#   threshold           = "0"
#   alarm_description   = "Alarm when there are pending ECS tasks"

#   dimensions = {
#     ClusterName = aws_ecs_cluster.main.name
#   }

#   alarm_actions = [aws_autoscaling_policy.scale_out.arn]
# }