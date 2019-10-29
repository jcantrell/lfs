echo -n "6.42.sh : " >> /lfs-build/logs/log6
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib
make
echo -n $? >> /lfs-build/logs/log6
make -k test
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
unset BUILD_ZLIB BUILD_ZLIP2
