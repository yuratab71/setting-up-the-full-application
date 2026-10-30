variable "region" {
  type = string
}

variable "lambda_name" {
  type = string
}

variable "metric_widgets" {
  type = list(object({
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
  }))
}

variable "log_widgets" {
  type = list(object({
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
  }))
}
