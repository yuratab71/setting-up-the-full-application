output "files_bucket" {
  type  = string
  value = aws_s3_bucket.files.bucket
}

output "identity_pool_id" {
  type  = string
  value = aws_cognito_identity_pool.this.id
}

output "cloudfront_id" {
  type  = string
  value = aws_cloudfront_distribution.this.id
}
