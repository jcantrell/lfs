echo -n "5.27.sh : " >> $LFS/lfs-build/logs/log5
./configure --prefix=/tools --without-guile
make
make check
make install
echo $? >> $LFS/lfs-build/logs/log5
