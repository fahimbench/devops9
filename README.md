# NSA-9
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

Clique droit et Cloner sur la VM.

Lors du clonage dans les options proposés, n'oubliez pas de changer le **nom de la VM** (cf. Tableau ci-dessus) et générer une nouvelle **adresse MAC** ainsi que de le cloner intégralement.

![](https://i.imgur.com/L0l5fc9.png)

## Configuration Réseau

Dans le menu de VirtualBox -> **Fichier** -> **Gestionnaire de réseau hôte**

Désactiver le **serveur DHCP** et Configurer la carte manuellement comme suit:
| Propriété           | Valeur           |
| ------------------- | :--------------: |
| Adresse IPv4        | 192.168.0.1      |
| Masque réseau IPv4  | 255.255.255.248  |

# WIP
