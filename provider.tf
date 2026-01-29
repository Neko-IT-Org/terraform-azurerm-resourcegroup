###############################################################
# TERRAFORM CONFIGURATION
# Description: Provider configuration for local development
###############################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
  }
}

###############################################################
# AZURE PROVIDER
###############################################################
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}