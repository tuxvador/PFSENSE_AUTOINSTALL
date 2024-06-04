# proxmox_goad_pfsense Autoinstall
Proxmox GOAD Pfsense Autoinstall

The aim of this repo is to share scripts that i have develloped to automate pfsense firewall install for proxmox

I am currently automating the majority of the tasks. For the install, the user only normaly has to modify the file **goad.conf** in the root directory of the repository.

The script will generate the **dev.tvars** file needed by terraform.

the install script will also : 
- install packages need for the install like sshpass and ansible
- create interfaces
- create terraform user, terraform role and terraform token and deletes them at the end of the install
- generate dev.tfvars for terraform
- modify ansibles inventory.yml to match goad.conf
- generate pfsense.sh to send keys based on the template pfsense.template.sh
- create and configure pfsense vm

## Install.sh
path **install/install.sh**
to install pfsense in automatic mode, run : ```bash install/install.sh``` as root user on proxmox. 

This will generate the interfaces, install pfsense and configure it with the rules in ansibles playbook

No input is needed, the script uses and displays default value which you only have to validate by pressing enter.


**Estimated install time :
PFSense version : pfSense-CE-2.7.2
Ansible version : core 2.14.3
Terraform version : v1.8.4
lxml version : 5.2.2
pfsensible.core version : 0.6.1**


# Note
You need internet access on your proxmox ton install packages in pfsense.tf in /module/pfsense/ansible/scripts/pfsense.tf in the remote_exec block.

The lxml python package is needed to be able to edit xml files with ansible. It is not present by default in pfsense and needs to be copied or installed on another FreeBSD 14 instance and then moved to to the pfsense virtual machine
