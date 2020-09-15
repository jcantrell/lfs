#!/bin/bash
set -xe
# This script seeks to set up a system for lfs
wget http://jcantrell.me/jordan/files/setup.sh
wget http://jcantrell.me/jordan/files/usecases.sh
chmod +x setup.sh usecases.sh
# Run basic workstation setup
./usecases.sh workstation
# Blindly clobber sh and make it a link to bash
sudo rm /bin/sh
sudo ln -s /usr/local/bin/bash /bin/sh

./setup.sh install_coreutils
./setup.sh install_gzip
./setup.sh install_makeinfo
./setup.sh install_xz
./setup.sh install_mkfs
./setup.sh install_wget
# groupadd - shadow package ?
# useradd - shadow package ?
./setup.sh install_shadow

# nproc isn't found by lfs user in step 3
sudo cp -Pu /usr/local/bin/* /usr/bin
