# Backend configuration for Terraform state
# This should be created manually or via a separate bootstrap process

terraform {
  backend "azurerm" {
    resource_group_name  = "tf-demo"
    storage_account_name = "snefftfdemo55"
    container_name       = "tfstate"
    key                  = "fd-demo.terraform.tfstate"
    use_oidc             = true
  }
}