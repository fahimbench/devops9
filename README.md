# NSA 9

## Création des VMs

Lancer le fichier script.sh :
```bash
sudo bash script.sh
```
**Compatibilité -> distro se basant sur :** Ubuntu, Debian

**Configuration minimal :** 8Go RAM

Ce script installera les packages suivants sur la machine hôte :

- Ansible
- Vagrant
- Virtualbox
- Nginx

Il créera un nouvel adaptateur réseau pour Virtualbox (s'il n'existe pas déjà) :

**Adresse IP** : 192.168.0.1
**Sous-masque** : 255.255.255.248

Il configurera et lancera les VMs suivante :

|Nom|Network|RAM|OS|
|:---:|:-------:|:---:|:---:|
|gitlab_server|IP:192.168.0.2 - 255.255.255.248|4096Mo|Debian 10
|front_server|IP:192.168.0.3 - 255.255.255.248|1024Mo|Debian 10
|back_server|IP:192.168.0.4 - 255.255.255.248|1024Mo|Debian 10
|database_server|IP:192.168.0.5 - 255.255.255.248|1024Mo|Debian 10

Pour voir les VMs avec virtualbox ( via command line )
```bash
sudo virtualbox
```
Pour supprimer les VMs sans relancer le script :
```bash
sudo killall -9 VBoxHeadless && vagrant destroy
sudo vboxmanage unregistervm gitlab_server --delete
sudo vboxmanage unregistervm front_server --delete
sudo vboxmanage unregistervm back_server --delete
sudo vboxmanage unregistervm database_server --delete
```

Le script vous demandera de définir un mot de passe pour le compte &ldquo;root&rdquo; de Gitlab ainsi que le mot de passe du compte &ldquo;root&rdquo; de la base de données et gérera le reste tout seul.

# Installation de Gitlab-ce avec Ansible

Une fois les VMs installés Vagrant executera le playbook d'ansible (ansible/playbooks/gitlab_server.yml) qui permettra l'installation de gitlab-ce sur la machine d'ip 192.168.0.2 et le configurera pour accueillir les 2 projets : &ldquo;back&rdquo; et &ldquo;front&rdquo;.

Il mettra à jour le Debian installé plus tôt sur la machine et dans l'ordre :

- Installera les packets suivant :
     - git
     - apt-transport-https
     - ca-certificates
     - wget
     - software-properties-common
     - gnupg2
     - curl
     - python
     - python-pip
     - python-docker
     - docker-ce
- Créera 2 containers docker :
     - gitlab
     - gitlab-runner
- Testera si l'API du gitlab server est mis en place avant de passer à la suite
- Créera 2 runners
- Et finalement autorisera que ces 2 runners se lancent en parallèle (en concurrent pour ne pas attendre que l'un finisse avant de commencer l'autre)

# Push des 2 projets

Une fois l'environnement gitlab mis en place, le script initialisera ces projets et pushera sur le serveur gitlab avec l'utilisateur root et le mot de passe définit plus tôt (sans devoir créer à la main un projet)
```bash
#Push repo front
(cd ~/vms/repositories/front &&
git init &&
git add . &&
git commit -m "first commit" &&
git remote add origin http://root:${gitlab_root_password}@gitlab.server/root/front.git &&
git push --set-upstream origin master)

#Push repo back
(cd ~/vms/repositories/back &&
git init &&
git add . &&
git commit -m "first commit" &&
git remote add origin http://root:${gitlab_root_password}@gitlab.server/root/back.git &&
git push --set-upstream origin master)
```

# Définition des variables d'env. Gitlab

Gitlab permet grâce à son API de définir des variables d'environnement qui seront injectés lors du passage des pipelines et permettront de ne pas insérer dans nos projets en textes bruts des fichiers contenant des données sensibles. Mais pour se faire, il est nécessaire d'avoir une private key que l'on peut obtenir comme cela :

```bash
#Get gilab private key
private_token=$(curl --data "grant_type=password&username=root&password=${gitlab_root_password}" --request POST http://192.168.0.2/oauth/token -s | grep -o '"[^"]*"\s*:\s*"[^"]*"' | grep -E '^"(access_token)"' | sed -E 's/.*"access_token":"?([^,"]*)"?.*/\1/')
```

Et ainsi pouvoir créer nos variables :
```bash
#add key ssh servers variables to gitlab
curl -s --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/1/variables" --form "key=ANSIBLE_KEY_SSH_FRONT" --form "value=${front_server_file}" >> /dev/null
curl -s --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=ANSIBLE_KEY_SSH_BACK" --form "value=${back_server_file}" >> /dev/null
curl -s --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=ANSIBLE_KEY_SSH_DATABASE" --form "value=${database_server_file}" >> /dev/null

#add ansible hosts variables to gitlab
curl -s --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/1/variables" --form "key=ANSIBLE_HOSTS" --form "value=${hosts_file}" >> /dev/null
curl -s --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=ANSIBLE_HOSTS" --form "value=${hosts_file}" >> /dev/null

#add somes variables to gitlab
curl -s --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=DB_HOST" --form "value=192.168.0.5" >> /dev/null
curl -s --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=DB_PORT" --form "value=3306" >> /dev/null
curl -s --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=DB_DATABASE" --form "value=back" >> /dev/null
curl -s --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=DB_USERNAME" --form "value=deploy" >> /dev/null
curl -s --request POST --header "Authorization: Bearer ${private_token}" "http://192.168.0.2/api/v4/projects/2/variables" --form "key=DB_PASSWORD" --form "value=${db_password}" >> /dev/null
```

- Sur le projet front :
     - ANSIBLE_KEY_SSH_FRONT
     - ANSIBLE_HOSTS
- Sur le projet back :
     - ANSIBLE_KEY_SSH_BACK
     - ANSIBLE_KEY_SSH_DATABASE
     - ANSIBLE_HOSTS
     - DB_HOST
     - DB_PORT
     - DB_DATABASE
     - DB_USERNAME
     - DB_PASSWORD

Les fichiers contenant la clé SSH sont nécessaires, générés lorsque la VMs a été créer et stockés dans les variables du même nom.

Le fichier contenant les hosts et la configuration adéquat pour se connecter aux VMs sont stockés dans les variables du même nom.

```yaml
all:
  hosts:
    front_server:
      ansible_host: "192.168.0.3"
      ansible_ssh_port: "22"
      ansible_ssh_user: "vagrant"
      ansible_ssh_private_key_file: /etc/ansible/front_server
    back_server:
      ansible_host: "192.168.0.4"
      ansible_ssh_port: "22"
      ansible_ssh_user: "vagrant"
      ansible_ssh_private_key_file: /etc/ansible/back_server
    database_server:
      ansible_host: "192.168.0.5"
      ansible_ssh_port: "22"
      ansible_ssh_user: "vagrant"
      ansible_ssh_private_key_file: /etc/ansible/database_server
```

Pour la configuration d'une base de données et pour son accès, on stocke la valeur que nous demandera le fichier de configuration du back.

```env
DB_CONNECTION=mysql
DB_HOST=
DB_PORT=
DB_DATABASE=
DB_USERNAME=
DB_PASSWORD=
```
# CI/CD Pipeline

Une fois le projet push, gitlab detectera le fichier .gitlab-ci.yml contenu dans chaque projet et executera les instructions contenus. Il permettra entre autre :

- Pour le front :
     - De télécharger une image node:latest et d'y executer :
          - Builder le projet
          - Tester le projet
          - Deployer le projet sur le serveur **front_server**
- Pour le back :
     - De télécharger une image php:7.1 et d'y executer :
          - Deployer une base de données sur le serveur **database_server** et de migrer
          - Tester le projet
          - Deployer le projet sur le serveur **back_server** 


## Build, test et deploiement du front

Le front est développé à l'aide du framework Angular.

Pour builder :
```bash
npm run build --prod
```

Pour Tester :
```bash
npm run test
```

Le deploiement se fait à l'aide d'ansible
```bash
ansible-playbook playbook.yml
```

Ansible installera sur le serveur front_server :
- Packages :
     - nginx
- Configure nginx
- Copiera le dossier build généré vers /var/www/html/ 

## Build, test et deploiement du back

Pour éditer le .env on utilise la commande sed :
```bash
cp .env.example .env
sed -i "s/\(DB_HOST\s*=\s*\).*/\1$DB_HOST/" .env
sed -i "s/\(DB_PORT\s*=\s*\).*/\1$DB_PORT/" .env
sed -i "s/\(DB_DATABASE\s*=\s*\).*/\1$DB_DATABASE/" .env
sed -i "s/\(DB_USERNAME\s*=\s*\).*/\1$DB_USERNAME/" .env
sed -i "s/\(DB_PASSWORD\s*=\s*\).*/\1$DB_PASSWORD/" .env
``` 
Pour deployer la base de données on utilise ansible:
Ansible installera sur le serveur database_server :
- Packages :
     - software-properties-common
     - python-mysqldb
     - ufw
     - mariadb-client
     - mariadb-common
     - mariadb-server
- Configure un user deploy sur plusieurs hosts

Pour Migrer :
```bash
php artisan migrate
```

Pour Tester :
```bash
vendor/bin/phpunit
```

Ansible installera sur le serveur back_server :
- Packages :
     - php-fpm
     - php-mysql
     - nginx
- Configure nginx -> Pointe vers le dossier public
- Copiera le projet

# Résultats

![](https://i.goopics.net/xPKeW.png)