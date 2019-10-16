echo -n "6.36.sh : " >> /lfs-build/logs/log6
patch -Np1 -i ../bash-4.3.30-upstream_fixes-1.patch
./configure --prefix=/usr                    \
            --bindir=/bin                    \
            --docdir=/usr/share/doc/bash-4.3.30 \
            --without-bash-malloc            \
            --with-installed-readline
echo -n $? >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
chown -Rv nobody .
syu nobody -s /bin/bash -c "PATH=$PATH make tests"
make install
echo $? >> /lfs-build/logs/log6
