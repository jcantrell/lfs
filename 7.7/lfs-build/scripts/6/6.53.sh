echo -n "6.53.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr --docdir=/usr/share/doc/xz-5.2.0
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
