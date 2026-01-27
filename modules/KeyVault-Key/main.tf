###############################################################
# RESOURCE: time_static
# Description: Captures timestamp for CreatedOn tag and expiry calculations
###############################################################
resource "time_static" "created_at" {}

###############################################################
# RESOURCE: time_offset
# Description: Calculates default expiry date (2 years from creation)
# Used when expiration_date is not explicitly provided
###############################################################
resource "time_offset" "expiry_plus_2y" {
  base_rfc3339 = time_static.created_at.rfc3339
  offset_years = 2
}

###############################################################
# RESOURCE: azurerm_key_vault_key
# Description: Creates one or more Azure Key Vault keys
# for_each: Iterates over var.keys map
# Supports:
#   - RSA keys (2048, 3072, 4096 bits)
#   - EC keys (P-256, P-384, P-521, P-256K curves)
#   - HSM-backed keys (RSA-HSM, EC-HSM)
#   - Automatic rotation policies
#   - Custom expiration dates
# 
# Key Operations:
#   - encrypt/decrypt: For encryption/decryption operations
#   - sign/verify: For digital signatures
#   - wrapKey/unwrapKey: For key wrapping operations
###############################################################
resource "azurerm_key_vault_key" "this" {
  for_each = var.keys

  name         = each.value.name
  key_vault_id = each.value.key_vault_id

  # Key configuration
  key_type        = each.value.key_type
  key_size        = try(each.value.key_size, null)
  curve           = try(each.value.curve, null)
  key_opts        = try(each.value.key_opts, ["encrypt", "decrypt", "wrapKey", "unwrapKey", "sign", "verify"])
  not_before_date = try(each.value.not_before_date, null)

  # Expiration: Use provided date or default to +2 years
  expiration_date = coalesce(
    try(each.value.expiration_date, null),
    time_offset.expiry_plus_2y.rfc3339
  )

  ###############################################################
  # DYNAMIC BLOCK: rotation_policy
  # Description: Configures automatic key rotation
  # Format: ISO 8601 duration (P1Y = 1 year, P30D = 30 days)
  # Example:
  #   expire_after = "P2Y"              # Expire after 2 years
  #   notify_before_expiry = "P30D"     # Notify 30 days before
  #   time_after_creation = "P1Y"       # Rotate 1 year after creation
  ###############################################################
  dynamic "rotation_policy" {
    for_each = each.value.rotation_policy == null ? [] : [each.value.rotation_policy]
    content {
      expire_after         = try(rotation_policy.value.expire_after, null)
      notify_before_expiry = try(rotation_policy.value.notify_before_expiry, null)

      # Automatic rotation configuration
      dynamic "automatic" {
        for_each = try(rotation_policy.value.automatic, null) == null ? [] : [rotation_policy.value.automatic]
        content {
          time_after_creation = try(automatic.value.time_after_creation, null)
          time_before_expiry  = try(automatic.value.time_before_expiry, null)
        }
      }
    }
  }
}
