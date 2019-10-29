echo -n "6.21.sh : " >> /lfs-build/logs/log6
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
./configure --prefix=/usr --bindir=/bin
echo -n $? >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
make -j1 tests root-tests
echo -n $? >> /lfs-build/logs/log6
make install install-dev install-lib
echo $? >> /lfs-build/logs/log6
chmod -v 755 /usr/lib/libattr.so
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
