#!/bin/bash

# Ce script installe Docker sur Debian 12 avec des étapes interactives
# Assurez-vous de l'exécuter en tant que super-utilisateur ou avec sudo

# Fonctions d'affichage avec couleurs
INFO="\033[1;34m[INFO]\033[0m"
SUCCESS="\033[1;32m[SUCCESS]\033[0m"
WARNING="\033[1;33m[WARNING]\033[0m"
ERROR="\033[1;31m[ERROR]\033[0m"
RESET="\033[0m"

# Fonction pour demander confirmation
demander_confirmation() {
    echo -e "$1 (oui/non)"
    read reponse
    if [[ "$reponse" == "oui" ]]; then
        return 0
    else
        return 1
    fi
}

# Étape 1 : Suppression des anciennes versions de Docker
if demander_confirmation "$INFO Voulez-vous supprimer les anciennes versions de Docker ?"; then
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg
    done
    echo -e "$SUCCESS Anciennes versions de Docker supprimées."
else
    echo -e "$WARNING Passage à l'étape suivante sans supprimer les anciennes versions."
fi

# Étape 2 : Installation de Docker
if demander_confirmation "$INFO Voulez-vous installer Docker (installation basée sur la documentation officielle) ?"; then
    # Mise à jour des paquets
    sudo apt-get update
    
    # Installation des dépendances
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Ajout de la clé GPG officielle de Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Ajout du dépôt Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Mise à jour des dépôts apt
    sudo apt-get update

    # Installation des paquets Docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Activation et démarrage du service Docker
    sudo systemctl enable docker
    sudo systemctl start docker

    # Vérification de l'installation
    sudo docker run hello-world && echo -e "$SUCCESS Docker installé avec succès."
else
    echo -e "$WARNING Docker n'a pas été installé."
fi

# Étape 3 : Ajout d'un utilisateur au groupe Docker
if demander_confirmation "$INFO Voulez-vous ajouter un utilisateur au groupe Docker ?"; then
    echo "Veuillez entrer le nom de l'utilisateur :"
    read utilisateur
    if id "$utilisateur" &>/dev/null; then
        sudo usermod -aG docker $utilisateur
        echo -e "$SUCCESS L'utilisateur $utilisateur a été ajouté au groupe docker. Vous devrez vous déconnecter et vous reconnecter pour que les changements prennent effet."
    else
        echo -e "$ERROR L'utilisateur $utilisateur n'existe pas. Veuillez vérifier le nom de l'utilisateur."
    fi
else
    echo -e "$WARNING Aucun utilisateur n'a été ajouté au groupe Docker."
fi

# Étape 4 : Installation d'une interface graphique pour Docker
if demander_confirmation "$INFO Voulez-vous installer une interface graphique pour Docker ?"; then
    echo "Choisissez une interface graphique : 1 - Portainer, 2 - Rancher (veuillez ne pas choisir Rancher car cette partie du script est à corriger)"
    read choix_interface
    
    if [ "$choix_interface" = "1" ]; then
        echo "Quelle version de Portainer souhaitez-vous installer ? (Community Edition [CE]/Enterprise Edition [EE])"
        read version_portainer
        
        if [ "$version_portainer" = "CE" ]; then
            echo "Création du conteneur Portainer Community Edition..."
            sudo docker run -d \
              -p 8000:8000 -p 9000:9000 -p 9443:9443 \
              --name=portainer-container \
              --restart=always \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v portainer-volume:/data \
              portainer/portainer-ce:latest && echo -e "$SUCCESS Portainer CE installé avec succès."
        elif [ "$version_portainer" = "EE" ]; then
            echo "Création du conteneur Portainer Enterprise Edition..."
            sudo docker run -d \
              -p 8000:8000 -p 9000:9000 -p 9443:9443 \
              --name=portainer-container \
              --restart=always \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v portainer-volume:/data \
              portainer/portainer-ee:latest && echo -e "$SUCCESS Portainer EE installé avec succès."
        else
            echo -e "$WARNING Version invalide. Aucune installation de Portainer n'a été effectuée."
        fi
        
    elif [ "$choix_interface" = "2" ]; then
        sudo docker run -d \
          --name rancher \
          --restart=always \
          -p 80:80 -p 443:443 \
          rancher/rancher:latest && echo -e "$SUCCESS Rancher installé avec succès."
    else
        echo -e "$WARNING Aucune interface graphique sélectionnée."
    fi
else
    echo -e "$WARNING Aucune interface graphique n'a été installée."
fi

# Étape 5 : Conseils pour bien démarrer
if demander_confirmation "$INFO Voulez-vous des conseils et des liens pour bien démarrer avec Docker ?"; then
    echo -e "$INFO Consultez les ressources suivantes :"
    echo -e "$INFO Documentation officielle Docker : https://docs.docker.com/"
    echo -e "$INFO Tutoriels Docker : https://docs.docker.com/get-started/"
else
    echo -e "$WARNING Aucun lien ou conseil supplémentaire fourni."
fi

# Fin du script
echo -e "$SUCCESS Script terminé. Merci d'avoir utilisé cet installateur Docker interactif."
