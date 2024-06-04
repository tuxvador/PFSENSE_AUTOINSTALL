resource "proxmox_vm_qemu" "pfsense_install" {
  desc        = "pfsense install"
  name        = "PFSENSE"
  agent       = 0
  pool        = "ADMIN"
  vmid        = var.pfsense_vmid
  bios        = "ovmf"
  target_node = "windows-perso"
  cores       = "2"
  sockets     = "2"
  onboot      = true
  numa        = true
  iso         = var.pfsense_iso
  memory      = 2048
  balloon     = 2048
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disks {
    virtio {
      virtio0 {
        disk {
          size    = "20"
          storage = "local-lvm"
          format  = "raw"
          backup  = true
        }
      }
    }
  }

  network {
    bridge = "vmbr1"
    model  = "virtio"
  }

  network {
    bridge = "vmbr2"
    model  = "virtio"
  }

  network {
    bridge = "vmbr3"
    model  = "virtio"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    working_dir = "${path.module}/scripts/"
    command     = "./pfsense.sh ${proxmox_vm_qemu.pfsense_install.vmid}"
  }

  connection {
    type     = "ssh"
    user     = "admin"
    password = var.pfsense_password
    host     = var.pfsense_ip
  }

  provisioner "remote-exec" {
    inline = [
      "pkg update -y",
      "pkg install -y qemu-guest-agent",
      "pkg install -y sudo",
      "pkg install -y vim",
      "python3.11 -m ensurepip",                 #install pip
      "python3.11 -m pip install --upgrade pip", #upgrade pip
      "sysrc sshd_enable='YES'",
      "sysrc qemu_guest_agent_enable='YES'",
      "sysrc qemu_guest_agent_flags='-d -v -l /var/log/qemu-ga.log'",
      "service qemu-guest-agent start",
      "service qemu-guest-agent status",
    ]
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    working_dir = "${path.module}/scripts/ansible"
    command     = "ansible-playbook -i inventory.yml playbook.yml"
  }
}
