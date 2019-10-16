echo -n "6.65.sh : " >> /lfs-build/logs/log6
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo -n $? >> /lfs-build/logs/log6
make -C doc install-html docdir=/usr/share/doc/tar-1.28
echo $? >> /lfs-build/logs/log6
