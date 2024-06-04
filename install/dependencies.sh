#!/bin/bash
echo "----------------------------------------------"
echo "Download hashicorp gpg key"
echo "----------------------------------------------"
wget -O /tmp/hashicorp.gpg https://apt.releases.hashicorp.com/gpg | cat /tmp/hashicorp.gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpgecho "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

echo "----------------------------------------------"
echo "apt-update"
echo "----------------------------------------------"
sudo apt-get update

echo "----------------------------------------------"
echo "Install : sshpass gnupg software-properties-common terraform  ansible-core"
echo "----------------------------------------------"
pkgs=(sshpass gnupg software-properties-common terraform  ansible-core pwgen apache2-utils)
sudo apt-get -y --ignore-missing install "${pkgs[@]}"

echo "----------------------------------------------"
echo "install : pfsensible.core"
echo "----------------------------------------------"
ansible-galaxy collection install pfsensible.core

echo "----------------------------------------------"
echo "END"
echo "----------------------------------------------"