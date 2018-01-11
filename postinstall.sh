#!/bin/bash
#
# postinstall.sh
#
# Script post-installation pour CentOS 7 + Xfce
#
# (c) Nicolas Kovacs, 2018

# Exécuter en tant que root
if [ $EUID -ne 0 ] ; then
  echo "::"
  echo ":: Vous devez être root pour exécuter ce script."
  echo "::"
  exit 1
fi

# Répertoire courant
CWD=$(pwd)

# Interrompre en cas d'erreur
set -e

# Couleurs
VERT="\033[01;32m"
GRIS="\033[00m"

# Journal
LOG=/tmp/postinstall.log

# Pause entre les opérations
DELAY=1

# Nettoyer le fichier journal
echo > $LOG

# Bannière
sleep $DELAY
echo
echo "     #######################################" | tee -a $LOG
echo "     ### CentOS 7 Xfce Post-installation ###" | tee -a $LOG
echo "     #######################################" | tee -a $LOG
echo | tee -a $LOG
sleep $DELAY
echo "     Pour suivre l'avancement des opérations, ouvrez une"
echo "     deuxième console et invoquez la commande suivante :"
echo
echo "       # tail -f /tmp/postinstall.log"
echo
sleep $DELAY

# Mise à jour initiale
echo -e ":: Mise à jour initiale du système... \c"
yum -y update >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Basculer SELinux en mode permissif
echo "::"
echo -e ":: Basculer SELinux en mode permissif... \c"
sleep $DELAY
sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
setenforce 0
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Pour l'instant on n'utilise que l'IPv4
echo "::"
echo -e ":: Désactivation de l'IPv6... \c"
sleep $DELAY
cat $CWD/config/sysctl.d/disable-ipv6.conf > /etc/sysctl.d/disable-ipv6.conf
if [ -f /etc/ssh/sshd_config ]; then
  sed -i -e 's/#AddressFamily any/AddressFamily inet/g' /etc/ssh/sshd_config
  sed -i -e 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config
fi
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Personnalisation du shell Bash pour root
echo "::"
echo -e ":: Configuration du shell Bash pour l'administrateur... \c"
sleep $DELAY
cat $CWD/config/bash/bashrc-root > /root/.bashrc 
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Personnalisation du shell Bash pour les utilisateurs
echo "::"
echo -e ":: Configuration du shell Bash pour les utilisateurs... \c"
sleep $DELAY
cat $CWD/config/bash/bashrc-users > /etc/skel/.bashrc
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

echo

exit 0
