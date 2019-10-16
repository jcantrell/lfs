echo -n "6.34.sh : " >> /lfs-build/logs/log6
sed -i -e '/tp++/a  if (ep <= tp) break;' src/kwset.c
./configure --prefix=/usr --bindir=/bin
echo -n $? >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
