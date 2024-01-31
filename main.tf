terraform {
  required_version = ">=1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.71.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">=1.9.0"
    }
  }
}

provider "azurerm" {
  features {

  }
}

provider "azapi" {

}


data "azurerm_client_config" "current" {}

locals {
  prefix = "lab"
}

resource "random_string" "main" {
    length  = 8
    special = false
    upper   = false
    numeric = true
  
}

resource "random_string" "uksstorage" {
    length  = 8
    special = false
    upper   = false
    numeric = true
  
}

resource "azurerm_storage_account" "uksstorage" {
    name = "${local.prefix}${random_string.uksstorage.result}"
    resource_group_name = azurerm_resource_group.main.name
    location = "uksouth"
    account_tier = "Standard"
    account_replication_type = "LRS"
    account_kind = "StorageV2"
    tags = azurerm_resource_group.main.tags
}
