###############################################################
# TEST: Naming Module
# Description: Demonstrates the Naming module functionality
# Usage: terraform plan -var-file="test.tfvars"
###############################################################

###############################################################
# PROVIDER CONFIGURATION
###############################################################
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70.0"
    }
  }
}

provider "azurerm" {
  features {}
}

###############################################################
# MODULE: Naming (Test Instance)
###############################################################
module "naming_test" {
  source = "../modules/Naming"

  # Basic naming components
  prefix      = "neko"
  suffix      = "01"
  environment = "lab"
  region      = "weu"
  
  # Azure naming module configuration
  unique_seed   = "test123"
  unique_length = 4
  
  # Generate multiple name variations
  name_suffixes = [
    "hub",
    "mgmt",
    "untrust",
    "trust",
    "spoke-app",
    "spoke-data"
  ]
  
  # Add some custom types for testing
  custom_resource_types = {
    "test_custom_app"    = "testapp"
    "test_custom_db"     = "testdb"
    "test_custom_cache"  = "testcache"
  }
  
  # Enable validation
  validate_names = true
  
  # Use Azure naming module
  use_azure_naming_module = true
}

###############################################################
# OUTPUTS: Display Generated Names
###############################################################

# Azure standard resource names
output "test_azure_resource_group" {
  description = "Azure naming module - Resource Group"
  value       = module.naming_test.resource_group_name
}

output "test_azure_virtual_network" {
  description = "Azure naming module - Virtual Network"
  value       = module.naming_test.virtual_network_name
}

output "test_azure_storage_account" {
  description = "Azure naming module - Storage Account (sanitized)"
  value       = module.naming_test.storage_account_name
}

output "test_azure_key_vault" {
  description = "Azure naming module - Key Vault"
  value       = module.naming_test.key_vault_name
}

# Custom Palo Alto names
output "test_palo_alto_vm" {
  description = "Custom naming - Palo Alto VM Series"
  value       = module.naming_test.palo_alto_names.vm_series
}

output "test_palo_alto_interface" {
  description = "Custom naming - Palo Alto Interface"
  value       = module.naming_test.palo_alto_names.interface
}

output "test_palo_alto_zone" {
  description = "Custom naming - Palo Alto Zone"
  value       = module.naming_test.palo_alto_names.zone
}

# Built names with suffixes
output "test_built_resource_groups" {
  description = "Built names - Resource Groups for all suffixes"
  value       = module.naming_test.built_names.resource_group
}

output "test_built_palo_interfaces" {
  description = "Built names - Palo Alto Interfaces for all suffixes"
  value       = lookup(module.naming_test.built_names, "palo_alto_interface", {})
}

# All custom names
output "test_all_custom_names" {
  description = "All custom resource names"
  value       = module.naming_test.custom_names
}

# Naming components used
output "test_naming_components" {
  description = "Naming components used in generation"
  value       = module.naming_test.naming_components
}

# Storage names (sanitized)
output "test_storage_names" {
  description = "Storage account names (sanitized for Azure requirements)"
  value       = module.naming_test.storage_names
}

###############################################################
# VALIDATION OUTPUT
###############################################################
output "test_validation_result" {
  description = "Validation result"
  value       = module.naming_test.validation_result
}

###############################################################
# EXAMPLE: Using the names in resources
###############################################################

# Example 1: Resource Group
output "example_resource_group_name" {
  description = "Example: How to use for Resource Group"
  value       = "${module.naming_test.resource_group_name}-hub"
}

# Example 2: Virtual Network
output "example_vnet_name" {
  description = "Example: How to use for VNet"
  value       = "${module.naming_test.virtual_network_name}-hub"
}

# Example 3: Palo Alto VM
output "example_palo_vm_name" {
  description = "Example: How to use for Palo Alto VM"
  value       = "${module.naming_test.palo_alto_names.vm_series}-hub"
}

# Example 4: Network Interfaces with built names
output "example_nic_names" {
  description = "Example: How to use built names for NICs"
  value = {
    mgmt    = lookup(module.naming_test.built_names.palo_alto_interface, "mgmt", "N/A")
    untrust = lookup(module.naming_test.built_names.palo_alto_interface, "untrust", "N/A")
    trust   = lookup(module.naming_test.built_names.palo_alto_interface, "trust", "N/A")
  }
}

###############################################################
# DEMONSTRATION: Complete naming for Hub-and-Spoke
###############################################################
output "demo_hub_spoke_naming" {
  description = "Complete Hub-and-Spoke naming example"
  value = {
    hub = {
      resource_group  = lookup(module.naming_test.built_names.resource_group, "hub", "N/A")
      virtual_network = lookup(module.naming_test.built_names.virtual_network, "hub", "N/A")
      palo_alto_vm    = "${module.naming_test.palo_alto_names.vm_series}-hub"
      nsg_mgmt        = "${module.naming_test.network_security_group_name}-mgmt"
      nsg_untrust     = "${module.naming_test.network_security_group_name}-untrust"
      nsg_trust       = "${module.naming_test.network_security_group_name}-trust"
    }
    spoke_app = {
      resource_group  = lookup(module.naming_test.built_names.resource_group, "spoke-app", "N/A")
      virtual_network = lookup(module.naming_test.built_names.virtual_network, "spoke-app", "N/A")
      route_table     = "${module.naming_test.route_table_name}-spoke-app"
    }
    spoke_data = {
      resource_group  = lookup(module.naming_test.built_names.resource_group, "spoke-data", "N/A")
      virtual_network = lookup(module.naming_test.built_names.virtual_network, "spoke-data", "N/A")
      route_table     = "${module.naming_test.route_table_name}-spoke-data"
    }
  }
}

###############################################################
# TEST NOTES
###############################################################
# Run this test with:
# terraform init
# terraform plan
# 
# Expected outputs:
# - Azure standard names: rg-neko-lab-weu-01, vnet-neko-lab-weu-01, etc.
# - Palo Alto names: neko-palofw-lab-weu-01, neko-paloif-lab-weu-01, etc.
# - Built names with suffixes: 
#   - hub: neko-rg-hub-lab-weu-01
#   - mgmt: neko-paloif-mgmt-lab-weu-01
#   - etc.
# - Storage names: nekostlabweu01 (sanitized)
###############################################################
