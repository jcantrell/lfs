#!/bin/bash
set -xe
SYS="tcl" # or ubuntu
# This script seeks to set up a system for lfs
wget http://jcantrell.me/jordan/files/setup.sh
wget http://jcantrell.me/jordan/files/usecases.sh
chmod +x setup.sh usecases.sh
# Run basic workstation setup
./usecases.sh workstation
# Blindly clobber sh and make it a link to bash
if [ $SYS == "tcl" ]; then
sudo rm /bin/sh
sudo ln -s /usr/local/bin/bash /bin/sh
fi

./setup.sh install_gzip
./setup.sh install_xz
if [ $SYS == "tcl" ]; then
./setup.sh install_coreutils
./setup.sh install_makeinfo
./setup.sh install_mkfs
./setup.sh install_wget
./setup.sh install_shadow
sudo rm /usr/bin/ar
sudo cp -P /usr/local/bin/* /bin
sudo cp -P /usr/local/sbin/* /sbin
sudo passwd root
fi
git clone http://jcantrell.me:3000/jcantrell/lfs.git
