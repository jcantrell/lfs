echo -n "6.24.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/sed-4.2.2
echo -n $? >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
make html
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo -n $? >> /lfs-build/logs/log6
make -C doc install-html
echo $? >> /lfs-build/logs/log6
