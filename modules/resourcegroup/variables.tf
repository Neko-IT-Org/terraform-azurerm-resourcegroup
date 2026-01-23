###############################################################
# VARIABLE: name
# Type: string (required)
# Description: Resource group name
# Azure constraints:
#   - 1-90 characters
#   - Alphanumerics, _, -, ., ()
#   - Cannot end with a period
# Validation: Regex + length check
# Example: "rg-neko-lab-weu-01"
###############################################################
variable "name" {
  type        = string
  description = "Required. The name of the this resource."

  # Validation compliant with Azure naming rules
  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 90 && can(regex("^[a-zA-Z0-9_().-]+$", var.name)) && !endswith(var.name, ".")
    error_message = <<ERROR_MESSAGE
    The resource group name must meet the following requirements:
    - `Between 1 and 90 characters long.` 
    - `Can only contain Alphanumerics, underscores, parentheses, hyphens, periods.`
    - `Cannot end in a period`
    ERROR_MESSAGE
  }
}

###############################################################
# VARIABLE: location
# Type: string (required)
# Description: Azure region where to deploy the RG
# Examples: "westeurope", "eastus", "francecentral"
# Note: Must be a valid Azure region
###############################################################
variable "location" {
  description = "The location of the resource"
  type        = string
}

###############################################################
# VARIABLE: tags
# Type: map(string) (optional)
# Description: Custom tags to apply to the RG
# Default: {} (empty map)
# Note: Will be merged with the auto-generated "CreatedOn" tag
# Example: { environment = "prod", owner = "team" }
###############################################################
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

###############################################################
# VARIABLE: lock
# Type: object (optional)
# Description: Management lock configuration
# Default: null (no lock)
# Structure:
#   - kind (required): "CanNotDelete" or "ReadOnly"
#   - name (optional): Lock name (auto-generated if null)
# Validation: kind must be CanNotDelete or ReadOnly
# Use Case: Protect critical RGs against deletion
###############################################################
variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:
  
  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  # Validation: kind must be in the allowed list
  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

###############################################################
# VARIABLE: role_assignments
# Type: list(object) (optional)
# Description: RBAC role assignments at RG level
# Default: [] (empty list)
# Structure:
#   - principal_id (required): User/group/SP ID
#   - role_definition_id XOR role_definition_name (one required)
#   - condition, condition_version, description, delegated_... (optional)
# Validation: Exactly one of role_definition_id or role_definition_name
# Example: [{ principal_id = "xxx", role_definition_name = "Reader" }]
###############################################################
variable "role_assignments" {
  description = <<EOT
Optional role assignments at RG scope.
Example:
[
  { principal_id = "00000000-0000-0000-0000-000000000000", role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/<role-guid>" }
]
EOT
  type = list(object({
    principal_id                           = string
    role_definition_id                     = optional(string)
    role_definition_name                   = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    description                            = optional(string)
    delegated_managed_identity_resource_id = optional(string)
  }))
  default = []

  # Validation: Exactly one of role_definition_id OR role_definition_name
  validation {
    condition = alltrue([
      for assignment in var.role_assignments :
      (
        (!isnull(assignment.role_definition_id) && isnull(assignment.role_definition_name)) ||
        (isnull(assignment.role_definition_id) && !isnull(assignment.role_definition_name))
      )
    ])

    error_message = <<EOT
Each role assignment must specify exactly one of `role_definition_id` or `role_definition_name`. Remove the extra attribute if both are provided, or supply the missing one.
EOT
  }
}

###############################################################
# VARIABLE: enable_telemetry
# Type: bool (optional)
# Default: false
# Description: Enable diagnostic settings for telemetry
# Use Case: Send logs and metrics to Log Analytics, Storage Account, or Event Hub
# Note: Requires telemetry_settings to be configured if enabled
###############################################################
variable "enable_telemetry" {
  description = "Enable diagnostic settings for telemetry"
  type        = bool
  default     = false
}

###############################################################
# VARIABLE: telemetry_settings
# Type: object (optional, nullable)
# Default: null
# Description: Diagnostic settings configuration for telemetry
# Structure:
#   - log_analytics_workspace_id (optional): Log Analytics Workspace ID
#   - storage_account_id (optional): Storage Account ID for archival
#   - event_hub_authorization_rule_id (optional): Event Hub authorization rule ID
#   - event_hub_name (optional): Event Hub name
#   - log_categories (optional): List of log categories to enable (default: ["Administrative"])
#   - metric_categories (optional): List of metric categories to enable (default: ["AllMetrics"])
# Note: At least one destination (workspace/storage/event hub) must be specified if enable_telemetry is true
###############################################################
variable "telemetry_settings" {
  description = "Diagnostic settings configuration for telemetry"
  type = object({
    log_analytics_workspace_id      = optional(string)
    storage_account_id              = optional(string)
    event_hub_authorization_rule_id = optional(string)
    event_hub_name                  = optional(string)
    log_categories                  = optional(list(string), ["Administrative"])
    metric_categories               = optional(list(string), ["AllMetrics"])
  })
  default  = null
  nullable = true

  ###############################################################
  # VALIDATION: At least one destination required
  # Description: If enable_telemetry is true, at least one destination must be configured
  ###############################################################
  validation {
    condition = var.telemetry_settings == null || (
      var.telemetry_settings.log_analytics_workspace_id != null ||
      var.telemetry_settings.storage_account_id != null ||
      var.telemetry_settings.event_hub_authorization_rule_id != null
    )
    error_message = "If telemetry_settings is provided, at least one destination (log_analytics_workspace_id, storage_account_id, or event_hub_authorization_rule_id) must be specified."
  }
}
