echo -n "5.26.sh : " >> $LFS/lfs-build/logs/log5
./configure --prefix=/tools
make
make check
make install
echo $? >> $LFS/lfs-build/logs/log5
