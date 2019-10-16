echo -n "5.15.sh : " >> $LFS/lfs-build/logs/log5
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite

make
make install
echo $? >> $LFS/lfs-build/logs/log5
