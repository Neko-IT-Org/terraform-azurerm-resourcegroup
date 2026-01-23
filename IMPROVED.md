# 🏗️ Azure Hub-and-Spoke Infrastructure with Palo Alto Firewall

![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-623CE4?logo=terraform)
![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoftazure)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Production--Ready-success)

Production-ready Terraform infrastructure for deploying a secure Hub-and-Spoke network architecture on Azure with Palo Alto Networks VM-Series firewall.

---

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Module Documentation](#-module-documentation)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Security](#-security)
- [Cost Estimation](#-cost-estimation)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Hub VNet (10.0.0.0/16)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Management  │  │   Untrust    │  │    Trust     │     │
│  │  10.0.1.0/24 │  │  10.0.2.0/24 │  │  10.0.3.0/24 │     │
│  │    NSG       │  │    NSG       │  │    NSG       │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │              │
│         └────────┬─────────┴────────┬─────────┘             │
│                  │                  │                        │
│         ┌────────▼──────────────────▼────────┐             │
│         │   Palo Alto VM-Series Firewall     │             │
│         │   • BYOL/Bundle Licensing          │             │
│         │   • Bootstrap Support               │             │
│         │   • HA Ready                        │             │
│         └────────────────────────────────────┘             │
└───────────────────────────┬─────────────────────────────────┘
                            │ VNet Peering
              ┌─────────────┼─────────────┐
              │             │             │
    ┌─────────▼──────┐  ┌──▼──────────┐ │
    │  Spoke App VNet │  │ Spoke Data  │ │
    │  10.1.0.0/16    │  │ 10.2.0.0/16 │ │
    │  • Web Subnet   │  │ • DB Subnet │ │
    │  • App Subnet   │  │             │ │
    │  • UDR → FW     │  │ • UDR → FW  │ │
    └─────────────────┘  └─────────────┘ │
```

### Traffic Flow

- **North-South**: Internet ↔ Firewall (Untrust) ↔ Spoke VNets
- **East-West**: Spoke ↔ Firewall (Trust) ↔ Spoke
- **Management**: Dedicated Management subnet with strict NSG

---

## ✨ Features

### Core Infrastructure

- ✅ **Hub-and-Spoke Topology** - Centralized security and routing
- ✅ **Palo Alto VM-Series** - Enterprise-grade firewall
- ✅ **Bootstrap Support** - Automated firewall configuration
- ✅ **Modular Design** - Reusable Terraform modules
- ✅ **Multiple Environments** - Dev, Staging, Production

### Security

- 🔒 **Network Security Groups** - Granular traffic control
- 🔒 **User Defined Routes** - Force traffic through firewall
- 🔒 **SSH Key Authentication** - No password authentication
- 🔒 **Management Locks** - Prevent accidental deletion
- 🔒 **RBAC Support** - Role-based access control

### Observability

- 📊 **Diagnostic Settings** - Azure Monitor integration
- 📊 **Automatic Tagging** - CreatedOn timestamps
- 📊 **Telemetry Support** - Log Analytics workspace
- 📊 **Cost Tracking** - Resource group level tags

### DevOps

- 🚀 **GitHub Actions** - Automated CI/CD
- 🚀 **Pre-commit Hooks** - Code quality validation
- 🚀 **Makefile** - Simplified operations
- 🚀 **Terraform Workspaces** - Environment isolation

---

## 📦 Prerequisites

### Required Tools

| Tool           | Version | Purpose                    |
| -------------- | ------- | -------------------------- |
| Terraform      | ≥ 1.5.0 | Infrastructure provisioning|
| Azure CLI      | ≥ 2.50  | Azure authentication       |
| Make           | Any     | Task automation (optional) |
| Pre-commit     | Latest  | Code validation (optional) |

### Azure Requirements

- **Subscription**: Active Azure subscription
- **Permissions**: Contributor role at subscription level
- **Service Principal**: For CI/CD pipeline
- **Marketplace Agreement**: Accept Palo Alto terms

```bash
# Accept Palo Alto Marketplace terms
az vm image terms accept \
  --publisher paloaltonetworks \
  --offer vmseries-flex \
  --plan byol
```

---

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/Neko-IT-Org/azure-terraform-modules.git
cd azure-terraform-modules
```

### 2. Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Minimum Required Variables:**

```hcl
project_name = "neko"
environment  = "dev"
location     = "westeurope"

admin_source_ip             = "YOUR_PUBLIC_IP/32"
palo_alto_admin_ssh_key     = "ssh-rsa AAAAB3..."
log_analytics_workspace_id  = "/subscriptions/.../workspaces/..."
```

### 3. Deploy Infrastructure

```bash
# Using Make (recommended)
make init
make plan
make apply

# Or using Terraform directly
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Verify Deployment

```bash
# Check outputs
terraform output infrastructure_summary

# Access firewall management
ssh paadmin@<FIREWALL_MGMT_IP> -i ~/.ssh/palo_key
```

---

## 📚 Module Documentation

### Available Modules

| Module         | Description                      | README                                   |
| -------------- | -------------------------------- | ---------------------------------------- |
| resourcegroup  | Azure Resource Groups with locks | [Link](./modules/resourcegroup/README.md)|
| Vnet           | Virtual Networks                 | [Link](./modules/Vnet/README.md)         |
| Subnet         | Subnets with associations        | [Link](./modules/Subnet/README.md)       |
| NSG            | Network Security Groups          | [Link](./modules/NSG/README.md)          |
| RouteTable     | User Defined Routes              | [Link](./modules/RouteTable/README.md)   |
| VNetPeering    | VNet peering management          | [Link](./modules/VNetPeering/README.md)  |
| PaloAlto       | VM-Series firewall deployment    | [Link](./modules/PaloAlto/README.md)     |

### Module Usage Example

```hcl
module "vnet_hub" {
  source              = "./modules/Vnet"
  name                = "vnet-hub-prod-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg_hub.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}
```

---

## ⚙️ Configuration

### Environment-Specific Variables

Create separate tfvars files for each environment:

```bash
environments/
├── dev.tfvars
├── staging.tfvars
└── prod.tfvars
```

### Terraform Workspaces

```bash
# Create and switch to workspace
terraform workspace new dev
terraform workspace select dev

# Deploy to specific environment
terraform apply -var-file=environments/dev.tfvars
```

### Backend Configuration

For production, use Azure Storage backend:

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-prod-weu-01"
    storage_account_name = "sttfstateprodweu01"
    container_name       = "tfstate"
    key                  = "hub-spoke.tfstate"
  }
}
```

---

## 🔐 Security

### Sensitive Variables

Store sensitive data in Azure Key Vault:

```bash
# Store SSH key
az keyvault secret set \
  --vault-name kv-terraform-prod \
  --name palo-ssh-key \
  --file ~/.ssh/palo_key.pub

# Reference in pipeline
TF_VAR_palo_alto_admin_ssh_key=$(az keyvault secret show \
  --vault-name kv-terraform-prod \
  --name palo-ssh-key \
  --query value -o tsv)
```

### Network Security

- **Management Subnet**: Restricted to admin IP only
- **Untrust Subnet**: Public-facing with firewall inspection
- **Trust Subnet**: Private, routes through firewall
- **Spoke Subnets**: UDRs force traffic to firewall

---

## 💰 Cost Estimation

### Using Infracost

```bash
# Install Infracost
brew install infracost

# Generate cost estimate
infracost breakdown --path .

# Compare with baseline
infracost diff --path . --compare-to infracost-base.json
```

### Estimated Monthly Costs (West Europe)

| Resource               | Quantity | Cost/Month (USD) |
| ---------------------- | -------- | ---------------- |
| Palo Alto VM (D3v2)    | 1        | ~$180            |
| Public IPs (Standard)  | 2        | ~$7              |
| VNet Peering (1TB)     | 2        | ~$20             |
| Log Analytics (5GB)    | 1        | ~$10             |
| **Total**              |          | **~$217**        |

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Marketplace Agreement Not Accepted

**Error**: `MarketplacePurchaseEligibilityFailed`

**Solution**:
```bash
az vm image terms accept \
  --publisher paloaltonetworks \
  --offer vmseries-flex \
  --plan byol
```

#### 2. Peering State "Initiated"

**Error**: Peering shows as "Initiated" instead of "Connected"

**Solution**: Create reverse peering or set `create_reverse_peering = true`

#### 3. Cannot SSH to Firewall

**Error**: Connection timeout

**Solution**:
1. Check NSG allows your IP: `admin_source_ip = "YOUR_IP/32"`
2. Verify public IP assignment: `terraform output`
3. Wait 5-10 minutes for VM to fully boot

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Workflow

```bash
# Install pre-commit hooks
make pre-commit

# Run validation tests
make test

# Format code
make fmt

# Generate documentation
make docs
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Authors

**Neko-IT-Org**

- GitHub: [@Neko-IT-Org](https://github.com/Neko-IT-Org)

---

## 🙏 Acknowledgments

- Palo Alto Networks for VM-Series documentation
- HashiCorp for Terraform
- Azure community for best practices

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Neko-IT-Org/azure-terraform-modules/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Neko-IT-Org/azure-terraform-modules/discussions)

---

**⭐ If this project helped you, please give it a star!**
