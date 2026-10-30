variable "domain" {
  type = string
}

variable "region" {
  description = "Region!"
  type        = string
}

variable "sns_arn" {
  description = "SNS topic arn"
  type        = string
}

variable "redeployment" {
  type = string
}
