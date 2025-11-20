# Security configurations for storage access

# Apply IP restrictions to Storage Account 1 using Function App's outbound IPs
resource "azurerm_storage_account_network_rules" "storage_1_ip_restrictions" {
  storage_account_id = azurerm_storage_account.public_storage.id

  default_action = "Deny"
  bypass         = ["AzureServices"]

  # Allow all possible outbound IPs from Function App 1
  ip_rules = split(",", azurerm_windows_function_app.func_app_1.possible_outbound_ip_addresses)

  # Ensure Function App is created first
  depends_on = [azurerm_windows_function_app.func_app_1]
}

# Role assignments for Function App managed identities
# Temporarily commented out - will add these via Azure CLI after infrastructure deployment
# to work around Terraform dependency issues with managed identity creation

# Function App 1 - Storage Blob Data Contributor on Storage Account 1
# resource "azurerm_role_assignment" "func_app_1_storage_1" {
#   scope                = azurerm_storage_account.public_storage.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_windows_function_app.func_app_1.identity[0].principal_id
#   principal_type       = "ServicePrincipal"
# }

# Function App 2 - Storage Blob Data Contributor on Storage Account 2  
# resource "azurerm_role_assignment" "func_app_2_storage_2" {
#   scope                = azurerm_storage_account.private_storage.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_windows_function_app.func_app_2.identity[0].principal_id
#   principal_type       = "ServicePrincipal"
# }

# Optional: Cross-access for testing (Function App 1 can also access Storage Account 2)
# resource "azurerm_role_assignment" "func_app_1_storage_2" {
#   scope                = azurerm_storage_account.private_storage.id
#   role_definition_name = "Storage Blob Data Reader"
#   principal_id         = azurerm_windows_function_app.func_app_1.identity[0].principal_id
#   principal_type       = "ServicePrincipal"
# }

# Optional: Cross-access for testing (Function App 2 can also access Storage Account 1)
# resource "azurerm_role_assignment" "func_app_2_storage_1" {
#   scope                = azurerm_storage_account.public_storage.id
#   role_definition_name = "Storage Blob Data Reader"  
#   principal_id         = azurerm_windows_function_app.func_app_2.identity[0].principal_id
#   principal_type       = "ServicePrincipal"
# }