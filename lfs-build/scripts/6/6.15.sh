echo -n "6.15.sh : " >> /lfs-build/logs/log6
patch -Np1 -i ../mpfr-3.1.2-upstream_fixes-3.patch
./configure --prefix=/usr        \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-3.1.2
make
echo -n $? >> /lfs-build/logs/log6
make html
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo -n $? >> /lfs-build/logs/log6
make install-html
echo $? >> /lfs-build/logs/log6
