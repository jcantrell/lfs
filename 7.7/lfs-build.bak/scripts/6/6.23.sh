echo -n "6.23.sh : " >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
make RAISE_SETFCAP=no prefix=/usr install
echo $? >> /lfs-build/logs/log6
chmod -v 755 /usr/lib/libcap.so
mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
