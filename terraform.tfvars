# Provider
provider_vsphere_host     = "vcenter.hamzuy.lab"
provider_vsphere_user     = "administrator@vshpere.lab"
provider_vsphere_password = "@password123"

# Infrastructure
deploy_vsphere_datacenter = "Datacenter"
deploy_vsphere_host    = "192.168.20.3"
deploy_vsphere_datastore  = "DC"
deploy_vsphere_folder     = "dyy"
deploy_vsphere_network    = "vlan110"

# Guest
guest_name_prefix     = "k8s-prod"
guest_template        = "ubuntu-template-22"
guest_vcpu            = "4"
guest_memory          = "4096"
guest_ipv4_netmask    = "24"
guest_ipv4_gateway    = "10.20.110.1"
guest_dns_servers     = "10.20.110.1"
guest_dns_suffix      = "k8s-dyy.lab"
guest_domain          = "k8s-dyy.lab"
guest_ssh_user        = "secops"
guest_ssh_password    = "secops123"
guest_ssh_key_private = "C:/Users/dyy/.ssh/id_ed25519"
guest_ssh_key_public  = "C:/Users/dyy/.ssh/id_ed25519.pub"
guest_firmware        = "efi"

# Master(s)
#master_ips = {
#  "0" = "10.20.110.5"
#}
# To:
master_ips = ["10.20.110.5"]

# Worker(s)
#worker_ips = {
#  "0" = "10.20.110.6"
#  "1" = "10.20.110.7"
#}
# To:
worker_ips = ["10.20.110.6", "10.20.110.7"]