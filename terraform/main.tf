module "components" {
  source = "git::https://github.com/aws-devopsprocloud/terraform-components-module.git?ref=main"
  for_each = var.components
  component = each.key 
  environment = var.environment
  rule_priority = each.value.rule_priority
  domain_name = var.domain_name
  zone_id = var.zone_id
  app_version = var.app_version
}