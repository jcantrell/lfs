echo -n "5.16.sh : " >> $LFS/lfs-build/logs/log5
./configure --prefix=/tools --without-bash-malloc
make
make test
make install
echo $? >> $LFS/lfs-build/logs/log5
ln -sv bash /tools/bin/sh
