echo -n "6.49.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr --docdir=/usr/share/doc/gettext-0.19.4
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
