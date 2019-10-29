echo -n "6.55.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr --sysconfdir=/etc
make
make install
echo $? >> /lfs-build/logs/log6
