##### Terraform Initialization
terraform {
  required_version = ">= 0.13"

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "1.24.3"
    }
  }
}

##### Provider
provider "vsphere" {
  user           = var.provider_vsphere_user
  password       = var.provider_vsphere_password
  vsphere_server = var.provider_vsphere_host

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

##### Data sources
data "vsphere_datacenter" "target_dc" {
  name = var.deploy_vsphere_datacenter
}

data "vsphere_datastore" "target_datastore" {
  name          = var.deploy_vsphere_datastore
  datacenter_id = data.vsphere_datacenter.target_dc.id
}

data "vsphere_host" "target_host" {
  name          = var.deploy_vsphere_host
  datacenter_id = data.vsphere_datacenter.target_dc.id
}

# Get default resource pool
data "vsphere_resource_pool" "pool" {
  name          = "Resources"  # Default resource pool name
  datacenter_id = data.vsphere_datacenter.target_dc.id
}

data "vsphere_network" "target_network" {
  name          = var.deploy_vsphere_network
  datacenter_id = data.vsphere_datacenter.target_dc.id
}

data "vsphere_virtual_machine" "source_template" {
  name          = var.guest_template
  datacenter_id = data.vsphere_datacenter.target_dc.id
}

##### Resources
# Clones a single Linux VM from a template
resource "vsphere_virtual_machine" "kubernetes_master" {
  count            = length(var.master_ips)
  name             = "${var.guest_name_prefix}-master0${count.index + 1}"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  host_system_id   = data.vsphere_host.target_host.id
  datastore_id     = data.vsphere_datastore.target_datastore.id
  folder           = var.deploy_vsphere_folder
  firmware         = var.guest_firmware

  num_cpus = var.guest_vcpu
  memory   = var.guest_memory
  guest_id = data.vsphere_virtual_machine.source_template.guest_id

  scsi_type = data.vsphere_virtual_machine.source_template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.target_network.id
    adapter_type = data.vsphere_virtual_machine.source_template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.source_template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.source_template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.source_template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.source_template.id

    customize {
      linux_options {
        host_name = "${var.guest_name_prefix}-master0${count.index + 1}"
        domain    = var.guest_domain
      }

      network_interface {
        ipv4_address = var.master_ips[count.index]
        ipv4_netmask = var.guest_ipv4_netmask
      }

      ipv4_gateway    = var.guest_ipv4_gateway
      dns_server_list = split(",", var.guest_dns_servers)
      dns_suffix_list = split(",", var.guest_dns_suffix)
    }
  }

  boot_delay = 10000

  # Windows-compatible wait - SIMPLIFIED: Just echo, no sleep
  provisioner "local-exec" {
    command     = "echo Waiting for VM ${self.name} to boot... Please wait 2-3 minutes."
    interpreter = ["cmd", "/C"]
    on_failure  = continue
  }

  lifecycle {
    ignore_changes = [
      annotation,
      disk[0].thin_provisioned,
      clone[0].template_uuid
    ]
    
    # Add create timeout for slow vCenter
    create_before_destroy = true
  }
}

# Clones multiple Linux VMs from a template
resource "vsphere_virtual_machine" "kubernetes_workers" {
  count            = length(var.worker_ips)
  name             = "${var.guest_name_prefix}-worker0${count.index + 1}"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  host_system_id   = data.vsphere_host.target_host.id
  datastore_id     = data.vsphere_datastore.target_datastore.id
  folder           = var.deploy_vsphere_folder
  firmware         = var.guest_firmware

  num_cpus = var.guest_vcpu
  memory   = var.guest_memory
  guest_id = data.vsphere_virtual_machine.source_template.guest_id

  scsi_type = data.vsphere_virtual_machine.source_template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.target_network.id
    adapter_type = data.vsphere_virtual_machine.source_template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.source_template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.source_template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.source_template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.source_template.id

    customize {
      linux_options {
        host_name = "${var.guest_name_prefix}-worker0${count.index + 1}"
        domain    = var.guest_domain
      }

      network_interface {
        ipv4_address = var.worker_ips[count.index]
        ipv4_netmask = var.guest_ipv4_netmask
      }

      ipv4_gateway    = var.guest_ipv4_gateway
      dns_server_list = split(",", var.guest_dns_servers)
      dns_suffix_list = split(",", var.guest_dns_suffix)
    }
  }

  boot_delay = 10000

  # Windows-compatible wait - SIMPLIFIED: Just echo, no sleep
  provisioner "local-exec" {
    command     = "echo Waiting for VM ${self.name} to boot... Please wait 2-3 minutes."
    interpreter = ["cmd", "/C"]
    on_failure  = continue
  }

  lifecycle {
    ignore_changes = [
      annotation,
      disk[0].thin_provisioned,
      clone[0].template_uuid
    ]
    
    # Add create timeout for slow vCenter
    create_before_destroy = true
  }
}

# Wait resource to ensure VMs are created before proceeding
resource "time_sleep" "wait_for_vms" {
  depends_on = [
    vsphere_virtual_machine.kubernetes_master,
    vsphere_virtual_machine.kubernetes_workers
  ]

  create_duration = "180s"  # Wait 3 minutes after VM creation
}

# Final status output (Windows compatible)
resource "null_resource" "cluster_status" {
  depends_on = [time_sleep.wait_for_vms]

  provisioner "local-exec" {
    command = <<-EOT
      echo =========================================
      echo Kubernetes Cluster VMs Created Successfully!
      echo =========================================
      echo.
      echo Master Node:
      echo   Name: ${vsphere_virtual_machine.kubernetes_master[0].name}
      echo   IP:   ${vsphere_virtual_machine.kubernetes_master[0].default_ip_address}
      echo.
      echo Worker Nodes:
      ${join("", [for idx, worker in vsphere_virtual_machine.kubernetes_workers : "echo   ${worker.name}: ${worker.default_ip_address}\n      "])}
      echo.
      echo Next Steps:
      echo 1. Open vSphere console for each VM
      echo 2. Login with: ubuntu/ubuntu (or packer/VMware1!)
      echo 3. Enable SSH: sudo systemctl start ssh
      echo 4. Disable firewall: sudo ufw disable
      echo =========================================
    EOT
    interpreter = ["cmd", "/C"]
  }
}

##### Outputs
output "master_ips" {
  value = [for vm in vsphere_virtual_machine.kubernetes_master : vm.default_ip_address]
  description = "IP addresses of master nodes"
}

output "worker_ips" {
  value = [for vm in vsphere_virtual_machine.kubernetes_workers : vm.default_ip_address]
  description = "IP addresses of worker nodes"
}

output "vm_names" {
  value = concat(
    [for vm in vsphere_virtual_machine.kubernetes_master : vm.name],
    [for vm in vsphere_virtual_machine.kubernetes_workers : vm.name]
  )
  description = "Names of all created VMs"
}

output "instructions" {
  value = <<-EOT
    
    ===========================================================================
    KUBERNETES CLUSTER DEPLOYMENT INSTRUCTIONS
    ===========================================================================
    
    VMs Created Successfully:
    
    MASTER NODE:
      Name: ${vsphere_virtual_machine.kubernetes_master[0].name}
      IP:   ${vsphere_virtual_machine.kubernetes_master[0].default_ip_address}
    
    WORKER NODES:
    %{ for idx, worker in vsphere_virtual_machine.kubernetes_workers }
      ${worker.name}: ${worker.default_ip_address}
    %{ endfor }
    
    NEXT STEPS - Manual Configuration Required:
    
    1. FOR EACH VM (do this in vSphere Console):
       a. Open vSphere Client
       b. Go to VMs and Templates → your folder name
       c. Right-click each VM → Open Console
       d. Login with (try both):
          • Username: ubuntu     Password: ubuntu
          • Username: packer     Password: VMware1!
    
    2. IN EACH VM CONSOLE, run these commands:
       sudo systemctl start ssh
       sudo systemctl enable ssh
       sudo ufw disable
       sudo apt-get update
       sudo apt-get install -y python3 python3-pip
    
    3. TEST SSH FROM YOUR WINDOWS MACHINE (PowerShell):
       ssh ubuntu@${vsphere_virtual_machine.kubernetes_master[0].default_ip_address}
    
    ===========================================================================
    Note: If SSH fails, check Windows OpenSSH is installed:
    Settings → Apps → Optional Features → Add "OpenSSH Client"
    ===========================================================================
  EOT
  description = "Complete deployment instructions"
}