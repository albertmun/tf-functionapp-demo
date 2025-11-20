# Variables for Azure Function Apps and Storage Demo

variable "environment" {
  description = "Environment name (e.g., test, dev, prod)"
  type        = string
  default     = "test"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "location_short" {
  description = "Short name for Azure region"
  type        = string
  default     = "eus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "tf-demo"
}

variable "storage_account_1_name" {
  description = "Name of the first storage account (public with IP restrictions)"
  type        = string
  default     = "stgsnefffds1"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_1_name))
    error_message = "Storage account name must be between 3 and 24 characters long and contain only lowercase letters and numbers."
  }
}

variable "storage_account_2_name" {
  description = "Name of the second storage account (private with private endpoint)"
  type        = string
  default     = "stgsnefffds2"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_2_name))
    error_message = "Storage account name must be between 3 and 24 characters long and contain only lowercase letters and numbers."
  }
}

variable "my_current_ip" {
  description = "Your current public IP address for testing Function App 2"
  type        = string
  default     = "107.139.218.54"
}

variable "apim_ip_address" {
  description = "IP address of the external APIM instance that needs access to Function App 2"
  type        = string
  default     = "20.112.58.86"
}

variable "enable_function_app_2_restrictions" {
  description = "Enable IP restrictions on Function App 2 (set to false for unrestricted testing)"
  type        = bool
  default     = true
}

variable "function_app_1_name" {
  description = "Name of the first function app"
  type        = string
  default     = "sneff-fd-func-1"
}

variable "function_app_2_name" {
  description = "Name of the second function app"
  type        = string
  default     = "sneff-fd-func-2"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "function_subnet_address_prefix" {
  description = "Address prefix for the function app subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_endpoint_subnet_address_prefix" {
  description = "Address prefix for the private endpoint subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# Generic resource configuration variables (migrated from hardcoded values in main.tf)
variable "account_tier" {
  description = "Tier for the storage accounts"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Replication type for the storage accounts"
  type        = string
  default     = "LRS"
}

variable "service_plan_os_type" {
  description = "OS type for the App Service Plan"
  type        = string
  default     = "Windows"
}

variable "service_plan_sku_name" {
  description = "SKU name for the App Service Plan"
  type        = string
  default     = "S1"
}

variable "powershell_core_version" {
  description = "PowerShell Core version for Function Apps"
  type        = string
  default     = "7.4"
}

variable "deploy_version" {
  description = "Deployment version tag to apply to resources"
  type        = string
  default     = "v1.1"
}

variable "creator" {
  description = "Creator identifier used in resource tags"
  type        = string
  default     = "github-actions"
}

# API Management instance variables (import existing APIM)
variable "apim_name" {
  description = "Name of the existing API Management instance"
  type        = string
  default     = "apim-fd-public-test2"
}

variable "apim_location" {
  description = "Azure region of the API Management instance (can differ from other resources)"
  type        = string
  default     = "westus2"
}

variable "apim_sku_name" {
  description = "SKU name for API Management (e.g., Developer_1, Consumption_0, Premium_1)"
  type        = string
  default     = "Developer_1"
}

variable "apim_publisher_email" {
  description = "Publisher email for API Management"
  type        = string
  default     = "shane.neff@outlook.com"
}

variable "apim_publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "microsoft"
}

variable "use_dynamic_apim_ip" {
  description = "Resolve APIM hostname to current public IP during plan/apply (true) or use static apim_ip_address value (false)."
  type        = bool
  default     = true
}