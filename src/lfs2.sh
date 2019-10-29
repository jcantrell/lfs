# Chapter 4 - Setup lfs user environment
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

# /usr/local/bin isn't official; for tinycore only
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin:/usr/local/bin
export LFS LC_ALL LFS_TGT PATH
EOF

source ~/.bash_profile
