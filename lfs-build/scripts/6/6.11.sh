echo -n "6.11.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr

make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6

make install
echo $? >> /lfs-build/logs/log6

mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so

