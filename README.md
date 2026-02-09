# Terraform vSphere Kubernetes Infrastructure

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![VMware](https://img.shields.io/badge/VMware-231f20?style=for-the-badge&logo=VMware&logoColor=white)

## Overview
Terraform module to provision a Kubernetes cluster infrastructure with 3 VMs on VMware vSphere. This module creates master and worker VMs with proper network configuration, ready for Kubernetes installation.

## Architecture
Creates 3 VMs (1 master + 2 workers) on vSphere:
- Master: `k8s-prod-master01` (10.20.110.5)
- Worker 1: `k8s-prod-worker01` (10.20.110.6)
- Worker 2: `k8s-prod-worker02` (10.20.110.7)

## Features
- **vSphere Integration**: Leverages VMware vSphere for enterprise-grade virtualization
- **Customizable**: Adjust CPU, memory, disk size, and cluster size
- **Network Configuration**: Static IP assignment with custom DNS and gateway
- **Windows Compatible**: Works on Windows, macOS, and Linux
- **Idempotent**: Safe to apply multiple times

## Prerequisites
- vSphere 8.0.3+ with appropriate permissions
- Ubuntu VM template (tested with Ubuntu 22.04)
- Network with VLAN 110 configured
- Terraform 0.13+
- vSphere provider credentials

## File Structure
The set of files used to describe infrastructure in Terraform is simply known as a Terraform configuration.:

```
├── main.tf
├── output.tf
├── terraform.tfvars
└── variables.tf
```
1. The `main.tf` file is where the core logic of your infrastructure is defined. It contains the resources that will be provisioned (e.g., vSphere cluster, datastore, portgroup, and so on), the resource blocks describe the virtual machines to create.

2. The `variables.tf` holds all the variables used in your Terraform configuration. These variables allow for dynamic configurations that can be customized at runtime. You define the variable types, descriptions, and default values in this file. (but not the values of those variables which are defined in terraform.tfvars).
   
3. For all files which match `terraform.tfvars` or `*.auto.tfvars` present in the current directory, Terraform automatically loads them to populate variables. This file provides the actual values for actual variables.

4.(optional) The `output.tf` file defines what information Terraform should print out after running apply or plan

> Note: Although .tfvars files are usually not distributed for security reasons, I included mine here for demonstration purposes.

## Execution

```
#Step 1: Initialize
terraform init

#Step 2: Preview changes
terraform plan

#Step 3: Apply changes
terraform apply
```

### Init

The first command to run for a new configuration is  `terraform init`, which initializes various local settings and data that will be used by subsequent commands. This command will sets up everything Terraform needs before you can plan or apply infrastructure.

### Plan
`terraform plan` is the dry run step in Terraform. It shows you what Terraform would do if you applied your configuration, without actually making any changes yet.

### Apply
`terraform apply` is the command that actually executes the changes described in your configuration and confirmed in the `terraform plan`.

### Destroy
`terraform destroy` is the cleanup command in Terraform. It removes all the resources that were previously created by your configuration, essentially reversing what `terraform apply` did.


## Inspiration & Acknowledgments

This project was inspired by and builds upon several great open-source projects:

### Core Inspiration
- **[terraform-deploy-vmware-vm](https://github.com/cloudmaniac/terraform-deploy-vmware-vm)** - Excellent reference for vSphere Terraform patterns
- [Terraform vSphere Provider Examples](https://github.com/hashicorp/terraform-provider-vsphere) - Official examples from HashiCorp

### Libraries & Tools Used
- [Terraform](https://www.terraform.io/) - Infrastructure as Code

Special thanks to the maintainers of these projects for their excellent work! ><
