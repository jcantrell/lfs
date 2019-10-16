echo -n "5.14.sh : " >> $LFS/lfs-build/logs/log5
PKG_CONFIG= ./configure --prefix=/tools
make
make check
make install
echo $? >> $LFS/lfs-build/logs/log5
