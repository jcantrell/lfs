echo -n "6.69.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr                          \
            --docdir=/usr/share/doc/man-db-2.7.1 \
            --sysconfdir=/etc                      \
            --disable-setuid                       \
            --with-browser=/usr/bin/lynx           \
            --with-vgrind=/usr/bin/vgrind          \
            --with-grap=/usr/bin/grap

make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
