output "datacenter_id" {
  value = data.vsphere_datacenter.target_dc.id
}

output "host_id" {
  value = data.vsphere_host.target_host.id
}

output "datastore_id" {
  value = data.vsphere_datastore.target_datastore.id
}

output "portgroup_id" {
  value = data.vsphere_network.target_network.id
}