# NSA-9

## Sommaire
* [Initialisation](https://github.com/fahimbench/devops9#initialisation)
* [Création et duplication VM modèle](https://github.com/fahimbench/devops9#cr%C3%A9ation-et-duplication-vm-mod%C3%A8le)
  * [Création](https://github.com/fahimbench/devops9#cr%C3%A9ation)
  * [Installation et configuration du Debian](https://github.com/fahimbench/devops9#installation-et-configuration-du-debian)
  * [Duplication](https://github.com/fahimbench/devops9#duplication)
* [Configuration Réseau](https://github.com/fahimbench/devops9#configuration-r%C3%A9seau)

## Initialisation
Télécharger VirtualBox : [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

Télécharger Debian 10.2 : [Debian 10.2](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-10.2.0-amd64-netinst.iso)

## Création et duplication VM Modèle
### Création
Suivre : [Création d'une nouvelle machine virtuelle dans VirtualBox](https://docs.oracle.com/cd/E26217_01/E35193/html/qs-create-vm.html)

**Minimum :** 512Mo de Ram et 8Go d'espace disque dur

À l'étape du choix de l'image, **prendre l'image du Debian précédemment téléchargé.**
### Installation et configuration du Debian

Sur le premier écran prendre **Install** et non **Graphical Install**.
![](https://www.howtoforge.com/images/featured/debian-10-server-installation.jpg)
 
Suivez les instructions.

À l'étape du choix des logiciels, il faut seulement sélectionner **SSH** et **utilitaires usuels du système**
![](https://i.stack.imgur.com/8OQdV.png)

À la fin la machine redémarre, vous pouvez l'éteindre pour qu'on puisse la **cloner**.

### Duplication


Il y a 4 duplications à faire.

| Nom des VMs    |
| -------------- |
| Gitlab server  |
| Front server   |
| Back server    |
| Database server|

Clic droit et Cloner sur la VM.

Lors du clonage dans les options proposés, n'oubliez pas de changer le **nom de la VM** (cf. Tableau ci-dessus) et générer une nouvelle **adresse MAC** ainsi que de le cloner intégralement.

![](https://i.imgur.com/L0l5fc9.png)

## Configuration Réseau

Dans le menu de VirtualBox -> **Fichier** -> **Gestionnaire de réseau hôte**

Désactiver le **serveur DHCP** et Configurer la carte manuellement comme suit:

| Propriété           | Valeur           |
| ------------------- | :--------------: |
| Adresse IPv4        | 192.168.0.1      |
| Masque réseau IPv4  | 255.255.255.248  |

Et appliquer !

Clic droit sur une VM -> **Configuration** -> **Réseau** -> **Onglet Carte 2** -> Sélectionner en **mode d'accés réseau** ‟Réseau privé hôte” et en nom sélectionner le **réseau hôte** précédemment créé.

Reproduire pour les autres VMs

Lancer une VM et se connecter en root.

Éditer le fichier /etc/network/interfaces qui permet de paramétrer l’accès de l'ordinateur au réseau.

```bash
vi /etc/network/interfaces
```

(cf. [Utilisation de vi](http://wiki.linux-france.org/wiki/Utilisation_de_vi))

Et ajouter les lignes suivantes à la fin du fichier :
```bash
auto enp0s8
iface enp0s8 inet static
    address 192.168.0.X
    submask 255.255.255.248
    gateway 192.168.0.6
```

Où **X** dans adress est : 

| Nom de la VM    | Valeur de X |
| --------------- | :---------: |
| Gitlab server   | 2           |
| Front server    | 3           |
| Back server     | 4           |
| Database server | 5           |

**Enregistrer** puis **reboot** la machine pour que les modifications soient prises en compte.

```bash
reboot
```

Répéter l'opération pour les autres VM

## Réglages du Pare-feu

| Nom de la VM    | Ports          |
| --------------- | :-------------:|
| Gitlab server   | 22,80,443,2289 |
| Front server    | 22,80,443      |
| Back server     | 22,80,443      |
| Database server | 22,3306        |

Télécharger [ufw](http://debian-facile.org/doc:systeme:ufw) :
```bash
apt install ufw
```

On active ufw pour les démarrages :
```bash
ufw enable
```

On autorise le service ou le port :
```bash
ufw allow XXX 
```
XXX étant le nom du service ou le port.
