# Networking resources for the demo environment

# Virtual Network for private connectivity
resource "azurerm_virtual_network" "demo" {
  name                = "vnet-${local.name_prefix}"
  address_space       = var.vnet_address_space
  location            = data.azurerm_resource_group.demo.location
  resource_group_name = data.azurerm_resource_group.demo.name

  tags = local.common_tags
}

# Subnet for Function App VNet integration
resource "azurerm_subnet" "function_subnet" {
  name                 = "snet-functions"
  resource_group_name  = data.azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = [var.function_subnet_address_prefix]

  # Delegate subnet to Microsoft.Web/serverFarms for Function App integration
  delegation {
    name = "function-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = "snet-private-endpoints"
  resource_group_name  = data.azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = [var.private_endpoint_subnet_address_prefix]
}

# Private DNS Zone for Storage Account
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.demo.name

  tags = local.common_tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_vnet_link" {
  name                  = "storage-blob-vnet-link"
  resource_group_name   = data.azurerm_resource_group.demo.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.demo.id
  registration_enabled  = false

  tags = local.common_tags
}

# Private Endpoint for Storage Account 2
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-${azurerm_storage_account.private_storage.name}"
  location            = data.azurerm_resource_group.demo.location
  resource_group_name = data.azurerm_resource_group.demo.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "storage-private-connection"
    private_connection_resource_id = azurerm_storage_account.private_storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob.id]
  }

  tags = local.common_tags
}

# VNet Integration for Function App 2 - Re-enabled with NAT Gateway for internet access
resource "azurerm_app_service_virtual_network_swift_connection" "func_app_2_vnet_integration" {
  app_service_id = azurerm_windows_function_app.func_app_2.id
  subnet_id      = azurerm_subnet.function_subnet.id
}
