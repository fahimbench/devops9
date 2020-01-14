# NSA 9

## Création des VMs

Lancer le fichier script.sh :
```bash
sudo bash script.sh
```

Ce script installera les packages suivants sur la machine hôte :

- Ansible
- Vagrant
- Virtualbox
- Nginx

Il créera un nouvel adapteur réseau pour Virtualbox (si n'existe pas déjà) :

**Adresse IP** : 192.168.0.1
**Sous-masque** : 255.255.255.248

Il configurera et lancera les VMs suivante :

|nom|network|ram|
|---|-------|---|
|gitlab_server|IP:192.168.0.2 - 255.255.255.248|1024Mo
|front_server|IP:192.168.0.3 - 255.255.255.248|1024Mo
|back_server|IP:192.168.0.4 - 255.255.255.248|1024Mo
|database_server|IP:192.168.0.5 - 255.255.255.248|1024Mo

Pour voir les VMs
```bash
sudo virtualbox
```
Pour supprimer les VMs
```bash
sudo killall -9 VBoxHeadless && vagrant destroy
sudo vboxmanage unregistervm gitlab_server --delete
sudo vboxmanage unregistervm front_server --delete
sudo vboxmanage unregistervm back_server --delete
sudo vboxmanage unregistervm database_server --delete
```
#Ansible

La configuration ansible se trouve dans le dossier nommé ansible.

Il se lance en même temps que la création de nos VMs. 
Auquel cas vous devrez supprimez les VMs avec les commandes ci-dessus et relancer le script.