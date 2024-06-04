#!/bin/bash

echo "Check interface names in /etc/network/interface before running this script"
echo "----------------------------------------------"
echo "Create static interfaces"
echo "----------------------------------------------"

cdr2mask ()
{
   # Number of args to shift, 255..255, first non-255 byte, zeroes
   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
   [ $1 -gt 1 ] && shift $1 || shift
   echo ${1-0}.${2-0}.${3-0}.${4-0} > /tmp/mask
}

while :; do
  read -p "Enter a number of interface you want to create between 2 and 5 (default 2): " if_number
  [[ ${if_number:=2} =~ ^[0-9]+$ ]] || { echo "input an integer between 1 and 5"; continue; }
  #echo $if_number
  if ((if_number >= 1 && if_number <= 5)); then
    break
  else
    echo "input an integer between 1 and 5"
  fi
done

for i in $(seq 1 $if_number); do
  while :; do
    if [[ $i -eq 1 ]];then
      read -p "Enter a valid ip adress number $i (defaults: 10.0.0.1): " ip
      [[ ${ip:=10.0.0.1} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo " Not a valid ip adress "; continue; }
    else
      read -p "Enter a valid ip adress number $i (defaults: 192.168.2.1): " ip
      [[ ${ip:=192.168.2.1} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo " Not a valid ip adress "; continue; }
    fi
    #echo $ip
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      break
    else
      echo " Not a valid ip adress"
    fi
  done

  while :; do
    netmask=''
    if [[ $i -eq 1 ]];then
      read -p "Enter network mask between 1 and 32 (default: 30): " mask
      [[ ${mask:=30} =~ ^[0-9]+$ ]] || { echo "input an integet between 1 and 32"; continue; }
    else
      read -p "Enter network mask between 1 and 32 (default: 24): " mask
      [[ ${mask:=24} =~ ^[0-9]+$ ]] || { echo "input an integet between 1 and 32"; continue; }
    fi
    #echo $mask
    if (($mask >= 1 && $mask <= 32)); then
     (cdr2mask $mask)
      netmask=$(cat "/tmp/mask")
      break
    else
      echo "input an integet between 1 and 32"
    fi
  done

  name="vmbr"
  while :; do
    if [[ $i -eq 1 ]];then
      read -p "Enter the bridge name to create vmbr? (default: 1): " if_name
      [[ ${if_name:=1} =~ ^[0-9]+$ ]] || { echo "Enter a number between 0 and 99"; continue; }
    else
      read -p "Enter the bridge name to create vmbr? (default: 2): " if_name
      [[ ${if_name:=2} =~ ^[0-9]+$ ]] || { echo "Enter a number between 0 and 99"; continue; }
    fi
    #echo $if_name
    if ((if_name >= 1 && if_name <= 99)); then
      name="$name$if_name"
      #echo $name
      break
    else
      echo "Enter a number between 0 and 99"
    fi
  done
  #echo $if_number $ip $netmask $name
  pvesh create /nodes/windows-perso/network -iface $name -type bridge -autostart true -address $ip -netmask $netmask
done

echo "----------------------------------------------"
echo "Create raw device for vlan"
echo "----------------------------------------------"
while :; do
    read -p "Enter the raw device vlan name vmbr? (default:3): " vlanvmbr
    [[ ${vlanvmbr:=3} =~ ^[0-9]+$ ]] || { echo "Enter a number between 0 and 99"; continue; }
    #echo $vlanvmbr
    if ((vlanvmbr >= 1 && vlanvmbr <= 99)); then
      name="$vlanvmbr"
      #echo $name
      break
    else
      echo "Enter a number between 0 and 99"
    fi
done
pvesh create /nodes/windows-perso/network -iface "vmbr"$name -type bridge -autostart true -bridge_vlan_aware yes

echo "----------------------------------------------"
echo "Create linux vlans devices for each vlan"
echo "----------------------------------------------"
while :; do
  read -p "Enter a number of vlans you wish to create (default:2): " if_number
  [[ ${if_number:=2} =~ ^[0-9]+$ ]] || { echo "input an integet between 1 and 5"; continue; }
  #echo $if_number
  if ((if_number >= 1 && if_number <= 5)); then
    break
  else
    echo "input an integer between 1 and 5"
  fi
done

for i in $(seq 1 $if_number); do
  while :; do
    if [[ $i -eq 1 ]];then
      read -p "Enter a number corresponding to the vlan id (defaults: 10): " if_vlanid
      [[ ${if_vlanid:=10} =~ ^[0-9]+$ ]] || { echo "input an integer"; continue; }
    else
      read -p "Enter a number corresponding to the vlan id (defaults: 20): " if_vlanid
      [[ ${if_vlanid:=20} =~ ^[0-9]+$ ]] || { echo "input an integer"; continue; }
    fi
    #echo $if_vlanid
    break
  done
  pvesh create /nodes/windows-perso/network -iface vlan$if_vlanid -type vlan -vlan-raw-device "vmbr"$vlanvmbr
done

echo "----------------------------------------------"
echo "Enter pfsense Wan Network and mask"
echo "----------------------------------------------"
while :; do
  read -p "Enter the wan network used by pfsense (default:10.0.0.0): " wannet #variable used to add post up and down rules to proxmox ($wannet and $wanmask)
  [[ ${wannet:=10.0.0.0} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo " Not a valid ip adress "; continue; }
  #echo $wannet
  if [[ $wannet =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    break
  else
    echo " Not a valid ip adress"
  fi
done

while :; do
  read -p "Enter wan network mask between 1 and 32 (default:30): " wanmask
  [[ ${wanmask:=30} =~ ^[0-9]+$ ]] || { echo "input an integet between 1 and 32"; continue; }
  #echo $wanmask
  if (($wanmask >= 1 && $wanmask <= 32)); then
    break
  else
    echo "input an integet between 1 and 32"
  fi
done

cp /etc/network/interfaces.new /etc/network/interfaces
rm /etc/network/interfaces.new
ifreload -a

echo "----------------------------------------------"
echo "Enable port forwarding and forward all traffic to pfsense"
echo "----------------------------------------------"

awk -v wannet="$wannet" -v wanmask="$wanmask" '
/^auto vmbr0$/ { print; in_vmbr0=1; next }
in_vmbr0 && /^auto/ {
    in_vmbr0=0
    print "        #---- Enable ip forwarding"
    print "        post-up echo 1 > /proc/sys/net/ipv4/ip_forward"
    print "        post-down echo 0 > /proc/sys/net/ipv4/ip_forward"
    print ""
    print "        #---- Exit network with vmbr0 ip address for all machines"
    print "        post-up   iptables -t nat -A POSTROUTING -s " wannet "/" wanmask " -o vmbr0 -j MASQUERADE"
    print "        post-down iptables -t nat -D POSTROUTING -s " wannet "/" wanmask " -o vmbr0 -j MASQUERADE"
    print ""
    print "        #---- allow ssh access without passing through pfsense"
    print "        post-up iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 22 -j ACCEPT"
    print "        post-down iptables -t nat -D PREROUTING -i vmbr0 -p tcp --dport 22 -j ACCEPT"
    print ""
    print "        #---- allow https access without passing through pfsense"
    print "        post-up iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 443 -j ACCEPT"
    print "        post-down iptables -t nat -D PREROUTING -i vmbr0 -p tcp --dport 443 -j ACCEPT"
    print ""
}
{ print }
END {
    if (in_vmbr0) {
        print "        #---- Enable ip forwarding"
        print "        post-up echo 1 > /proc/sys/net/ipv4/ip_forward"
        print "        post-down echo 0 > /proc/sys/net/ipv4/ip_forward"
        print ""
        print "        #---- Exit network with vmbr0 ip address for all machines"
        print "        post-up   iptables -t nat -A POSTROUTING -s " wannet "/" wanmask " -o vmbr0 -j MASQUERADE"
        print "        post-down iptables -t nat -D POSTROUTING -s " wannet "/" wanmask " -o vmbr0 -j MASQUERADE"
        print ""
        print "        #---- allow ssh access without passing through pfsense"
        print "        post-up iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 22 -j ACCEPT"
        print "        post-down iptables -t nat -D PREROUTING -i vmbr0 -p tcp --dport 22 -j ACCEPT"
        print ""
        print "        #---- allow https access without passing through pfsense"
        print "        post-up iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 443 -j ACCEPT"
        print "        post-down iptables -t nat -D PREROUTING -i vmbr0 -p tcp --dport 443 -j ACCEPT"
        print ""
    }
}
' /etc/network/interfaces > temp_file && mv temp_file /etc/network/interfaces

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf &> /dev/null

# cat >> /etc/network/interfaces << EOF
# #----PFSENSE
# #----redirect all to pfsense
# post-up iptables -t nat -A PREROUTING -i vmbr0 -j DNAT --to $wannet                                                                                                                                                                  
# post-down iptables -t nat -A PREROUTING -i vmbr0 -j DNAT --to $wannet
# #---- add SNAT WAN -> public ip   
# post-up iptables -t nat -A POSTROUTING -o vmbr0 -j SNAT -s $wannet/$wanmask --to-source $(ip addr show vmbr0 | grep "inet " |cut -d ' ' -f 6|cut -d/ -f 1)                      
# post-down iptables -t nat -D POSTROUTING -o vmbr0 -j SNAT -s $wannet/$wanmask --to-source $(ip addr show vmbr0 | grep "inet " |cut -d ' ' -f 6|cut -d/ -f 1)
# EOF

service networking restart