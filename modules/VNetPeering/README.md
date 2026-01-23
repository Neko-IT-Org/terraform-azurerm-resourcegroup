# Azure VNet Peering Terraform Module

This Terraform module creates and manages Azure Virtual Network Peerings with support for bidirectional peering, gateway transit, and Hub-and-Spoke architectures.

## Features

- Creates VNet peerings with configurable settings
- Automatic reverse peering creation (optional)
- Gateway transit support for VPN/ExpressRoute
- NVA forwarded traffic support
- Cross-subscription peering support
- Cross-region (global) peering support
- Comprehensive validation rules
- Detailed outputs for auditing

## Usage

### Simple Peering (One Direction)

```hcl
module "peering_hub_to_spoke" {
  source = "./modules/VNetPeering"

  peerings = [
    {
      name                        = "hub-to-spoke-app"
      source_virtual_network_name = module.vnet_hub.name
      source_resource_group_name  = module.rg_hub.name
      remote_virtual_network_id   = module.vnet_spoke.id
      allow_gateway_transit       = true
      allow_forwarded_traffic     = true
    }
  ]
}
```

### Bidirectional Peering (Hub-and-Spoke)

```hcl
module "peering_hub_spoke" {
  source = "./modules/VNetPeering"

  peerings = [
    {
      name                        = "hub-to-spoke-app"
      source_virtual_network_name = module.vnet_hub.name
      source_resource_group_name  = module.rg_hub.name
      source_virtual_network_id   = module.vnet_hub.id
      remote_virtual_network_id   = module.vnet_spoke.id
      remote_virtual_network_name = module.vnet_spoke.name
      remote_resource_group_name  = module.rg_spoke.name

      # Hub settings (provides gateway)
      allow_gateway_transit   = true
      allow_forwarded_traffic = true

      # Create reverse peering automatically
      create_reverse_peering = true
      reverse_peering_name   = "spoke-app-to-hub"

      # Spoke settings (uses hub's gateway)
      reverse_allow_forwarded_traffic = true
      reverse_use_remote_gateways     = true
    }
  ]
}
```

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | >= 1.5.0  |
| azurerm   | >= 3.70.0 |
| time      | >= 0.9.0  |

## Providers

| Name    | Version   |
| ------- | --------- |
| azurerm | >= 3.70.0 |
| time    | >= 0.9.0  |

## Inputs

| Name                            | Description                              | Type           | Default | Required |
| ------------------------------- | ---------------------------------------- | -------------- | ------- | :------: |
| peerings                        | List of peering configurations           | `list(object)` | n/a     |   yes    |
| default_allow_forwarded_traffic | Default allow_forwarded_traffic value    | `bool`         | `false` |    no    |
| default_allow_gateway_transit   | Default allow_gateway_transit value      | `bool`         | `false` |    no    |
| default_use_remote_gateways     | Default use_remote_gateways value        | `bool`         | `false` |    no    |

### peerings Object Structure

Each peering object supports the following attributes:

#### Required Attributes

| Attribute                     | Description                        | Type     |
| ----------------------------- | ---------------------------------- | -------- |
| name                          | Peering name (unique)              | `string` |
| source_virtual_network_name   | Source VNet name                   | `string` |
| source_resource_group_name    | Source VNet's resource group       | `string` |
| remote_virtual_network_id     | Remote VNet full resource ID       | `string` |

#### Optional Attributes

| Attribute                              | Description                                | Type     | Default |
| -------------------------------------- | ------------------------------------------ | -------- | ------- |
| source_virtual_network_id              | Source VNet ID (required if reverse)       | `string` | `null`  |
| remote_virtual_network_name            | Remote VNet name (required if reverse)     | `string` | `null`  |
| remote_resource_group_name             | Remote VNet RG (required if reverse)       | `string` | `null`  |
| allow_forwarded_traffic                | Allow NVA forwarded traffic                | `bool`   | `false` |
| allow_gateway_transit                  | Allow gateway transit                      | `bool`   | `false` |
| allow_virtual_network_access           | Allow VNet communication                   | `bool`   | `true`  |
| use_remote_gateways                    | Use remote VNet's gateway                  | `bool`   | `false` |
| create_reverse_peering                 | Create reverse peering                     | `bool`   | `false` |
| reverse_peering_name                   | Custom reverse peering name                | `string` | `null`  |
| reverse_allow_forwarded_traffic        | Reverse: allow forwarded traffic           | `bool`   | `false` |
| reverse_allow_gateway_transit          | Reverse: allow gateway transit             | `bool`   | `false` |
| reverse_allow_virtual_network_access   | Reverse: allow VNet access                 | `bool`   | `true`  |
| reverse_use_remote_gateways            | Reverse: use remote gateways               | `bool`   | `false` |

## Outputs

| Name                   | Description                                        |
| ---------------------- | -------------------------------------------------- |
| peering_ids            | Map of forward peering names to their IDs          |
| peering_names          | Map of forward peering keys to names               |
| peering_states         | Map of forward peering names to states             |
| reverse_peering_ids    | Map of reverse peering names to IDs (if created)   |
| reverse_peering_names  | Map of reverse peering keys to names (if created)  |
| reverse_peering_states | Map of reverse peering names to states (if created)|
| all_peering_ids        | Combined map of all peering IDs                    |
| peering_details        | Detailed info about each forward peering           |
| created_timestamp      | Timestamp when peerings were created               |

## Examples

### Hub-and-Spoke with Palo Alto Firewall

```hcl
###############################################################
# Hub-to-Spoke Peering (with Palo Alto NVA)
# Traffic flow: Spoke -> Hub -> Palo Alto -> Internet/On-premises
###############################################################
module "peering_hub_spoke_app" {
  source = "./modules/VNetPeering"

  peerings = [
    {
      # Peering identification
      name                        = "peer-hub-to-spoke-app-weu-01"
      source_virtual_network_name = module.vnet_hub.name
      source_resource_group_name  = module.rg_hub.name
      source_virtual_network_id   = module.vnet_hub.id
      remote_virtual_network_id   = module.vnet_spoke_app.id
      remote_virtual_network_name = module.vnet_spoke_app.name
      remote_resource_group_name  = module.rg_spoke_app.name

      # Hub allows forwarded traffic (from Palo Alto NVA)
      # Hub allows gateway transit (if VPN/ER gateway exists)
      allow_forwarded_traffic = true
      allow_gateway_transit   = true

      # Create reverse automatically
      create_reverse_peering = true
      reverse_peering_name   = "peer-spoke-app-to-hub-weu-01"

      # Spoke uses hub's gateway, accepts forwarded traffic
      reverse_allow_forwarded_traffic = true
      reverse_use_remote_gateways     = true
    }
  ]
}
```

### Multiple Spokes

```hcl
locals {
  spokes = {
    app = {
      vnet_id   = module.vnet_spoke_app.id
      vnet_name = module.vnet_spoke_app.name
      rg_name   = module.rg_spoke_app.name
    }
    data = {
      vnet_id   = module.vnet_spoke_data.id
      vnet_name = module.vnet_spoke_data.name
      rg_name   = module.rg_spoke_data.name
    }
    mgmt = {
      vnet_id   = module.vnet_spoke_mgmt.id
      vnet_name = module.vnet_spoke_mgmt.name
      rg_name   = module.rg_spoke_mgmt.name
    }
  }
}

module "peering_hub_to_spokes" {
  source = "./modules/VNetPeering"

  peerings = [
    for name, spoke in local.spokes : {
      name                        = "peer-hub-to-spoke-${name}-weu-01"
      source_virtual_network_name = module.vnet_hub.name
      source_resource_group_name  = module.rg_hub.name
      source_virtual_network_id   = module.vnet_hub.id
      remote_virtual_network_id   = spoke.vnet_id
      remote_virtual_network_name = spoke.vnet_name
      remote_resource_group_name  = spoke.rg_name

      allow_forwarded_traffic = true
      allow_gateway_transit   = true

      create_reverse_peering          = true
      reverse_peering_name            = "peer-spoke-${name}-to-hub-weu-01"
      reverse_allow_forwarded_traffic = true
      reverse_use_remote_gateways     = true
    }
  ]
}
```

### Cross-Subscription Peering

```hcl
module "peering_cross_sub" {
  source = "./modules/VNetPeering"

  peerings = [
    {
      name                        = "peer-prod-to-shared-weu-01"
      source_virtual_network_name = "vnet-prod-weu-01"
      source_resource_group_name  = "rg-network-prod-weu-01"
      
      # Remote VNet in different subscription
      remote_virtual_network_id = "/subscriptions/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/resourceGroups/rg-shared-weu-01/providers/Microsoft.Network/virtualNetworks/vnet-shared-weu-01"
      
      allow_forwarded_traffic = true
    }
  ]
}
```

### Global (Cross-Region) Peering

```hcl
module "peering_global" {
  source = "./modules/VNetPeering"

  peerings = [
    {
      name                        = "peer-weu-to-eus-01"
      source_virtual_network_name = module.vnet_weu.name
      source_resource_group_name  = module.rg_weu.name
      source_virtual_network_id   = module.vnet_weu.id
      
      remote_virtual_network_id   = module.vnet_eus.id
      remote_virtual_network_name = module.vnet_eus.name
      remote_resource_group_name  = module.rg_eus.name

      # Note: Global peering has some limitations
      # - Gateway transit may not work across regions
      allow_forwarded_traffic = true

      create_reverse_peering          = true
      reverse_peering_name            = "peer-eus-to-weu-01"
      reverse_allow_forwarded_traffic = true
    }
  ]
}
```

## Peering Scenarios Quick Reference

| Scenario           | Hub Settings                          | Spoke Settings                    |
| ------------------ | ------------------------------------- | --------------------------------- |
| Basic Hub-Spoke    | `allow_forwarded_traffic = true`      | `allow_forwarded_traffic = true`  |
| With VPN Gateway   | + `allow_gateway_transit = true`      | + `use_remote_gateways = true`    |
| With NVA (Firewall)| `allow_forwarded_traffic = true`      | `allow_forwarded_traffic = true`  |
| Isolation          | `allow_virtual_network_access = false`| (same)                            |

## Best Practices

1. **Naming Convention**: Use descriptive names like `peer-{source}-to-{dest}-{region}-{index}`
2. **Bidirectional**: Always create peerings in both directions for full connectivity
3. **Gateway Transit**: Only one VNet can have `allow_gateway_transit = true` in a peering
4. **NVA Traffic**: Enable `allow_forwarded_traffic` when using firewalls or routers
5. **Documentation**: Use the `peering_details` output for documentation and auditing

## Important Notes

- **Peering is NOT transitive**: VNet A peered to B, and B peered to C, does NOT mean A can reach C
- **Spoke-to-Spoke**: Traffic between spokes must go through hub NVA (requires UDRs)
- **Gateway Conflict**: `allow_gateway_transit` and `use_remote_gateways` cannot both be true
- **Cross-subscription**: Requires permissions on both subscriptions
- **Global Peering**: Some features (like gateway transit) may be limited

## Troubleshooting

| Issue                     | Cause                                              | Solution                                    |
| ------------------------- | -------------------------------------------------- | ------------------------------------------- |
| Peering state: Initiated  | Reverse peering not created                        | Create peering in both directions           |
| Peering state: Disconnected | Remote VNet deleted or peering removed            | Recreate peering                            |
| Can't use gateway         | Gateway not deployed or wrong settings             | Check `allow_gateway_transit` and gateway   |
| Traffic blocked           | NSG or missing UDR                                 | Check NSG rules and route tables            |

## Resources Created

- `azurerm_virtual_network_peering` - Forward peerings
- `azurerm_virtual_network_peering` - Reverse peerings (if `create_reverse_peering = true`)
- `time_static` - Timestamp for audit tracking
