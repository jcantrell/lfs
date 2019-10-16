echo -n "6.41.sh : " >> /lfs-build/logs/log6
echo '#define PATH_PROCNET_DEV "/proc/net/dev"' >> ifconfig/system/linux.h 
./configure --prefix=/usr  \
            --localstatedir=/var   \
            --disable-logger       \
            --disable-whois        \
            --disable-servers
echo -n $? >> /lfs-build/logs/log6

make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin

