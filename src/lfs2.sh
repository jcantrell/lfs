SYS="ubuntu"

# Chapter 4 - Setup lfs user environment
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF

# /usr/local/bin isn't official; for tinycore only
# that is where tce-load seems to install everything
[ $SYS = "tinycore" ] && sed -i ~/.bashrc '/^PATH/c\PATH=\/tools\/bin:\/usr\/local\/bin:\/bin:\/usr\/bin'

source ~/.bash_profile
