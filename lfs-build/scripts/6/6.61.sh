echo -n "6.61.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
