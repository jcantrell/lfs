echo -n "5.18.sh : " >> $LFS/lfs-build/logs/log5
./configure --prefix=/tools --enable-install-program=hostname
make
make RUN_EXPENSIVE_TESTS=yes check
make install
echo $? >> $LFS/lfs-build/logs/log5
