echo -n "6.16.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr --docdir=/usr/share/doc/mpc-1.0.2
make 
echo -n $? >> /lfs-build/logs/log6
make html
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo -n $? >> /lfs-build/logs/log6
make install-html
echo $? >> /lfs-build/logs/log6
