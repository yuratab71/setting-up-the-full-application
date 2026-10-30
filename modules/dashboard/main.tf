terraform {
  required_version = ">= 1.15.0"
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "simple-notes"

  dashboard_body = jsonencode({
    widgets = concat(var.metric_widgets, var.log_widgets)
  })
}

resource "aws_sns_topic" "this" {
  name = "simple-notes-sns-topic"
}
