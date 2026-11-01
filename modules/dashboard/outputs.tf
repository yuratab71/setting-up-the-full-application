output "sns_arn" {
  type  = string
  value = aws_sns_topic.this.arn
}
