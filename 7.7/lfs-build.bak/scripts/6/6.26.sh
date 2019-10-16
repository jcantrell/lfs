echo -n "6.26.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr
echo -n $? >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin

