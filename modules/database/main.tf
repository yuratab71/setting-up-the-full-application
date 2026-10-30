terraform {
  required_version = ">= 1.15.0"
}

locals {
  namespace = "AWS/DynamodDB"
  read      = "ConsumedReadCapacityUnits"
  write     = "ConsumedWriteCapacityUnits"
  latency   = "SuccessfulRequestLatency"
}

resource "aws_dynamodb_table" "this" {
  name         = "notes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "noteId"

  attribute {
    name = "noteId"
    type = "S"
  }
}

// ====================================================
// CLOUDWATCH METRICS
// ====================================================
resource "aws_cloudwatch_metric_alarm" "read" {
  alarm_name          = "${aws_dynamodb_table.this.name}-consumed-read-capacity-metric"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = local.read
  namespace           = local.namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "The number of read capacity units consumed over the specified time period"
  alarm_actions       = [var.sns_arn]
  ok_actions          = [var.sns_arn]

  dimensions = {
    TableName = aws_dynamodb_table.this.name
  }
}

resource "aws_cloudwatch_metric_alarm" "write" {
  alarm_name          = "${aws_dynamodb_table.this.name}-consumed-write-capacity-metric"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = local.write
  namespace           = local.namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "The number of write capacity units consumed over the specified time period"
  alarm_actions       = [var.sns_arn]
  ok_actions          = [var.sns_arn]

  dimensions = {
    TableName = aws_dynamodb_table.this.name
  }
}

resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "${aws_dynamodb_table.this.name}-successful-reques-latency-metric"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = local.latency
  namespace           = local.namespace
  period              = 900
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "The latency of successful requests to DynamoDB "
  alarm_actions       = [var.sns_arn]
  ok_actions          = [var.sns_arn]

  dimensions = {
    TableName = aws_dynamodb_table.this.name
  }
}
