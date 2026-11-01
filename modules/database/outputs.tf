output "table_id" {
  type  = string
  value = aws_dynamodb_table.this.id
}

output "table_arn" {
  type  = string
  value = aws_dynamodb_table.this.arn
}

output "table_name" {
  type  = string
  value = aws_dynamodb_table.this.name
}

output "dashboard_widget" {
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
          "${local.read}",
          "TableName",
          "${aws_dynamodb_table.this.name}"
        ],
        [
          "${local.namespace}",
          "${local.write}",
          "TableName",
          "${aws_dynamodb_table.this.name}"
        ],
        [
          "${local.namespace}",
          "${local.latency}",
          "TableName",
          "${aws_dynamodb_table.this.name}"
        ],
      ],
      title  = "DynamodDB: ${aws_dynamodb_table.this.name} Overview"
      period = 900
      stat   = "Average"
      view   = "timeSeries"
      region = var.region
    }

  }
}
