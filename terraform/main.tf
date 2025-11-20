# Azure Function Apps and Storage Demo Environment
# This configuration demonstrates two different storage access patterns:
# 1. Function App with IP-based access to Storage Account
# 2. Function App with VNet integration and private endpoint access to Storage Account

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.1"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

# Data sources for current client configuration
data "azurerm_client_config" "current" {}

# Use existing resource group
data "azurerm_resource_group" "demo" {
  name = var.resource_group_name
}

# Storage Account 1 - Public with IP restrictions
resource "azurerm_storage_account" "public_storage" {
  name                     = var.storage_account_1_name
  resource_group_name      = data.azurerm_resource_group.demo.name
  location                 = data.azurerm_resource_group.demo.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  # Enable public access - network restrictions managed by separate resource
  public_network_access_enabled = true

  # Disable shared key access to enforce Azure AD authentication
  shared_access_key_enabled = false

  # Note: Network rules managed by azurerm_storage_account_network_rules in security.tf

  tags = local.common_tags
}

# Storage Account 2 - Private with private endpoint
resource "azurerm_storage_account" "private_storage" {
  name                     = var.storage_account_2_name
  resource_group_name      = data.azurerm_resource_group.demo.name
  location                 = data.azurerm_resource_group.demo.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type

  # Disable public access - only private endpoint access
  public_network_access_enabled = false

  # Disable shared key access to enforce Azure AD authentication
  shared_access_key_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = local.common_tags
}

# App Service Plan for Function Apps (S1 SKU as requested)
resource "azurerm_service_plan" "demo" {
  name                = "plan-${var.environment}-${var.location_short}"
  resource_group_name = data.azurerm_resource_group.demo.name
  location            = data.azurerm_resource_group.demo.location
  os_type             = var.service_plan_os_type
  sku_name            = var.service_plan_sku_name

  tags = local.common_tags
}

# Function App 1 - Will use IP restrictions to access Storage Account 1
resource "azurerm_windows_function_app" "func_app_1" {
  name                = var.function_app_1_name
  resource_group_name = data.azurerm_resource_group.demo.name
  location            = data.azurerm_resource_group.demo.location

  storage_account_name          = azurerm_storage_account.public_storage.name
  storage_uses_managed_identity = true
  service_plan_id               = azurerm_service_plan.demo.id
  https_only                    = true

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      powershell_core_version = var.powershell_core_version
    }

    # Enable CORS for Azure Portal testing
    cors {
      allowed_origins = [
        "https://portal.azure.com",
        "https://ms.portal.azure.com"
      ]
      support_credentials = true
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"         = "powershell"
    "WEBSITE_RUN_FROM_PACKAGE"         = "1"
    "STORAGE_ACCOUNT_1_NAME"           = azurerm_storage_account.public_storage.name
    "STORAGE_ACCOUNT_1_ENDPOINT"       = azurerm_storage_account.public_storage.primary_blob_endpoint
    "AzureWebJobsStorage__accountName" = azurerm_storage_account.public_storage.name
  }

  tags = local.common_tags
}

# Function App 2 - Will use VNet integration and private endpoint
resource "azurerm_windows_function_app" "func_app_2" {
  name                = var.function_app_2_name
  resource_group_name = data.azurerm_resource_group.demo.name
  location            = data.azurerm_resource_group.demo.location

  storage_account_name          = azurerm_storage_account.public_storage.name # Uses public storage for function runtime
  storage_uses_managed_identity = true
  service_plan_id               = azurerm_service_plan.demo.id
  https_only                    = true

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      powershell_core_version = var.powershell_core_version
    }
    vnet_route_all_enabled = true

    # Enable CORS for Azure Portal testing
    cors {
      allowed_origins = [
        "https://portal.azure.com",
        "https://ms.portal.azure.com"
      ]
      support_credentials = true
    }

    # Conditional IP restrictions (driven by enable_function_app_2_restrictions)
    dynamic "ip_restriction" {
      for_each = local.ip_restrictions_func_app_2
      content {
        ip_address = ip_restriction.value.ip_address
        name       = ip_restriction.value.name
        priority   = ip_restriction.value.priority
        action     = ip_restriction.value.action
      }
    }

    ip_restriction_default_action = var.enable_function_app_2_restrictions ? "Deny" : "Allow"
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"         = "powershell"
    "WEBSITE_RUN_FROM_PACKAGE"         = "1"
    "STORAGE_ACCOUNT_2_NAME"           = azurerm_storage_account.private_storage.name
    "STORAGE_ACCOUNT_2_ENDPOINT"       = azurerm_storage_account.private_storage.primary_blob_endpoint
    "WEBSITE_VNET_ROUTE_ALL"           = "1"
    "AzureWebJobsStorage__accountName" = azurerm_storage_account.public_storage.name
  }

  tags = local.common_tags
}

# Existing API Management instance (to be imported into state)
resource "azurerm_api_management" "apim" {
  name                          = var.apim_name
  location                      = var.apim_location
  resource_group_name           = data.azurerm_resource_group.demo.name
  publisher_email               = var.apim_publisher_email
  publisher_name                = var.apim_publisher_name
  sku_name                      = var.apim_sku_name
  public_network_access_enabled = true

  tags = local.common_tags
}

# API in APIM for Function App 2
resource "azurerm_api_management_api" "func_app_2_api" {
  name                = "func-app-2-api"
  resource_group_name = data.azurerm_resource_group.demo.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Function App 2 API"
  path                = "funcapp2"
  protocols           = ["https"]
  service_url         = "https://${azurerm_windows_function_app.func_app_2.default_hostname}/api"

  description = "API for accessing Function App 2 functions through APIM"

  depends_on = [
    azurerm_api_management.apim,
    azurerm_windows_function_app.func_app_2
  ]
}

# Backend configuration for Function App 2
resource "azurerm_api_management_backend" "func_app_2_backend" {
  name                = "func-app-2-backend"
  resource_group_name = data.azurerm_resource_group.demo.name
  api_management_name = azurerm_api_management.apim.name
  protocol            = "http"
  url                 = "https://${azurerm_windows_function_app.func_app_2.default_hostname}/api"
  description         = "Backend for Function App 2"

  depends_on = [
    azurerm_api_management.apim,
    azurerm_windows_function_app.func_app_2
  ]
}

# HealthCheck Operation
resource "azurerm_api_management_api_operation" "healthcheck" {
  operation_id        = "healthcheck"
  api_name            = azurerm_api_management_api.func_app_2_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.demo.name
  display_name        = "Health Check"
  method              = "GET"
  url_template        = "/HealthCheck"
  description         = "Check the health status of Function App 2"

  response {
    status_code = 200
    description = "Success"
  }
}

# NetworkDiagnostics Operation
resource "azurerm_api_management_api_operation" "network_diagnostics" {
  operation_id        = "network-diagnostics"
  api_name            = azurerm_api_management_api.func_app_2_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.demo.name
  display_name        = "Network Diagnostics"
  method              = "GET"
  url_template        = "/NetworkDiagnostics"
  description         = "Run network diagnostics from Function App 2"

  response {
    status_code = 200
    description = "Success"
  }
}

# SimpleTest Operation
resource "azurerm_api_management_api_operation" "simple_test" {
  operation_id        = "simple-test"
  api_name            = azurerm_api_management_api.func_app_2_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.demo.name
  display_name        = "Simple Test"
  method              = "GET"
  url_template        = "/SimpleTest"
  description         = "Simple test function"

  response {
    status_code = 200
    description = "Success"
  }
}

# TestPrivateStorageConnection Operation
resource "azurerm_api_management_api_operation" "test_private_storage" {
  operation_id        = "test-private-storage"
  api_name            = azurerm_api_management_api.func_app_2_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.demo.name
  display_name        = "Test Private Storage Connection"
  method              = "GET"
  url_template        = "/TestPrivateStorageConnection"
  description         = "Test connection to private storage account"

  response {
    status_code = 200
    description = "Success"
  }
}

# TestStorageSimple Operation
resource "azurerm_api_management_api_operation" "test_storage_simple" {
  operation_id        = "test-storage-simple"
  api_name            = azurerm_api_management_api.func_app_2_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.demo.name
  display_name        = "Test Storage Simple"
  method              = "GET"
  url_template        = "/TestStorageSimple"
  description         = "Simple storage test"

  response {
    status_code = 200
    description = "Success"
  }
}

# API Policy to set backend and handle authentication
resource "azurerm_api_management_api_policy" "func_app_2_policy" {
  api_name            = azurerm_api_management_api.func_app_2_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.demo.name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <set-backend-service backend-id="${azurerm_api_management_backend.func_app_2_backend.name}" />
    <cors allow-credentials="true">
      <allowed-origins>
        <origin>https://portal.azure.com</origin>
        <origin>https://ms.portal.azure.com</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
      <expose-headers>
        <header>*</header>
      </expose-headers>
    </cors>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML

  depends_on = [
    azurerm_api_management_api.func_app_2_api,
    azurerm_api_management_backend.func_app_2_backend
  ]
}

