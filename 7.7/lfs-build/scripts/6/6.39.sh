echo -n "6.39.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr --enable-libgdbm-compat
echo -n $? >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
