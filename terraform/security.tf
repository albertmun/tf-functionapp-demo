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

# Function App 1 - Storage Blob Data Contributor on Storage Account 1 (for runtime)
resource "azurerm_role_assignment" "func_app_1_storage_1_blob" {
  scope                            = azurerm_storage_account.public_storage.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_windows_function_app.func_app_1.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# Function App 1 - Storage Account Contributor (for function runtime operations)
resource "azurerm_role_assignment" "func_app_1_storage_1_account" {
  scope                            = azurerm_storage_account.public_storage.id
  role_definition_name             = "Storage Account Contributor"
  principal_id                     = azurerm_windows_function_app.func_app_1.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# Function App 2 - Storage Blob Data Contributor on Storage Account 1 (for runtime)
resource "azurerm_role_assignment" "func_app_2_storage_1_blob" {
  scope                            = azurerm_storage_account.public_storage.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_windows_function_app.func_app_2.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# Function App 2 - Storage Account Contributor (for function runtime operations)
resource "azurerm_role_assignment" "func_app_2_storage_1_account" {
  scope                            = azurerm_storage_account.public_storage.id
  role_definition_name             = "Storage Account Contributor"
  principal_id                     = azurerm_windows_function_app.func_app_2.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

# Function App 2 - Storage Blob Data Contributor on Storage Account 2 (private storage)
resource "azurerm_role_assignment" "func_app_2_storage_2" {
  scope                            = azurerm_storage_account.private_storage.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_windows_function_app.func_app_2.identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
# }