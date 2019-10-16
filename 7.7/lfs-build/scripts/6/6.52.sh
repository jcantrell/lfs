echo -n "6.52.sh : " >> /lfs-build/logs/log6
PAGE=letter ./configure --prefix=/usr

make
echo -n $? >> /lfs-build/logs/log6

make install
echo $? >> /lfs-build/logs/log6
