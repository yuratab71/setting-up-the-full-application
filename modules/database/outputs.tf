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
