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

# Basculer SELinux en mode permissif
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

# Configurer l'affichage en temps réel
echo "::"
echo -e ":: Configuration de l'affichage en temps réel... \c"
sleep $DELAY
cat $CWD/config/sysctl.d/inotify.conf > /etc/sysctl.d/inotify.conf
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

# Quelques options pratiques pour Vim
echo "::"
echo -e ":: Configuration de Vim... \c"
sleep $DELAY
cat $CWD/config/vim/vimrc > /etc/vimrc
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Activer les dépôts [base], [updates] et [extras] avec une priorité de 1
echo "::"
echo -e ":: Configuration des dépôts de paquets officiels... \c"
sleep $DELAY
cat $CWD/config/yum/CentOS-Base.repo > /etc/yum.repos.d/CentOS-Base.repo
sed -i -e 's/installonly_limit=5/installonly_limit=2/g' /etc/yum.conf
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Configurer le dépôt CR sans l'activer
echo "::"
echo -e ":: Configuration du dépôt de paquets CR... \c"
sleep $DELAY
cat $CWD/config/yum/CentOS-CR.repo > /etc/yum.repos.d/CentOS-CR.repo
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Activer la gestion des Delta RPM
if ! rpm -q deltarpm 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Activer la gestion des Delta RPM... \c"
  yum -y install deltarpm >> $LOG 2>&1
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Mise à jour initiale
echo "::"
echo -e ":: Mise à jour initiale du système... \c"
yum -y update >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Installer le plugin Yum-Priorities
if ! rpm -q yum-plugin-priorities 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Installation du plugin Yum-Priorities... \c"
  yum -y install yum-plugin-priorities >> $LOG 2>&1
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Activer le dépôt [epel] avec une priorité de 10
if ! rpm -q epel-release 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Configuration du dépôt de paquets EPEL... \c"
  rpm --import http://mirrors.ircam.fr/pub/fedora/epel/RPM-GPG-KEY-EPEL-7 >> $LOG 2>&1
  yum -y install epel-release >> $LOG 2>&1
  cat $CWD/config/yum/epel.repo > /etc/yum.repos.d/epel.repo
  cat $CWD/config/yum/epel-testing.repo > /etc/yum.repos.d/epel-testing.repo
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Activer le dépôt [nux-dextop] avec une priorité de 10
if ! rpm -q nux-dextop-release 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Configuration du dépôt de paquets Nux-Dextop... \c"
  yum -y localinstall $CWD/config/yum/nux-dextop-release-*.rpm >> $LOG 2>&1
  rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-nux.ro >> $LOG 2>&1
  cat $CWD/config/yum/nux-dextop.repo > /etc/yum.repos.d/nux-dextop.repo
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Activer le dépôt [adobe-linux-x86_64] avec une priorité de 10
if ! rpm -q adobe-release-x86_64 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Configuration du dépôt de paquets Adobe... \c"
  yum -y localinstall $CWD/config/yum/adobe-release-*.rpm >> $LOG 2>&1
  rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux >> $LOG 2>&1
  cat $CWD/config/yum/adobe-linux-x86_64.repo > /etc/yum.repos.d/adobe-linux-x86_64.repo
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Configurer les dépôts [elrepo], [elrepo-kernel], etc. sans les activer
if ! rpm -q elrepo-release 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Configuration du dépôt de paquets ELRepo... \c"
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org >> $LOG 2>&1
  yum -y localinstall $CWD/config/yum/elrepo-release-*.rpm >> $LOG 2>&1
  cat $CWD/config/yum/elrepo.repo > /etc/yum.repos.d/elrepo.repo
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Activer le dépôt [microlinux] avec une priorité de 1
if [ ! -f /etc/yum.repos.d/microlinux.repo ]; then
  echo "::"
  echo -e ":: Configuration du dépôt Microlinux... \c"
  sleep $DELAY
  rpm --import https://centos.microlinux.fr/centos/RPM-GPG-KEY-microlinux >> $LOG 2>&1
  cat $CWD/config/yum/microlinux.repo > /etc/yum.repos.d/microlinux.repo
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Installer les outils Linux listés dans config/pkglists/outils-linux.txt
echo "::"
echo -e ":: Installation des outils système Linux... \c"
PAQUETS=$(egrep -v '(^\#)|(^\s+$)' $CWD/config/pkglists/outils-linux.txt)
yum -y install $PAQUETS >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Installer le groupe de paquets X Window System
echo "::"
echo -e ":: Installation du serveur graphique X Window... \c"
yum -y groupinstall "X Window System" >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Installer le groupe de paquets Xfce
echo "::"
echo -e ":: Installation du bureau Xfce... \c"
yum -y groupinstall "Xfce" >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Installer les ajouts et les applications
echo "::"
echo -e ":: Installation des ajouts et des applications... \c"
BUREAU=$(egrep -v '(^\#)|(^\s+$)' $CWD/config/pkglists/bureau-xfce.txt)
yum -y install $BUREAU >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Supprimer les paquets inutiles listés dans config/pkglists/cholesterol.txt
echo "::"
echo -e ":: Suppression des paquets inutiles... \c"
CHOLESTEROL=$(egrep -v '(^\#)|(^\s+$)' $CWD/config/pkglists/cholesterol.txt)
yum -y remove $CHOLESTEROL >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Installer les polices Apple
if [ ! -d /usr/share/fonts/apple-fonts ]; then
  cd /tmp
  rm -rf /usr/share/fonts/apple-fonts
  echo "::"
  echo -e ":: Installation des polices TrueType Apple... \c"
  wget -c --no-check-certificate \
    https://www.microlinux.fr/download/FontApple.tar.xz >> $LOG 2>&1
  mkdir /usr/share/fonts/apple-fonts
  tar xvf FontApple.tar.xz >> $LOG 2>&1
  mv Lucida*.ttf Monaco.ttf /usr/share/fonts/apple-fonts/
  fc-cache -f -v >> $LOG 2>&1
  rm -f FontApple.tar.xz
  cd - >> $LOG 2>&1
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Installer la police Eurostile
if [ ! -d /usr/share/fonts/eurostile ]; then
  cd /tmp
  rm -rf /usr/share/fonts/eurostile
  echo "::"
  echo -e ":: Installation de la police TrueType Eurostile... \c"
  wget -c --no-check-certificate \
    https://www.microlinux.fr/download/Eurostile.zip >> $LOG 2>&1
  unzip Eurostile.zip -d /usr/share/fonts/ >> $LOG 2>&1
  mv /usr/share/fonts/Eurostile /usr/share/fonts/eurostile
  fc-cache -f -v >> $LOG 2>&1
  rm -f Eurostile.zip
  cd - >> $LOG 2>&1
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Autoriser les polices Type-1 pour Ghostscript
echo "::"
echo -e ":: Autoriser les polices Type-1 pour Ghostscript... \c"
sleep $DELAY
cat $CWD/config/infinality/infinality.conf > /etc/fonts/infinality/infinality.conf
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Installer les fonds d'écran Microlinux
if [ ! -f /usr/share/backgrounds/.microlinux ]; then
  cd /tmp
  echo "::"
  echo -e ":: Installation des fonds d'écran Microlinux... \c"
  wget -c --no-check-certificate \
    https://www.microlinux.fr/download/microlinux-wallpapers.tar.gz >> $LOG 2>&1
  tar xvzf microlinux-wallpapers.tar.gz >> $LOG 2>&1 
  cp -f microlinux-wallpapers/* /usr/share/backgrounds/ >> $LOG 2>&1
  touch /usr/share/backgrounds/.microlinux >> $LOG 2>&1
  rm -f microlinux-wallpapers.tar.gz
  cd - >> $LOG 2>&1
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Installer Gtkcdlabel
if [ ! -f /usr/bin/gtkcdlabel.py ]; then
  echo "::"
  echo -e ":: Installation de l'application Gtkcdlabel... \c"
  cd /tmp
  wget -c --no-check-certificate \
    https://www.microlinux.fr/download/gtkcdlabel-1.15.tar.bz2 >> $LOG 2>&1
  tar xvjf gtkcdlabel-1.15.tar.bz2 -C / >> $LOG 2>&1
  rm -f gtkcdlabel-1.15.tar.bz2
  cd - >> $LOG 2>&1
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Personnaliser les entrées du menu Xfce
echo "::"
echo -e ":: Personnalisation des entrées de menu Xfce... \c"
sleep $DELAY
$CWD/menus.sh >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Personnaliser GDM
if [ ! -f /etc/dconf/profile/gdm ]; then
  echo "::"
  echo -e ":: Personnalisation de GDM... \c"
  cat $CWD/config/gdm/gdm > /etc/dconf/profile/gdm
  cat $CWD/config/gdm/00-login-screen > /etc/dconf/db/gdm.d/00-login-screen
  cat $CWD/config/gdm/01-logo > /etc/dconf/db/gdm.d/01-logo
  cp $CWD/config/gdm/microlinux-logo.png /usr/share/pixmaps/ >> $LOG 2>&1
  dconf update
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Installer le profil par défaut des utilisateurs
echo "::"
echo -e ":: Installation du profil par défaut des utilisateurs... \c"
sleep $DELAY
$CWD/profil.sh >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Avertissement final
echo
echo "     L'installation du bureau est terminée. À présent," 
echo "     vous pouvez créer un ou plusieurs utilisateurs :"
echo
echo "       # useradd -c \"Prénom Nom\" utilisateur"
echo "       # passwd utilisateur"
echo
echo "     Redémarrez le PC et supprimez l'utilisateur initial :"
echo
echo "       # userdel -r install"
echo
echo "     Notez que SELinux est actuellement en mode permissif."
echo
sleep $DELAY

echo

exit 0
