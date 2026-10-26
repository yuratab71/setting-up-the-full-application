variable "name" {
  description = "Lambda function name"
  type        = string
}

variable "handler" {
  description = "Handler function"
  type        = string
}

variable "filename" {
  description = "Path to the lambda source file"
  type        = string
}

variable "runtime" {
  description = "Engine on whic lambda is running"
  type        = string
}

variable "gw_id" {
  description = "Rest api gateway id"
  type        = string
}

variable "gw_resource_id" {
  description = "Rest api gateway resource id"
  type        = string
}

variable "http_method" {
  description = "Http method on which this lambda is invoked"
  type        = string
}

variable "permissions" {
  description = "List of permissions on dynamodb table"
  type        = list(string)
}

variable "dynamodb_arn" {
  description = "Table arn"
  type        = string
}

variable "table_name" {
  description = "Table name !!!"
  type        = string
}

variable "region" {
  description = "Region!"
  type        = string
}
