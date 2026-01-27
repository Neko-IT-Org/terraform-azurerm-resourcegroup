###############################################################
# VARIABLE: keys
# Type: map(object) (required)
# Description: Map of Key Vault keys to create
# Structure:
#   - name (required): Key name
#   - key_type (required): RSA, EC, RSA-HSM, EC-HSM
#   - key_vault_id (required): Full Key Vault resource ID
#   - key_size (optional): 2048, 3072, 4096 for RSA
#   - curve (optional): P-256, P-384, P-521, P-256K for EC
#   - key_opts (optional): encrypt, decrypt, sign, verify, wrapKey, unwrapKey
#   - not_before_date (optional): ISO 8601 format
#   - expiration_date (optional): ISO 8601 format (default: +2 years)
#   - tags (optional): Key-specific tags
#   - rotation_policy (optional): Rotation configuration
# Validations:
#   - key_type must be valid
#   - key_size must be valid for RSA keys
###############################################################
variable "keys" {
  description = "Map of Key Vault keys to create with their configuration"
  type = map(object({
    name            = string
    key_type        = string
    key_vault_id    = string
    key_size        = optional(number)
    curve           = optional(string)
    key_opts        = optional(list(string), ["encrypt", "decrypt", "wrapKey", "unwrapKey", "sign", "verify"])
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
    rotation_policy = optional(object({
      expire_after         = optional(string)
      notify_before_expiry = optional(string)
      automatic = optional(object({
        time_after_creation = optional(string)
        time_before_expiry  = optional(string)
      }))
    }))
  }))

  ###############################################################
  # VALIDATION: key_type
  # Description: Ensures key_type is valid
  ###############################################################
  validation {
    condition = alltrue([
      for k, v in var.keys :
      contains(["RSA", "EC", "RSA-HSM", "EC-HSM"], v.key_type)
    ])
    error_message = "key_type must be one of: RSA, EC, RSA-HSM, EC-HSM."
  }

  ###############################################################
  # VALIDATION: key_size for RSA
  # Description: If key_type is RSA, key_size must be 2048, 3072, or 4096
  ###############################################################
  validation {
    condition = alltrue([
      for k, v in var.keys :
      !contains(["RSA", "RSA-HSM"], v.key_type) || (
        v.key_size != null && contains([2048, 3072, 4096], v.key_size)
      )
    ])
    error_message = "For RSA keys, key_size must be 2048, 3072, or 4096."
  }

  ###############################################################
  # VALIDATION: curve for EC
  # Description: If key_type is EC, curve must be specified
  ###############################################################
  validation {
    condition = alltrue([
      for k, v in var.keys :
      !contains(["EC", "EC-HSM"], v.key_type) || (
        v.curve != null && contains(["P-256", "P-384", "P-521", "P-256K"], v.curve)
      )
    ])
    error_message = "For EC keys, curve must be one of: P-256, P-384, P-521, P-256K."
  }
}
