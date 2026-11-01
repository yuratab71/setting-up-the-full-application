output "nameservers" {
  type  = list(string)
  value = aws_route53_zone.this.name_servers
}

output "hosted_zone_id" {
  type  = string
  value = aws_route53_zone.this.id
}

output "gw_id" {
  type  = string
  value = aws_api_gateway_rest_api.this.id
}

output "list_resource_id" {
  type  = string
  value = aws_api_gateway_resource.list.id
}

output "id_resource_id" {
  type  = string
  value = aws_api_gateway_resource.id.id
}

output "options_method_id" {
  type  = string
  value = aws_api_gateway_method.options.id
}

output "options_integration_id" {
  type  = string
  value = aws_api_gateway_integration.options.id
}

output "dashboard_widget_metrics" {
  type = object({
    type   = string
    x      = number
    y      = number
    width  = number
    height = number
    properties = object({
      metrics = list(list(string))
      title   = string
      period  = number
      stat    = string
      view    = string
      region  = string
    })
  })

  value = {
    type   = "metric"
    x      = 0
    y      = 0
    width  = 12,
    height = 6,
    properties = {
      metrics = [
        [
          "${local.namespace}",
          "${local.latency}",
          "ApiName",
          "${aws_api_gateway_rest_api.this.name}",
          "Stage",
          "${aws_api_gateway_stage.this.stage_name}"
        ],
        [
          "${local.namespace}",
          "${local.internal_errors}",
          "ApiName",
          "${aws_api_gateway_rest_api.this.name}",
          "Stage",
          "${aws_api_gateway_stage.this.stage_name}"
        ],
        [
          "${local.namespace}",
          "${local.client_errors}",
          "ApiName",
          "${aws_api_gateway_rest_api.this.name}",
          "Stage",
          "${aws_api_gateway_stage.this.stage_name}"
        ],
        [
          "${local.namespace_custom}",
          "${local.total}"
        ],
        [
          "${local.namespace_custom}",
          "${local.unautorized}",
          "ApiName",
          "${aws_api_gateway_rest_api.this.name}",
          "Stage",
          "${aws_api_gateway_stage.this.stage_name}"
        ],
        [
          "${local.namespace_custom}",
          "${local.throttle}",
          "ApiName",
          "${aws_api_gateway_rest_api.this.name}",
          "Stage",
          "${aws_api_gateway_stage.this.stage_name}"
        ],
        [
          "${local.namespace_custom}",
          "${local.ok}",
          "ApiName",
          "${aws_api_gateway_rest_api.this.name}",
          "Stage",
          "${aws_api_gateway_stage.this.stage_name}"
        ]
      ],
      title  = "Api Gateway Latency"
      period = 300
      stat   = "Average"
      view   = "timeSeries"
      region = var.region
    },
  }
}

output "dashboard_widget_logs" {
  type = object({
    type   = string
    x      = number
    y      = number
    width  = number
    height = number
    properties = object({
      title  = string
      view   = string
      region = string
      query  = string
    })
  })

  value = {
    type   = "log"
    x      = 12
    y      = 0
    width  = 12
    height = 6

    properties = {
      title  = "Api Gateway Overview"
      view   = "timeSeries"
      region = var.region

      query = <<-QUERY
          SOURCE '${aws_cloudwatch_log_group.this.name}' 
          | filter status=200 
          | stats
            max(@maxMemoryUsed / @memorySize * 100) as MaxMemoryUsagePercent,
            avg(@maxMemoryUsed / @memorySize * 100) as AvgMemoryUsagePercent         
          by bin(5m)
       QUERY
    }
  }
}

output "gw_log_group_arn" {
  type  = string
  value = aws_cloudwatch_log_group.this.arn
}

output "gateway_url" {
  type  = string
  value = aws_api_gateway_stage.this.invoke_url
}
