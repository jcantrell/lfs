echo -n "6.27.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr                           \
            --exec-prefix=                          \
            --libdir=/usr/lib                       \
            --docdir=/usr/share/doc/procps-ng-3.3.10 \
            --disable-static                        \
            --disable-kill
echo -n $? >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
mv -v /usr/bin/pidof /bin
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
