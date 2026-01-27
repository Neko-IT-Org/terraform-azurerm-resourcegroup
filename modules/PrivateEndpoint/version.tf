###############################################################
# TERRAFORM BLOCK
# Description: Spécifie les versions requises de Terraform et des providers
###############################################################
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.70.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}
