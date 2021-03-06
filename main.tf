# Author: Jon Howe
# Blog: https://www.virtjunkie.com/vmware-provisioning-using-hashicorp-terraform-part-2/
# GitHub: https://github.com/jonhowe/Terraform-vSphere-VirtualMachine/blob/master/main.tf
# Vcenter connection parameters
provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}
 
data "vsphere_datacenter" "dc" {
  name = var.datacenter
}
 
data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}
 
data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
 
data "vsphere_network" "network" {
  name          = var.portgroup
  datacenter_id = data.vsphere_datacenter.dc.id
}
 
data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}
 
 
resource "vsphere_virtual_machine" "windows" {
  count = var.is_windows_image ? 1 : 0
  name              = var.vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
 
  num_cpus = var.vcpu_count
  memory   = var.memory
  guest_id = data.vsphere_virtual_machine.template.guest_id
 
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
 
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
 
  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
    datastore_id     = data.vsphere_datastore.datastore.id
  }
  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
    datastore_id     = data.vsphere_datastore.datastore.id
    unit_number = 1
  }
    customize {
      #https://www.terraform.io/docs/providers/vsphere/r/virtual_machine.html#windows-customization-options
      windows_options {
        computer_name  = var.vm_name
        admin_password = var.adminpassword
        
        join_domain = "internal.local"
	      domain_admin_user = "wallsb_mgt@internal.local"
	      domain_admin_password = "SkyrimBatteryRig110"
        run_once_command_list = [
        ]
        
      }
      network_interface {}
 
      
      network_interface {
        ipv4_address = var.vm_ip
        ipv4_netmask = var.vm_cidr
      }
      ipv4_gateway = var.default_gw
      dns_server_list = ["172.20.24.13","172.20.22.31"]
      
    }
}