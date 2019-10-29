echo -n "5.13.sh : " >> $LFS/lfs-build/logs/log5
./configure --prefix=/tools
make install
echo $? >> $LFS/lfs-build/logs/log5
make check
