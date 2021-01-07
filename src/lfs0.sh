#!/bin/bash
set -xe
SYS="ubuntu" # or ubuntu
[ ! -z "$1" ] && SYS="$1"
if [ $SYS == "ubuntu" ]; then
  # TODO: On ubuntu desktop, need to add "universe multiverse" to 
  # the focal line of /etc/apt/sources.list, this allows texinfo to
  # be installed
  sudo sed -i '/ focal /s/$/ universe multiverse/' /etc/apt/sources.list
fi
# This script seeks to set up a system for lfs
wget http://jcantrell.me/jordan/files/setup/jopm/jopm.sh
# Run basic workstation setup
sh jopm.sh usecase minimumcore
sh jopm.sh install valgrind
if [ $SYS == "tinycore" ]; then
  # Blindly clobber sh and make it a link to bash
  sudo rm /bin/sh
  sudo ln -s /usr/local/bin/bash /bin/sh
  sudo rm /usr/bin/ar
  sudo cp -P /usr/local/bin/* /bin
  sudo cp -P /usr/local/sbin/* /sbin
fi
wget http://jcantrell.me:3000/jcantrell/lfs/raw/master/src/lfs1.sh
