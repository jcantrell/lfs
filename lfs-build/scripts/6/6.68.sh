echo -n "6.68.sh : " >> /lfs-build/logs/log6
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --docdir=/usr/share/doc/util-linux-2.26 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --without-python     \
            --without-systemd    \
            --without-systemdsystemunitdir
make
echo -n $? >> /lfs-build/logs/log6


chown -Rv nobody .
su nobody -s /bin/bash -c "PATH=$PATH make -k check"
make install
echo $? >> /lfs-build/logs/log6
