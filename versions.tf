terraform {
  required_version = ">= 1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.31.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "> 3.5.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.6.0"
    }
  }
}
