echo -n "5.24.sh : " >> $LFS/lfs-build/logs/log5
./configure --prefix=/tools
make
make check
make install
echo $? >> $LFS/lfs-build/logs/log5