########################################
# Módulo: observability
# SNS + Alarmas para Lambda, API Gateway y Aurora
########################################

locals {
  tags = merge(var.tags, {
    Component = "observability"
  })

  # Nombre del API (coherente con el módulo apigw)
  apigw_name = "${var.name_prefix}-api"

  # Obtener DBClusterIdentifier desde el ARN del cluster Aurora
  db_cluster_id = regex("arn:aws:rds:[^:]+:[0-9]+:cluster:([^:]+)", var.db_cluster_arn)[0]
}

########################################
# SNS Topic de alarmas
########################################

resource "aws_sns_topic" "alarm_topic" {
  name = "${var.name_prefix}-alarms"

  tags = local.tags
}

resource "aws_sns_topic_subscription" "alarm_email" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

########################################
# Alarmas por Lambda: Errors > 0
########################################

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "${var.name_prefix}-${each.value}-errors"
  alarm_description   = "Errores en Lambda ${each.value} mayores a 0 en 5 minutos"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  alarm_actions = [aws_sns_topic.alarm_topic.arn]

  tags = local.tags
}

########################################
# Alarma API Gateway: 5XXError > 0
########################################

resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  alarm_name          = "${var.name_prefix}-api-5xx"
  alarm_description   = "Errores 5XX en API Gateway para stage ${var.apigw_stage_name}"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  # Para REST API se suelen usar dimensiones ApiName + Stage
  dimensions = {
    ApiName = local.apigw_name
    Stage   = var.apigw_stage_name
  }

  alarm_actions = [aws_sns_topic.alarm_topic.arn]

  tags = local.tags
}

########################################
# Alarma Aurora: capacidad / carga alta
# (ejemplo con ServerlessDatabaseCapacity)
########################################

resource "aws_cloudwatch_metric_alarm" "aurora_capacity_high" {
  alarm_name          = "${var.name_prefix}-aurora-capacity-high"
  alarm_description   = "Aurora Serverless v2 usando capacidad alta durante 10 minutos"
  namespace           = "AWS/RDS"
  metric_name         = "ServerlessDatabaseCapacity"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 1.8          # por ejemplo, >1.8 ACUs si max es 2.0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = local.db_cluster_id
  }

  alarm_actions = [aws_sns_topic.alarm_topic.arn]

  tags = local.tags
}
