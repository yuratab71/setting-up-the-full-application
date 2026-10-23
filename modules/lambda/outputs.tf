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
