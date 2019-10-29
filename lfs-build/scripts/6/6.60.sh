echo -n "6.60.sh : " >> /lfs-build/logs/log6
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
