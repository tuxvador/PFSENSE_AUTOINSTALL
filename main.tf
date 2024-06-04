#define providel in parent to be able to use depend_on in module définition
#error when put directly in the submodule, provifer.tf has to be created in parent and child
#and required provider only has to be defined in that file
provider "proxmox" {
  pm_parallel         = 3
  pm_tls_insecure     = true
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
}

#create Admin pool in proxmox
module "cpool" {
  source = "./modules/create_pool/"
}

#delete ADMIN pool in proxmox
module "dpool" {
  source = "./modules/delete_pool/"
}

#create PFSENS VM
module "pfsense" {
  source           = "./modules/pfsense"
  pfsense_ip       = var.pfsense_ip
  pfsense_password = var.pfsense_password
  pfsense_iso      = var.pfsense_iso
  pfsense_vmid     = var.pfsense_vmid
  depends_on       = [module.cpool, module.dpool]
}
