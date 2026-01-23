# Azure Infrastructure Terraform Modules

Production-ready Terraform modules for deploying Azure infrastructure following best practices.

## Architecture

Modular design supporting Hub-and-Spoke, single VNet, or any custom Azure network topology.

## Modules

| Module                                    | Description                                   |
| ----------------------------------------- | --------------------------------------------- |
| [resourcegroup](./modules/resourcegroup/) | Azure Resource Group with locks and RBAC      |
| [Vnet](./modules/Vnet/)                   | Virtual Network with DDoS and DNS support     |
| [Subnet](./modules/Subnet/)               | Subnets with NSG and Route Table associations |
| [NSG](./modules/NSG/)                     | Network Security Groups with rules            |
| [RouteTable](./modules/RouteTable/)       | Route Tables for traffic steering             |

## Prerequisites

- Terraform >= 1.5.0
- Azure CLI authenticated
- Appropriate Azure permissions

## Quick Start

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply infrastructure
terraform apply
```

## Structure

```
.
├── modules/
│   ├── resourcegroup/
│   ├── Vnet/
│   ├── Subnet/
│   ├── NSG/
│   └── RouteTable/
├── main.tf           # Root configuration
├── variables.tf      # Root variables
├── outputs.tf        # Root outputs
└── README.md
```

## Key Features

- **Modular Design**: Reusable modules for each Azure resource type
- **Automatic Tagging**: All resources tagged with `CreatedOn` timestamp
- **Validation**: Built-in validation for Azure naming and configuration rules
- **Flexible**: Works with IaaS, PaaS, SaaS, Kubernetes, and any Azure service
- **Production Ready**: Includes locks, RBAC, and security best practices

## Naming Convention

`<resource>-<project>-<env>-<region>-<index>`

Examples:

- `rg-myapp-prod-weu-01`
- `vnet-hub-prod-weu-01`
- `nsg-aks-cluster-weu-01`

## Use Cases

- Hub-and-Spoke architectures
- AKS cluster networking
- Multi-tier applications
- Isolated environments
- Any Azure networking scenario

## Authors

Neko-IT-Org
