output "method_id" {
  type  = string
  value = aws_api_gateway_method.this.id
}

output "integration_id" {
  type  = string
  value = aws_api_gateway_integration.this.id
}

output "arn" {
  type  = string
  value = aws_lambda_function.this.arn
}

output "function_name" {
  type  = string
  value = aws_lambda_function.this.function_name
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
    height = 8,
    properties = {
      title  = "${aws_lambda_function.this.function_name} Overview"
      period = 300
      stat   = "Average"
      view   = "timeSeries"
      region = var.region
      metrics = [
        [
          "${local.namespace}",
          "${local.throttles}",
          "FunctionName",
          "${aws_lambda_function.this.function_name}"
        ],
        [
          "${local.namespace}",
          "${local.concurrent_executions}",
          "FunctionName",
          "${aws_lambda_function.this.function_name}"
        ]

      ],
    },
  }
}

output "dashboard_widget_performance" {
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
    height = 3

    properties = {
      title  = "${aws_lambda_function.this.function_name} Performace"
      view   = "table"
      region = var.region

      query = <<-QUERY
          SOURCE '${aws_cloudwatch_log_group.this.name}' 
          | filter @type = "REPORT"
          | stats
            count(*) as Invocations,
            avg(@initDuration) as ColdStart,
            avg(@billedDuration) as AvgBilledDuration,
            sum(@billedDuration) as TotalBilledDuration
          QUERY
    }
  }
}

output "dashboard_widget_memory" {
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
    height = 5

    properties = {
      title  = "${aws_lambda_function.this.function_name} Memory Consumption"
      view   = "timeSeries"
      region = var.region

      query = <<-QUERY
          SOURCE '${aws_cloudwatch_log_group.this.name}' 
          | filter @type = "REPORT"
          | stats
            max(@maxMemoryUsed / @memorySize * 100) as MaxMemoryUsagePercent,
            avg(@maxMemoryUsed / @memorySize * 100) as AvgMemoryUsagePercent         
          by bin(5m)
      QUERY
    }
  }
}
