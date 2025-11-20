# NAT Gateway for VNet internet access
resource "azurerm_public_ip" "nat_gateway" {
  name                = "pip-nat-${local.name_prefix}"
  location            = data.azurerm_resource_group.demo.location
  resource_group_name = data.azurerm_resource_group.demo.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_nat_gateway" "demo" {
  name                    = "nat-${local.name_prefix}"
  location                = data.azurerm_resource_group.demo.location
  resource_group_name     = data.azurerm_resource_group.demo.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = local.common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "demo" {
  nat_gateway_id       = azurerm_nat_gateway.demo.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

# Associate NAT Gateway with Function subnet for internet access
resource "azurerm_subnet_nat_gateway_association" "function_subnet" {
  subnet_id      = azurerm_subnet.function_subnet.id
  nat_gateway_id = azurerm_nat_gateway.demo.id
}