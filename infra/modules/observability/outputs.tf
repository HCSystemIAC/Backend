output "sns_alarm_topic_arn" {
  description = "ARN del topic SNS donde se envían las alarmas"
  value       = aws_sns_topic.alarm_topic.arn
}
