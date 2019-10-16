echo -n "5.17.sh : " >> $LFS/lfs-build/logs/log5
make
make PREFIX=/tools install
echo $? >> $LFS/lfs-build/logs/log5
