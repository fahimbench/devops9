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

#Verify if nginx is installed
if [ $(dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo "Nginx will be installed ..."
  apt-get -yq install nginx > /dev/null && echo "nginx installed.";
else
  echo "Nginx already installed"
fi

#Configure new hostonly network with 192.168.0.1 if not exist
vboxhostonly=`ifconfig | grep -B 1 "inet 192.168.0.1  netmask 255.255.255.248" | head -n 1 | cut -d: -f 1`
if [ -z '$vboxhostonly' ];
then
  vboxhostonly=`vboxmanage hostonlyif create | sed -n "s/^.*'\(.*\)'.*$/\1/p"`
  vboxmanage hostonlyif ipconfig ${vboxhostonly} --ip 192.168.0.1 --netmask 255.255.255.248
  echo "${vboxhostonly} hostonly network created"
else
  echo "hostonly network 192.168.0.1 exists"
fi

#Create vms folder if not created yet and move on
if [[ ! -d ~/vms ]];
then
  mkdir ~/vms && echo "Folder vms created in ~/vms"
fi

if [[ -d ~/vms/ansible ]];
then
  rm -R ~/vms/ansible
fi
cp -R ansible ~/vms

#change directory
cd ~/vms


#Write in Vagrantfile the config
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
N = 3
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  HOST_CONFIG.each_with_index do |(hostname, basebox), index|
    config.vm.define hostname do |hname|
      hname.vm.box = basebox
      hname.vm.network 'private_network', ip: \"192.168.0.#{2+index}\", netmask: '255.255.255.248'
      hname.vm.provider 'virtualbox' do |v|
        v.name = hostname
        v.memory = 1024
        #v.customize ['modifyvm', hostname, '--nic2', 'hostonly', '--cableconnected2', 'on', '--hostonlyadapter2', '${vboxhostonly}']
      end
        if index == N
        hname.vm.provision :ansible do |ansible|
          # Disable default limit to connect to all the machines
          ansible.limit = 'all'
          ansible.inventory_path = \"ansible/hosts\"
          ansible.playbook = 'ansible/playbook.yml'
        end
      end
    end
  end
end" > Vagrantfile

#Launch Vagrantfile build all VMs
vagrant up

#Config Nginx reverse proxy gitlab and front
echo "
upstream gitlab {
  server 192.168.0.2;
}
server {
        listen   80;
        server_name  gitlab.server;
        access_log  /var/log/gitlab.access.log;
        error_log  /var/log/gitlab.nginx_error.log debug;
        location / {
                proxy_pass         http://gitlab;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
                root   /var/www/nginx-default;
        }

}" > /etc/nginx/sites-available/gitlab.server.conf

echo "
upstream front {
  server 192.168.0.3;
}
server {
        listen   80;
        server_name  front.server;
        access_log  /var/log/front.access.log;
        error_log  /var/log/front.nginx_error.log debug;
        location / {
                proxy_pass         http://front;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
                root   /var/www/nginx-default;
        }

}" > /etc/nginx/sites-available/front.server.conf

#delete and link(re-link) available and enabled
rm /etc/nginx/sites-enabled/gitlab.server.conf
rm /etc/nginx/sites-enabled/front.server.conf
ln -s /etc/nginx/sites-available/gitlab.server.conf /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/front.server.conf /etc/nginx/sites-enabled/

#reload service
systemctl restart nginx