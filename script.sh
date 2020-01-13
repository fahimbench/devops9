#!/bin/bash

#If not launched with sudo
if [[ $UID != 0 ]];
then
    echo "Please run this script with sudo:"
    echo "sudo bash $0 $*"
    exit 1
fi

#Update
#echo "Update ..." && apt-get -qq update > /dev/null

#Verify if virtualbox is installed
if [ $(dpkg-query -W -f='${Status}' virtualbox 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo "Virtualbox will be installed ..."
  apt-get -yq install virtualbox > /dev/null && echo "Virtualbox installed."
else
  echo "Virtualbox already installed"
fi

#Verify if vagrant is installed
if [ $(dpkg-query -W -f='${Status}' vagrant 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo "Vagrant will be installed ..."
  apt-get -yq install vagrant > /dev/null && echo "Vagrant installed."
else
  echo "Vagrant already installed"
fi

#Verify if vagrant is installed
if [ $(dpkg-query -W -f='${Status}' ansible 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo "Ansible will be installed ..."
  apt-get -yq install ansible > /dev/null && echo "Ansible installed.";
else
  echo "Ansible already installed"
fi


vboxhostonly=`vboxmanage hostonlyif create | sed -n "s/^.*'\(.*\)'.*$/\1/p"`
vboxmanage hostonlyif ipconfig ${vboxhostonly} --ip 192.168.0.1 --netmask 255.255.255.248
echo "${vboxhostonly} hostonly network created"

#Create vms folder if not created yet and move on
if [[ ! -d ~/vms ]];
then
  mkdir ~/vms && echo "Folder vms created in ~/vms"
fi

#change directory
cd ~/vms

echo "# -*- mode: ruby -*-

# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = '2'

# declare the machine config in a hash
HOST_CONFIG = { 
  'gitlab_server' => 'bento/debian-10',
  'front_server' => 'bento/debian-10',
  'back_server' => 'bento/debian-10',
  'database_server' => 'bento/debian-10'
}

# create the vms
N = 5
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  HOST_CONFIG.each_with_index do |(hostname, basebox), index|
    config.vm.define hostname do |hname|
      hname.vm.box = basebox
      hname.vm.network 'private_network', ip: \"192.168.0.#{2+index}\", netmask: '255.255.255.248'
      hname.vm.provider 'virtualbox' do |v|
        v.name = hostname
        v.memory = 1024
        v.customize ['modifyvm', hostname, '--nic2', 'hostonly', '--cableconnected2', 'on', '--hostonlyadapter2', '${vboxhostonly}']
      end
      if machine_id == N
      machine.vm.provision :ansible do |ansible|
        # Disable default limit to connect to all the machines
        ansible.limit = 'all'
        ansible.playbook = 'playbook.yml'
      end
    end
  end
end" > Vagrantfile
 
vagrant up
