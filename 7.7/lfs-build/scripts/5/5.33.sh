echo -n "5.33.sh : " >> $LFS/lfs-build/logs/log5
./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            PKG_CONFIG=""

make
make install
echo $? >> $LFS/lfs-build/logs/log5
