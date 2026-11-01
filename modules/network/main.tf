terraform {
  required_version = ">= 1.15.0"
}

locals {
  name             = "yuratab71-simple-notes"
  namespace        = "AWS/ApiGateway"
  namespace_custom = "Custom/ApiGateway"
  throttle         = "Throttle"
  unautorized      = "Unautorized"
  ok               = "Success"
  latency          = "Latency"
  total            = "Total Payload"
  internal_errors  = "5XXError"
  client_errors    = "4XXError"
}

resource "aws_route53_zone" "this" {
  name = var.domain
}

resource "aws_iam_role" "this" {
  name = "api-gw-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.this.arn

  depends_on = [
    aws_iam_role_policy_attachment.this
  ]
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_rest_api" "this" {
  name = "simple-notes-apigw"
}

resource "aws_api_gateway_resource" "list" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "notes"
}

resource "aws_api_gateway_resource" "id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.list.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.id.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.id.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.id.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = var.redeployment
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*Put it here*/
resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "main"

  depends_on = [
    aws_api_gateway_account.this
  ]

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.this.arn

    format = replace(
      jsonencode({
        requestId         = "$context.requestId"
        ip                = "$context.identity.sourceIp"
        httpMethod        = "$context.httpMethod"
        resourcePath      = "$context.resourcePath"
        status            = "$context.status"
        responseLength    = "$context.responseLength"
        responseTime      = "$context.responseLatency"
        integrationTime   = "$context.integrationLatency"
        integrationStatus = "$context.integrationStatus"
        error             = "$context.error.message"
      }),
      "\"responseLength\":\"$context.responseLength\"",
      "\"responseLength\":$context.responseLength"
    )
  }
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "ERROR"
  }
}

// ====================================================
// CLOUDWATCH METRICS
// ====================================================
resource "aws_cloudwatch_log_metric_filter" "throttle" {
  name           = "gw_throttled_requests"
  log_group_name = aws_cloudwatch_log_group.this.name

  pattern = "{ $.status = 429 }"

  metric_transformation {
    name      = local.throttle
    namespace = local.namespace_custom
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized" {
  name           = "gw_unautorized_request"
  log_group_name = aws_cloudwatch_log_group.this.name

  pattern = "{ $.status = 401 || $.status = 403 }"

  metric_transformation {
    name      = local.unautorized
    namespace = local.namespace_custom
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "ok" {
  name           = "gw_200ok_request"
  log_group_name = aws_cloudwatch_log_group.this.name

  pattern = "{ $.status = 200 }"

  metric_transformation {
    name      = local.ok
    namespace = local.namespace_custom
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "total" {
  name           = "gw_total"
  log_group_name = aws_cloudwatch_log_group.this.name

  pattern = "{ $.responseLength = * }"

  metric_transformation {
    name      = local.total
    namespace = local.namespace_custom
    value     = "$.responseLength"
    unit      = "Bytes"
  }
}

resource "aws_cloudwatch_metric_alarm" "total" {
  alarm_name          = "simple-notes-api-processed-bytes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = local.total
  namespace           = local.namespace_custom
  period              = 300
  statistic           = "Sum"
  threshold           = 100000
  alarm_description   = "Alarm for total bytes payload"
  alarm_actions       = [var.sns_arn]
  ok_actions          = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "simple-notes-api-gateway-latency-metric"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = local.latency
  namespace           = local.namespace
  period              = 300
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "Avarage Latency"
  alarm_actions       = [var.sns_arn]
  ok_actions          = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "internal_errors" {
  alarm_name          = "simple-notes-api-gateway-5xx-error-metric"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = local.internal_errors
  namespace           = local.namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Sum of failed requests with 5xx error"
  alarm_actions       = [var.sns_arn]
  ok_actions          = [var.sns_arn]
}

resource "aws_cloudwatch_metric_alarm" "client_errors" {
  alarm_name          = "simple-notes-api-gateway-4xx-error-metric"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = local.client_errors
  namespace           = local.namespace
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Sum of failed requests with 4xx error"
  alarm_actions       = [var.sns_arn]
  ok_actions          = [var.sns_arn]
}

// ====================================================
// CLOUDWATCH LOG GROUP
// ====================================================
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.this.name}/access"
  retention_in_days = 7
}
