terraform {
  required_version = ">= 1.15.0"
}

resource "aws_dynamodb_table" "this" {
  name         = "notes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "noteId"

  attribute {
    name = "noteId"
    type = "S"
  }
}
