#!/bin/bash
set -e

#If not launched with sudo
if [[ $UID != 0 ]];
then
    echo "Please run this script with sudo:"
    echo "sudo bash $0 $*"
    exit 1
fi

#Ask if we want remove all machine before continue if vms are already installed
#Verify if virtualbox is installed
if [ $(dpkg-query -W -f='${Status}' virtualbox 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo "Virtualbox will be installed ..."
  apt-get -yq install virtualbox > /dev/null && echo "Virtualbox installed."
else
  if [ $(VBoxManage list vms | grep -E "gitlab_server|front_server|back_server|database_server" | wc -l) -gt 0 ];
  then
      echo "VMs already installed. Needs to reinstall them (re-create) for continue ! Accept ? (y/n)"
      read accept
      if [ $accept == 'y' ];
      then
        killall -9 VBoxHeadless && vagrant destroy && echo "all processes killed"
        vboxmanage unregistervm gitlab_server --delete >> /dev/null
        vboxmanage unregistervm front_server --delete >> /dev/null
        vboxmanage unregistervm back_server --delete >> /dev/null
        vboxmanage unregistervm database_server --delete >> /dev/null
        echo "all VMs deleted"
      else
        exit 1
      fi
  fi
  echo "Virtualbox already installed"
fi

echo "Please enter new gitlab root password"
read gitlab_root_password

#Verify if git is installed
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo "Git will be installed ..."
  apt-get -yq install git > /dev/null && echo "Git installed."
else
  echo "Git already installed"
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
if [[ -d ~/vms ]];
then
  echo 'remove ~/vms folder'
  rm -R ~/vms
fi
mkdir ~/vms && echo "Folder vms created in ~/vms"

#delete, cp and link(re-link) available and enabled gitlab conf
if [[ -f /etc/nginx/sites-enabled/gitlab.server.conf ]];
then
  echo 'Remove nginx old gitlab config'
  rm -f /etc/nginx/sites-available/gitlab.server.conf
fi
echo 'Copy nginx gitlab config'
cp nginx-config/gitlab.server.conf /etc/nginx/sites-enabled/

#delete, cp and link(re-link) available and enabled front conf
if [[ -f /etc/nginx/sites-enabled/front.server.conf ]];
then
  echo 'Remove nginx old front config'
  rm -f /etc/nginx/sites-available/front.server.conf && rm -f /etc/nginx/sites-enabled/front.server.conf
fi
echo 'Copy nginx front config'
cp nginx-config/front.server.conf /etc/nginx/sites-enabled/

#copy Vagrantfile to ~/vms
echo 'Copy Vagrantfile to ~/vms'
cp Vagrantfile ~/vms/Vagrantfile

#copy playbooks config to ~/vms
echo 'Copy playbooks folder to ~/vms'
cp -R ansible ~/vms/ansible

#copy repositories to ~/vms
echo 'Copy repositories folder to ~/vms'
cp -R repositories ~/vms/repositories

#change directory
echo 'Change directory to ~/vms'
cd ~/vms

#Launch Vagrantfile build all VMs
echo 'Vagrant Up Vms'
GITLAB_ROOT_PASSWORD=${gitlab_root_password} vagrant up

#reload service nginx
echo 'Reload Nginx'
systemctl reload nginx

#Push repo front
cd ~/vms/repositories/front
git init
git add .
git commit -m "first commit"
git remote add origin http://root:${gitlab_root_password}@gitlab.server/root/front.git
git push --set-upstream origin master

#Push repo back
cd ~/vms/repositories/back
git init
git add .
git commit -m "first commit"
git remote add origin http://root:${gitlab_root_password}@gitlab.server/root/back.git
git push --set-upstream origin master

#key ssh files to variable
front_server_file=$(< ~/vms/.vagrant/machines/front_server/virtualbox/private_key)
back_server_file=$(< ~/vms/.vagrant/machines/back_server/virtualbox/private_key)
database_server_file=$(< ~/vms/.vagrant/machines/database_server/virtualbox/private_key)

#hosts file to variable
hosts_file=$(< ~/vms/ansible/hosts_gitlab_server)

#Get gilab private key
private_token=$(curl --data "grant_type=password&username=root&password=${gitlab_root_password}" --request POST http://192.168.0.2/oauth/token -s | grep -o '"[^"]*"\s*:\s*"[^"]*"' | grep -E '^"(access_token)"' | sed -E 's/.*"access_token":"?([^,"]*)"?.*/\1/')

#add key ssh servers to variables
curl --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/1/variables" --form "key=ANSIBLE_KEY_SSH_FRONT" --form "value=${front_server_file}" --form "protected=true"
curl --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=ANSIBLE_KEY_SSH_BACK" --form "value=${back_server_file}" --form "protected=true"
curl --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=ANSIBLE_KEY_SSH_DATABASE" --form "value=${database_server_file}" --form "protected=true"

#add ansible hosts to variable gitlab
curl --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/1/variables" --form "key=ANSIBLE_HOSTS" --form "value=${hosts_file}" --form "protected=true"
curl --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=ANSIBLE_HOSTS" --form "value=${hosts_file}" --form "protected=true"
