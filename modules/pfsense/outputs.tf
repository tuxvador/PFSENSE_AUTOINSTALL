output "vmid" {
  description = "Proxmox vm id"
  value       = proxmox_vm_qemu.pfsense_install.vmid
}
