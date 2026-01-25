###############################################################
# MODULE: Azure Naming (Official)
# Description: Uses the official Azure naming module for standard resources
# Source: Azure/naming/azurerm
# Documentation: https://registry.terraform.io/modules/Azure/naming/azurerm
###############################################################
module "azure_naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.0"

  # Pass through prefix and suffix from our module
  prefix = var.prefix
  suffix = var.suffix

  # Unique seed for generating unique names
  unique-seed = var.unique_seed

  # Unique length for generated suffixes
  unique-length = var.unique_length
}

###############################################################
# LOCAL: Custom Naming Logic
# Description: Builds custom names for resources not in Azure module
# Format: {prefix}-{resource_type}-{name}-{environment}-{region}-{suffix}
# Example: neko-palofw-trust-prod-weu-01
###############################################################
locals {
  # Base naming components
  prefix      = var.prefix != null && var.prefix != "" ? "${var.prefix}-" : ""
  suffix      = var.suffix != null && var.suffix != "" ? "-${var.suffix}" : ""
  environment = var.environment != null && var.environment != "" ? "-${var.environment}" : ""
  region      = var.region != null && var.region != "" ? "-${var.region}" : ""

  # Custom resource naming map
  # Format: resource_type = "short_name"
  # Example: palo_alto_vm_series = "palofw"
  custom_resource_types = merge(
    {
      # Palo Alto Networks Resources
      palo_alto_vm_series          = "palofw"
      palo_alto_management_profile = "paloprf"
      palo_alto_interface          = "paloif"
      palo_alto_zone               = "palozone"
      palo_alto_virtual_router     = "palovr"
      palo_alto_security_policy    = "palopol"
      
      # Azure Resources not in official module
      route_table_route            = "route"
      nsg_security_rule            = "nsgr"
      subnet_nsg_association       = "snsga"
      subnet_rt_association        = "srta"
      
      # Custom application resources
      custom_vm                    = "vm"
      custom_nic                   = "nic"
      custom_disk                  = "disk"
      custom_pip                   = "pip"
      
      # Add more custom types as needed
    },
    var.custom_resource_types # Allow override/extension via variable
  )

  # Generate custom names for each resource type
  # Result: { "palo_alto_vm_series" = "neko-palofw-{name}-prod-weu-01", ... }
  custom_names = {
    for type, short_name in local.custom_resource_types :
    type => "${local.prefix}${short_name}${local.environment}${local.region}${local.suffix}"
  }
}

###############################################################
# LOCAL: Name Sanitization Functions
# Description: Helper functions to sanitize names for Azure resources
# Use Cases:
#   - Remove invalid characters
#   - Enforce length limits
#   - Convert to lowercase/uppercase as needed
###############################################################
locals {
  # Function to sanitize general resource names
  # Rules: lowercase, alphanumeric + hyphens, max 63 chars
  sanitize_name = {
    for k, v in local.custom_names :
    k => lower(substr(replace(v, "/[^a-zA-Z0-9-]/", ""), 0, 63))
  }

  # Function to sanitize storage account names
  # Rules: lowercase, alphanumeric only, 3-24 chars
  sanitize_storage_name = {
    for k, v in local.custom_names :
    k => lower(substr(replace(v, "/[^a-zA-Z0-9]/", ""), 0, 24))
  }
}

###############################################################
# LOCAL: Final Naming Output
# Description: Combines Azure module names with custom names
# Structure: All names accessible via single map
###############################################################
locals {
  # Merge all naming sources
  all_names = merge(
    # Azure official module names
    {
      resource_group              = module.azure_naming.resource_group.name
      virtual_network             = module.azure_naming.virtual_network.name
      subnet                      = module.azure_naming.subnet.name
      network_security_group      = module.azure_naming.network_security_group.name
      route_table                 = module.azure_naming.route_table.name
      public_ip                   = module.azure_naming.public_ip.name
      network_interface           = module.azure_naming.network_interface.name
      virtual_machine             = module.azure_naming.virtual_machine.name
      storage_account             = module.azure_naming.storage_account.name
      key_vault                   = module.azure_naming.key_vault.name
      log_analytics_workspace     = module.azure_naming.log_analytics_workspace.name
      availability_set            = module.azure_naming.availability_set.name
      managed_disk                = module.azure_naming.managed_disk.name
      load_balancer               = module.azure_naming.load_balancer.name
      application_gateway         = module.azure_naming.application_gateway.name
      # Add more as needed from module.azure_naming
    },
    # Custom resource names
    local.sanitize_name
  )

  # Special case: storage account names (different rules)
  storage_names = {
    for k, v in local.custom_names :
    k => local.sanitize_storage_name[k]
    if can(regex("storage|st|sa", k))
  }
}

###############################################################
# HELPER FUNCTIONS
# Description: Functions to build specific resource names
###############################################################
locals {
  # Function to build a complete resource name
  # Usage: local.build_name("palo_alto_vm_series", "hub-trust")
  # Result: "neko-palofw-hub-trust-prod-weu-01"
  build_name = {
    for type in keys(local.all_names) :
    type => {
      for name_suffix in var.name_suffixes :
      name_suffix => "${local.all_names[type]}-${name_suffix}"
    }
  }
}

###############################################################
# VALIDATION
# Description: Validate naming inputs
###############################################################
resource "null_resource" "validation" {
  count = var.validate_names ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.prefix == null || can(regex("^[a-zA-Z0-9-]+$", var.prefix))
      error_message = "Prefix must contain only alphanumeric characters and hyphens."
    }

    precondition {
      condition     = var.suffix == null || can(regex("^[a-zA-Z0-9-]+$", var.suffix))
      error_message = "Suffix must contain only alphanumeric characters and hyphens."
    }

    precondition {
      condition     = var.environment == null || can(regex("^[a-zA-Z0-9-]+$", var.environment))
      error_message = "Environment must contain only alphanumeric characters and hyphens."
    }

    precondition {
      condition     = var.region == null || can(regex("^[a-zA-Z0-9-]+$", var.region))
      error_message = "Region must contain only alphanumeric characters and hyphens."
    }
  }
}
