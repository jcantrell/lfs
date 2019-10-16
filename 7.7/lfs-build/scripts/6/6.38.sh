echo -n "6.38.sh : "  >> /lfs-build/logs/log6
./configure --prefix=/usr
echo -n $? >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
