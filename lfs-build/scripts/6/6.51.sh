echo -n "6.51.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.0.4
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
