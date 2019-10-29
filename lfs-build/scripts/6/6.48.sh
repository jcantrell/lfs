echo -n "6.48.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr --localstatedir=/var/lib/locate
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
