echo -n "6.64.sh : " >> /lfs-build/logs/log6
patch -Np1 -i ../sysvinit-2.88dsf-consolidated-1.patch
make -C src
echo -n $? >> /lfs-build/logs/log6
make -C src install
echo $? >> /lfs-build/logs/log6
