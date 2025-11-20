# Local values for consistent tagging and naming

locals {
  common_tags = {
    Environment   = var.environment
    Project       = "fd-terraform-demo"
    ManagedBy     = "terraform"
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
    DeployVersion = var.deploy_version
    Creator       = var.creator
  }

  # Naming convention for resources
  name_prefix = "fd-demo-${var.environment}"

  # Resolve APIM IP: Use APIM resource's public IP if dynamic resolution enabled, otherwise use static IP
  # The APIM resource exposes public_ip_addresses attribute which is more reliable than DNS resolution
  apim_resolved_ip  = var.use_dynamic_apim_ip ? try(azurerm_api_management.apim.public_ip_addresses[0], "") : ""
  apim_effective_ip = local.apim_resolved_ip != "" && local.apim_resolved_ip != null ? local.apim_resolved_ip : var.apim_ip_address

  # Conditional IP restrictions for Function App 2 (empty list when disabled)
  ip_restrictions_func_app_2 = var.enable_function_app_2_restrictions ? [
    {
      ip_address = "${var.my_current_ip}/32"
      name       = "AllowMyCurrentIP"
      priority   = 100
      action     = "Allow"
    },
    {
      ip_address = "${local.apim_effective_ip}/32"
      name       = "AllowAPIMInstance"
      priority   = 110
      action     = "Allow"
    }
  ] : []
}