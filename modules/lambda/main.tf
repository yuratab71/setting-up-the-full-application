terraform {
  required_version = ">= 1.15.0"
}

// ==============================
// POLICIES
// ==============================
resource "aws_iam_role" "this" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "this" {
  name = var.name
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = var.permissions
      Resource = var.dynamodb_arn
    }]
  })
}

data "aws_caller_identity" "this" {}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.this.account_id}:${var.gw_id}/*/*/*"
}

// ==============================
// LAMBDA
// ==============================
data "archive_file" "this" {
  type        = "zip"
  source_file = var.filename
  output_path = "${var.filename}.zip"
}

resource "aws_lambda_alias" "this" {
  name             = "${var.name}-alias"
  description      = "Function ${var.name}"
  function_name    = aws_lambda_function.this.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_function" "this" {
  function_name = var.name
  role          = aws_iam_role.this.arn
  handler       = var.handler
  filename      = data.archive_file.this.output_path
  runtime       = var.runtime

  source_code_hash = data.archive_file.this.output_base64sha256

  environment {
    variables = {
      NOTES_TABLE_NAME = var.table_name
      AWS_ENDPOINT_URL = "https://dynamodb.${var.region}.amazonaws.com"
    }
  }
}

// ==============================
// API GW INTERGRATION
// ==============================
resource "aws_api_gateway_method" "this" {
  rest_api_id   = var.gw_id
  resource_id   = var.gw_resource_id
  http_method   = var.http_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id = var.gw_id
  resource_id = var.gw_resource_id
  http_method = aws_api_gateway_method.this.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this.invoke_arn
}
