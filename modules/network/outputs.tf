output "nameservers" {
  type  = list(string)
  value = aws_route53_zone.this.name_servers
}

output "hosted_zone_id" {
  type  = string
  value = aws_route53_zone.this.id
}

output "gw_id" {
  type  = string
  value = aws_api_gateway_rest_api.this.id
}

output "list_resource_id" {
  type  = string
  value = aws_api_gateway_resource.list.id
}

output "id_resource_id" {
  type  = string
  value = aws_api_gateway_resource.id.id
}

output "options_method_id" {
  type  = string
  value = aws_api_gateway_method.options.id
}

output "options_integration_id" {
  type  = string
  value = aws_api_gateway_integration.options.id
}


