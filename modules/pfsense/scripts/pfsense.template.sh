#!/bin/bash

timerkey=0.2

#Wait for pfsence to start
sleep 30

#accept EULA
sleep $timerkey
qm sendkey $1 kp_enter

#Choose to install pfsense
sleep $timerkey
qm sendkey $1 kp_enter

#Select partition type = Guided Root_on-ZFS
sleep $timerkey
qm sendkey $1 kp_enter

#proceed with installation
sleep $timerkey
qm sendkey $1 kp_enter

#Stripe - No Redundancy
sleep $timerkey
qm sendkey $1 kp_enter

#Select drive
sleep $timerkey
qm sendkey $1 spc
sleep $timerkey
qm sendkey $1 kp_enter

#Confirm
sleep $timerkey
qm sendkey $1 tab
qm sendkey $1 kp_enter

#Reboot
sleep 10
qm sendkey $1 kp_enter

#Configure Pfsense
#first boot sleep
sleep 40
#Configure Vlan now
sleep $timerkey
qm sendkey $1 n-kp_enter

#select wan interface
sleep $timerkey
qm sendkey $1 chg_wan_interface-kp_enter

#select lan interface
sleep $timerkey
qm sendkey $1 chg_lan_interface-kp_enter

#select optional interface
sleep $timerkey
qm sendkey $1 chg_opt_interface-kp_enter-y-kp_enter

#wait for pfsense configuration
sleep 180
qm sendkey $1 2-kp_enter

#select wan interface and deny configuration over DHCP
qm sendkey $1 1-kp_enter
qm sendkey $1 n-kp_enter

#Enter WAN IPV4 ip adress and mask
qm sendkey $1 change_pfs_wan_ip-kp_enter
qm sendkey $1 3-0-kp_enter

#Set default gateway for WAN interface
qm sendkey $1 change_pfs_wan_gateway-kp_enter
qm sendkey $1 y-kp_enter
#Deny ipv6 configuration and do not configure ipv6 adress manually
qm sendkey $1 n-kp_enter
qm sendkey $1 kp_enter
#Deny enable DHCP on wan interface
qm sendkey $1 n-kp_enter

#revert http as the webConfigurator protocol
qm sendkey $1 y-kp_enter
qm sendkey $1 kp_enter
#Sleep for configurator to start
sleep 5
#Configure Lan interface
qm sendkey $1 2-kp_enter
qm sendkey $1 2-kp_enter
#Deny LAN configuration over DHCP
qm sendkey $1 n-kp_enter
#Enter firewall LAN ip adress
qm sendkey $1 change_pfs_lan_ip-kp_enter
#Enter LAN network mask
qm sendkey $1 2-4-kp_enter
#Enter LAN gateway
qm sendkey $1 change_pfs_lan_gateway-kp_enter
qm sendkey $1 change_pfs_lan_gateway-kp_enter
qm sendkey $1 y-kp_enter
#Deney ipv6 adres configuration for LAN over DHCP
qm sendkey $1 n-kp_enter-kp_enter
#Enable DHCP on LAN
qm sendkey $1 y-kp_enter
#Enter DHCP start adress for LAN
qm sendkey $1 change_pfs_lan_dhcp_start-kp_enter
qm sendkey $1 change_pfs_lan_dhcp_end-kp_enter
qm sendkey $1 kp_enter
#Sleep for configuration to be recorded and restart DHCP
sleep 5

#Enable qemu agent
qm set $1 --agent enabled=1
#Start and stop vm for agent to be qemu-agent to be enabled
qm stop $1
sleep 5
qm start $1
#Enable ssh
sleep 90
qm sendkey $1 1-4-kp_enter
qm sendkey $1 y
qm sendkey $1 kp_enter
#ENd of scritp
