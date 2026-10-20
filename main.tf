terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.58.0"
    }
  }

  required_version = ">= 1.15.0"
}

provider "aws" {
  region = local.region
}

locals {
  domain       = "yuratab.pp.ua"
  region       = "eu-north-1"
  name         = "simple-notes"
  backend_path = "./packages/backend/dist"
  handler      = "app.handler"
  runtime      = "nodejs22.x"
}

module "network" {
  source = "./modules/network"
  domain = local.domain
}

module "dynamodb" {
  source = "./modules/database"
}

/*
 NOTES_TABLE_NAME
 AWS_ENDPOINT_URL
 */
module "lambda_list" {
  source         = "./modules/lambda"
  name           = "lambda-list"
  handler        = local.handler
  filename       = "${local.backend_path}/listNotes/app.js"
  runtime        = local.runtime
  gw_id          = module.network.gw_id
  gw_resource_id = module.network.list_resource_id
  http_method    = "GET"
  permissions    = ["dynamodb:Scan"]
  dynamodb_arn   = module.dynamodb.table_arn
  table_name     = module.dynamodb.table_name
  region         = local.region

  depends_on = [module.network, module.dynamodb]
}

module "lambda_create" {
  source         = "./modules/lambda"
  name           = "lambda-create"
  handler        = local.handler
  filename       = "${local.backend_path}/createNote/app.js"
  runtime        = local.runtime
  gw_id          = module.network.gw_id
  gw_resource_id = module.network.list_resource_id
  http_method    = "POST"
  permissions    = ["dynamodb:PutItem"]
  dynamodb_arn   = module.dynamodb.table_arn
  table_name     = module.dynamodb.table_name
  region         = local.region

  depends_on = [module.network, module.dynamodb]
}

module "lambda_get" {
  source         = "./modules/lambda"
  name           = "lambda-get"
  handler        = local.handler
  filename       = "${local.backend_path}/getNote/app.js"
  runtime        = local.runtime
  gw_id          = module.network.gw_id
  gw_resource_id = module.network.id_resource_id
  http_method    = "GET"
  permissions    = ["dynamodb:GetItem"]
  dynamodb_arn   = module.dynamodb.table_arn
  table_name     = module.dynamodb.table_name
  region         = local.region

  depends_on = [module.network, module.dynamodb]
}

module "lambda_update" {
  source         = "./modules/lambda"
  name           = "lambda-update"
  handler        = local.handler
  filename       = "${local.backend_path}/updateNote/app.js"
  runtime        = local.runtime
  gw_id          = module.network.gw_id
  gw_resource_id = module.network.id_resource_id
  http_method    = "PUT"
  permissions    = ["dynamodb:UpdateItem"]
  dynamodb_arn   = module.dynamodb.table_arn
  table_name     = module.dynamodb.table_name
  region         = local.region

  depends_on = [module.network, module.dynamodb]
}

module "lambda_delete" {
  source         = "./modules/lambda"
  name           = "lambda-delete"
  handler        = local.handler
  filename       = "${local.backend_path}/deleteNote/app.js"
  runtime        = local.runtime
  gw_id          = module.network.gw_id
  gw_resource_id = module.network.id_resource_id
  http_method    = "DELETE"
  permissions    = ["dynamodb:DeleteItem"]
  dynamodb_arn   = module.dynamodb.table_arn
  table_name     = module.dynamodb.table_name
  region         = local.region

  depends_on = [module.network, module.dynamodb]
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = module.network.gw_id

  triggers = {
    redeployment = sha1(jsonencode([
      module.network.list_resource_id,
      module.network.id_resource_id,
      module.lambda_list.method_id,
      module.lambda_list.integration_id,
      module.lambda_create.method_id,
      module.lambda_create.integration_id,
      module.lambda_get.method_id,
      module.lambda_get.integration_id,
      module.lambda_update.method_id,
      module.lambda_update.integration_id,
      module.lambda_delete.method_id,
      module.lambda_delete.integration_id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = module.network.gw_id
  stage_name    = "main"
}

/*
VITE_FILES_BUCKET - bucket name
VITE_GATEWAY_URL
VITE_IDENTITY_POOL_ID
VITE_REGION=
VITE_BASE_URL=/cloudfront/{cloudfront_distribution_id}
 */
module "frontend" {
  source         = "./modules/frontend"
  domain         = local.domain
  region         = local.region
  path           = "${path.module}/packages/frontend/dist"
  env_path       = "${path.module}/packages/frontend"
  hosted_zone_id = module.network.hosted_zone_id
  gw_id          = module.network.gw_id
  gw_url         = aws_api_gateway_stage.this.invoke_url

  depends_on = [module.network, module.dynamodb, module.lambda_create, module.lambda_delete, module.lambda_get, module.lambda_list, module.lambda_update]
}

output "rest_api_url" {
  type  = string
  value = aws_api_gateway_stage.this.invoke_url
}

output "nameservers" {
  type        = list(string)
  description = "Hosted zone nameservers"
  value       = module.network.nameservers
}
