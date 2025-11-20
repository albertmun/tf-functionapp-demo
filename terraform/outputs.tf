# Output values for reference

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = data.azurerm_resource_group.demo.name
}

output "storage_account_1_name" {
  description = "Name of the first storage account (public with IP restrictions)"
  value       = azurerm_storage_account.public_storage.name
}

output "storage_account_1_endpoint" {
  description = "Primary blob endpoint of the first storage account"
  value       = azurerm_storage_account.public_storage.primary_blob_endpoint
}

output "storage_account_2_name" {
  description = "Name of the second storage account (private with private endpoint)"
  value       = azurerm_storage_account.private_storage.name
}

output "storage_account_2_endpoint" {
  description = "Primary blob endpoint of the second storage account"
  value       = azurerm_storage_account.private_storage.primary_blob_endpoint
}

output "function_app_1_name" {
  description = "Name of the first function app"
  value       = azurerm_windows_function_app.func_app_1.name
}

output "function_app_1_url" {
  description = "Default URL of the first function app"
  value       = azurerm_windows_function_app.func_app_1.default_hostname
}

output "function_app_1_outbound_ips" {
  description = "Outbound IP addresses of the first function app"
  value       = azurerm_windows_function_app.func_app_1.outbound_ip_addresses
}

output "function_app_1_possible_outbound_ips" {
  description = "Possible outbound IP addresses of the first function app"
  value       = azurerm_windows_function_app.func_app_1.possible_outbound_ip_addresses
}

output "function_app_2_name" {
  description = "Name of the second function app"
  value       = azurerm_windows_function_app.func_app_2.name
}

output "function_app_2_url" {
  description = "Default URL of the second function app"
  value       = azurerm_windows_function_app.func_app_2.default_hostname
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.demo.name
}

output "private_endpoint_ip" {
  description = "Private IP address of the storage account private endpoint"
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
}

output "function_app_2_restrictions_enabled" {
  description = "Whether IP restrictions are enabled on Function App 2"
  value       = var.enable_function_app_2_restrictions
}

output "function_app_2_allowed_ips" {
  description = "IP addresses allowed to access Function App 2 (when restrictions are enabled)"
  value = var.enable_function_app_2_restrictions ? [
    var.my_current_ip,
    local.apim_effective_ip != "" ? local.apim_effective_ip : "Not resolved"
  ] : ["All IPs allowed (no restrictions)"]
}

output "apim_effective_ip" {
  description = "Resolved (or static fallback) APIM public IP used for Function App 2 restrictions"
  value       = local.apim_effective_ip
}

output "function_app_2_ip_restrictions" {
  description = "Full restriction objects applied to Function App 2"
  value       = local.ip_restrictions_func_app_2
}

output "apim_api_url" {
  description = "Base URL for accessing Function App 2 through APIM"
  value       = "https://${azurerm_api_management.apim.gateway_url}/funcapp2"
}

output "apim_api_endpoints" {
  description = "Full URLs for each Function App 2 endpoint via APIM"
  value = {
    healthcheck             = "https://${azurerm_api_management.apim.gateway_url}/funcapp2/HealthCheck"
    network_diagnostics     = "https://${azurerm_api_management.apim.gateway_url}/funcapp2/NetworkDiagnostics"
    simple_test            = "https://${azurerm_api_management.apim.gateway_url}/funcapp2/SimpleTest"
    test_private_storage   = "https://${azurerm_api_management.apim.gateway_url}/funcapp2/TestPrivateStorageConnection"
    test_storage_simple    = "https://${azurerm_api_management.apim.gateway_url}/funcapp2/TestStorageSimple"
  }
}
