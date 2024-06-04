#!/bin/bash

# Check if the configuration file exists
if [ ! -f goad.conf ]; then
    echo "Configuration file 'goad.conf' not found!"
    exit 1
fi

if [ ! -f modules/pfsense/scripts/ansible/inventory.yml ]; then
    echo "Inventory file 'inventory.yml' not found!"
    exit 1
fi

echo "********************************************************************************************"
echo "Create config"
echo "********************************************************************************************"
pmurl=$(echo 'PROXM_API_URL=https://'$(ip addr show vmbr0 | grep 'inet ' |cut -d ' ' -f 6|cut -d/ -f 1)'/api2/json');sed -i "s#PROXM_API_URL=.*#$pmurl#g" goad.conf
pfpwd=$(grep PFS_PWD goad.conf| cut -d "=" -f2)
pfpwdhash=$(htpasswd -bnBC 10 '' 'password'|head -n 1|cut -d ':' -f2)
sed -i "s#.*PFS_HASH=.*#PFS_HASH=$pfpwdhash#g" goad.conf
sed -i "s#.*PFS_ISO=.*#PFS_ISO=local:iso/$(ls /var/lib/vz/template/iso/ | grep -i pfsense)#g" goad.conf

echo "********************************************************************************************"
echo "create Terraform user, terraform role and api access token"
echo "********************************************************************************************"
trf_user=$(grep PROXM_TRF_USER goad.conf| cut -d "=" -f2)
trf_usr_pwd=$(grep PROXM_TRF_USR_PWD goad.conf| cut -d "=" -f2)
trf_token_id=$(grep PROXM_TRF_TOKEN_ID goad.conf| cut -d "=" -f2)
trf_token_name=$(grep PROXM_TRF_TOKEN_NAME goad.conf| cut -d "=" -f2)

pveum user add $trf_user@pve --password $trf_usr_pwd
#Terraform password generation
sed -i "s#.*PROXM_TRF_USR_PWD=.*#PROXM_TRF_USR_PWD=$(pwgen -c 16 -n 1)#g" goad.conf
#Token creation
sed -i "s#.*PROXM_TRF_TOKEN_VALUE=.*#PROXM_TRF_TOKEN_VALUE=$(pvesh create /access/users/terraform@pve/token/$trf_token_name --expire 0 --privsep 0 --output-format json | cut -d ',' -f4|cut -d '"' -f4)#g" goad.conf

trf_role=$(grep PROXM_TRF_ROLE goad.conf| cut -d "=" -f2)

#echo $trf_usr_pwd $trf_user $trf_role $trf_token_name
#pvesh create /access/users --userid $trf_user@pve --password $trf_usr_pwd

pveum role add $trf_role -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"
pveum aclmod / -user $trf_user@pve -role $trf_role

echo "********************************************************************************************"
echo "generate tfvarfile"
echo "********************************************************************************************"
cat > dev.tfvars << EOF
pm_api_url          = "$(grep PROXM_API_URL goad.conf| cut -d "=" -f2)"
pm_api_token_id     = "$(grep PROXM_TRF_TOKEN_ID goad.conf| cut -d "=" -f2)"
pm_api_token_secret = "$(grep PROXM_TRF_TOKEN_VALUE goad.conf| cut -d "=" -f2)"
pfsense_password    = "$(grep PFS_DEFAULT_PWD goad.conf| cut -d "=" -f2)"
pfsense_ip          = "$(grep PFS_LAN_IP goad.conf| cut -d "=" -f2)"
pfsense_vmid        = $(grep PROXM_VMID goad.conf| cut -d "=" -f2)
pfsense_iso         = "$(grep PFS_ISO goad.conf| cut -d "=" -f2)"
EOF

echo ''
echo ''

echo "********************************************************************************************"
echo "Install needed packages"
echo "********************************************************************************************"

bash install/dependencies.sh

echo ''
echo ''

echo "********************************************************************************************"
echo "create interfaces"
echo "********************************************************************************************"

bash install/interface.sh

echo ''
echo ''

echo "*******************************************************"
echo "repalce values in ansible inventory with values from goad.conf"
echo "*******************************************************"
# Extract values from goad.conf
PFS_LAN_IP=$(grep 'PFS_LAN_IPV4_ADDRESS' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_DEFAULT_PWD=$(grep 'PFS_DEFAULT_PWD' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_PWD=$(grep 'PFS_PWD' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_HASH=$(grep 'PFS_HASH' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_WAN_IP=$(grep 'PFS_WAN_IPV4_ADDRESS' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PROXM_DOMAIN=$(grep 'PROXM_DOMAIN' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PROXM_HOSTNAME=$(grep 'PROXM_HOSTNAME' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PROXM_DNS_HOSTNAME=$(grep 'PROXM_DNS_HOSTNAME' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PROXM_DNS_IP=$(grep 'PROXM_DNS_IP' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_whitelist_ssh_network=$(grep 'PFS_whitelist_ssh_network' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_WAN_NETWORK=$(grep 'PFS_WAN_NETWORK' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_WAN_MASK=$(grep 'PFS_WAN_MASK' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_LAN_NETWORK=$(grep 'PFS_LAN_NETWORK' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_LAN_MASK=$(grep 'PFS_LAN_MASK' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_WAN_INTERFACE=$(grep 'PFS_WAN_INTERFACE' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_LAN_INTERFACE=$(grep 'PFS_LAN_INTERFACE' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_OPTIONAL_INTERFACE=$(grep 'PFS_OPTIONAL_INTERFACE' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_VLAN1_INTERFACE=$(grep 'PFS_VLAN1_INTERFACE' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_VLAN2_INTERFACE=$(grep 'PFS_VLAN2_INTERFACE' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_WAN_IPV4_ADDRESS=$(grep 'PFS_WAN_IPV4_ADDRESS' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_WAN_GATEWAY=$(grep 'PFS_WAN_GATEWAY' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_LAN_IPV4_ADDRESS=$(grep 'PFS_LAN_IPV4_ADDRESS' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
PFS_LAN_GATEWAY=$(grep 'PFS_LAN_GATEWAY' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
VLAN1_NETWORK=$(grep 'VLAN1_NETWORK' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
VLAN2_NETWORK=$(grep 'VLAN2_NETWORK' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
VLANTAG1=$(grep 'VLANTAG1' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
VLANTAG1_ipv4=$(grep 'VLANTAG1_ipv4' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
VLANTAG2=$(grep 'VLANTAG2' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
VLANTAG2_ipv4=$(grep 'VLANTAG2_ipv4' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
VLAN1_DHCP_START=$(grep 'VLAN1_DHCP_START' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
VLAN1_DHCP_END=$(grep 'VLAN1_DHCP_END' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
VLAN2_DHCP_START=$(grep 'VLAN2_DHCP_START' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')
VLAN2_DHCP_END=$(grep 'VLAN2_DHCP_END' goad.conf | cut -d'=' -f2 | tr -d '[:space:]')

# Escape values for sed
escape_for_sed() {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# Replace values in modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|ansible_host: .*|ansible_host: $(escape_for_sed "$PFS_LAN_IP")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(ansible_password:\s*\).*|\1$(escape_for_sed "$PFS_DEFAULT_PWD")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(new_pfs_pwd:\s*\).*|\1$(escape_for_sed "$PFS_PWD")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(new_pfs_pwd_hash:\s*\).*|\1$(escape_for_sed "$PFS_HASH")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PFS_WAN_IP:\s*\).*|\1$(escape_for_sed "$PFS_WAN_IP")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PM_DOMAIN:\s*\).*|\1$(escape_for_sed "$PROXM_DOMAIN")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PM_HOSTNAME:\s*\).*|\1$(escape_for_sed "$PROXM_HOSTNAME")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PM_DNS_HOSTNAME:\s*\).*|\1$(escape_for_sed "$PROXM_DNS_HOSTNAME")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PM_DNS_IP:\s*\).*|\1$(escape_for_sed "$PROXM_DNS_IP")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(whitelist_ssh_network:\s*\).*|\1$(escape_for_sed "$PFS_whitelist_ssh_network")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(WAN_NETWORK:\s*\).*|\1$(escape_for_sed "$PFS_WAN_NETWORK")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(WAN_MASK:\s*\).*|\1$(escape_for_sed "$PFS_WAN_MASK")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(LAN_NETWORK:\s*\).*|\1$(escape_for_sed "$PFS_LAN_NETWORK")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(LAN_MASK:\s*\).*|\1$(escape_for_sed "$PFS_LAN_MASK")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PFS_WAN_INTERFACE:\s*\).*|\1$(escape_for_sed "$PFS_WAN_INTERFACE")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PFS_LAN_INTERFACE:\s*\).*|\1$(escape_for_sed "$PFS_LAN_INTERFACE")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PFS_OPTIONAL_INTERFACE:\s*\).*|\1$(escape_for_sed "$PFS_OPTIONAL_INTERFACE")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PFS_VLAN1_INTERFACE:\s*\).*|\1$(escape_for_sed "$PFS_VLAN1_INTERFACE")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PFS_VLAN2_INTERFACE:\s*\).*|\1$(escape_for_sed "$PFS_VLAN2_INTERFACE")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PFS_WAN_IPV4_ADDRESS:\s*\).*|\1$(escape_for_sed "$PFS_WAN_IPV4_ADDRESS")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PFS_WAN_GATEWAY:\s*\).*|\1$(escape_for_sed "$PFS_WAN_GATEWAY")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PFS_LAN_IPV4_ADDRESS:\s*\).*|\1$(escape_for_sed "$PFS_LAN_IPV4_ADDRESS")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(PFS_LAN_GATEWAY:\s*\).*|\1$(escape_for_sed "$PFS_LAN_GATEWAY")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(VLAN1_NETWORK:\s*\).*|\1$(escape_for_sed "$VLAN1_NETWORK")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(VLAN2_NETWORK:\s*\).*|\1$(escape_for_sed "$VLAN2_NETWORK")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(VLANTAG1:\s*\).*|\1$(escape_for_sed "$VLANTAG1")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(VLANTAG1_ipv4:\s*\).*|\1$(escape_for_sed "$VLANTAG1_ipv4")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(VLANTAG2:\s*\).*|\1$(escape_for_sed "$VLANTAG2")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(VLANTAG2_ipv4:\s*\).*|\1$(escape_for_sed "$VLANTAG2_ipv4")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(VLAN1_DHCP_START:\s*\).*|\1$(escape_for_sed "$VLAN1_DHCP_START")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(VLAN1_DHCP_END:\s*\).*|\1$(escape_for_sed "$VLAN1_DHCP_END")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(VLAN2_DHCP_START:\s*\).*|\1$(escape_for_sed "$VLAN2_DHCP_START")|" modules/pfsense/scripts/ansible/inventory.yml
sed -i "s|\(VLAN2_DHCP_END:\s*\).*|\1$(escape_for_sed "$VLAN2_DHCP_END")|" modules/pfsense/scripts/ansible/inventory.yml


echo "********************************************************************************************"
echo "modify pfsense.sh with content from goad.conf"
echo "********************************************************************************************"

cp modules/pfsense/scripts/pfsense.template.sh modules/pfsense/scripts/pfsense.sh
chmod 755 modules/pfsense/scripts/pfsense.sh

# Read the WAN interface value from goad.conf
wan_interface_value=$(grep 'PFS_WAN_INTERFACE=' goad.conf | cut -d'=' -f2)
lan_interface_value=$(grep 'PFS_LAN_INTERFACE=' goad.conf | cut -d'=' -f2)
optional_interface_value=$(grep 'PFS_OPTIONAL_INTERFACE=' goad.conf | cut -d'=' -f2)
wan_ip_value=$(grep 'PFS_WAN_IP=' goad.conf | cut -d'=' -f2)
wan_gateway_value=$(grep 'PFS_WAN_GATEWAY=' goad.conf | cut -d'=' -f2)
lan_ipv4_value=$(grep 'PFS_LAN_IPV4_ADDRESS=' goad.conf | cut -d'=' -f2)
lan_gateway_value=$(grep 'PFS_LAN_GATEWAY=' goad.conf | cut -d'=' -f2)
vlan2_dhcp_start_value=$(grep 'VLAN2_DHCP_START=' goad.conf | cut -d'=' -f2)
vlan2_dhcp_end_value=$(grep 'VLAN2_DHCP_END=' goad.conf | cut -d'=' -f2)

# Transform the WAN interface value to the desired format with dashes
transformed_wan_value=$(echo $wan_interface_value | sed 's/./&-/g' | sed 's/-$//')
transformed_lan_value=$(echo $lan_interface_value | sed 's/./&-/g' | sed 's/-$//')
transformed_optional_interface_value=$(echo $optional_interface_value | sed 's/./&-/g' | sed 's/-$//')
transformed_wan_ip_value=$(echo $wan_ip_value | sed 's/./&-/g' | sed 's/-$//')
transformed_wan_gateway_value=$(echo $wan_gateway_value | sed 's/./&-/g' | sed 's/-$//')
transformed_lan_ipv4_value=$(echo $lan_ipv4_value | sed 's/./&-/g' | sed 's/-$//')
transformed_lan_gateway_value=$(echo $lan_gateway_value | sed 's/./&-/g' | sed 's/-$//')
transformed_vlan2_dhcp_start_value=$(echo $vlan2_dhcp_start_value | sed 's/./&-/g' | sed 's/-$//')
transformed_vlan2_dhcp_end_value=$(echo $vlan2_dhcp_end_value | sed 's/./&-/g' | sed 's/-$//')

# Replace dots with "dot"
transformed_wan_ip_value=$(echo $transformed_wan_ip_value | sed 's/\./dot/g')
transformed_wan_gateway_value=$(echo $transformed_wan_gateway_value | sed 's/\./dot/g')
transformed_lan_ipv4_value=$(echo $transformed_lan_ipv4_value | sed 's/\./dot/g')
transformed_lan_gateway_value=$(echo $transformed_lan_gateway_value | sed 's/\./dot/g')
transformed_vlan2_dhcp_start_value=$(echo $transformed_vlan2_dhcp_start_value | sed 's/\./dot/g')
transformed_vlan2_dhcp_end_value=$(echo $transformed_vlan2_dhcp_end_value | sed 's/\./dot/g')


# Replace the WAN placeholder in modules/pfsense/scripts/pfsense.sh with the transformed WAN value
sed -i "s/chg_wan_interface/$transformed_wan_value/" modules/pfsense/scripts/pfsense.sh
# Replace the LAN placeholder in modules/pfsense/scripts/pfsense.sh with the transformed LAN value
sed -i "s/chg_lan_interface/$transformed_lan_value/" modules/pfsense/scripts/pfsense.sh
# Replace the OPTIONAL placeholder in modules/pfsense/scripts/pfsense.sh with the transformed OPTIONAL value
sed -i "s/chg_opt_interface/$transformed_optional_interface_value/" modules/pfsense/scripts/pfsense.sh
# Replace the WAN IP placeholder in modules/pfsense/scripts/pfsense.sh with the transformed WAN IP value
sed -i "s/change_pfs_wan_ip/$transformed_wan_ip_value/" modules/pfsense/scripts/pfsense.sh
# Replace the WAN Gateway placeholder in modules/pfsense/scripts/pfsense.sh with the transformed WAN Gateway value
sed -i "s/change_pfs_wan_gateway/$transformed_wan_gateway_value/" modules/pfsense/scripts/pfsense.sh
# Replace the LAN IPv4 placeholder in modules/pfsense/scripts/pfsense.sh with the transformed LAN IPv4 value
sed -i "s/change_pfs_lan_ip/$transformed_lan_ipv4_value/" modules/pfsense/scripts/pfsense.sh
# Replace the LAN Gateway placeholder in modules/pfsense/scripts/pfsense.sh with the transformed LAN Gateway value
sed -i "s/change_pfs_lan_gateway/$transformed_lan_gateway_value/" modules/pfsense/scripts/pfsense.sh
# Replace the VLAN2 DHCP start placeholder in modules/pfsense/scripts/pfsense.sh with the transformed VLAN2 DHCP start value
sed -i "s/change_pfs_lan_dhcp_start/$transformed_vlan2_dhcp_start_value/" modules/pfsense/scripts/pfsense.sh
# Replace the VLAN2 DHCP end placeholder in modules/pfsense/scripts/pfsense.sh with the transformed VLAN2 DHCP end value
sed -i "s/change_pfs_lan_dhcp_end/$transformed_vlan2_dhcp_end_value/" modules/pfsense/scripts/pfsense.sh

echo ''
echo ''

echo "********************************************************************************************"
echo "install and autoconfigure pfsense vm"
echo "********************************************************************************************"


terraform init
terraform apply -var-file="dev.tfvars" --auto-approve

echo ''
echo ''

echo "********************************************************************************************"
echo "delete terraform token, terraform user, terraform role"
echo "********************************************************************************************"
pvesh delete /access/users/$trf_user@pve/token/$trf_token_name
pveum user delete $trf_user@pve
pveum role delete $trf_role