echo -n "6.14.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr \
            --enable-cxx  \
            --docdir=/usr/share/doc/gmp-6.0.0a
make
echo -n $? >> /lfs-build/logs/log6
make html
echo -n $? >> /lfs-build/logs/log6
make check 2>&1 | tee gmp-check-log
echo -n $? >> /lfs-build/logs/log6
awk '/tests passed/{total+=$2} ; END{print total}' gmp-check-log
make install
echo -n $? >> /lfs-build/logs/log6
make install-html
echo $? >> /lfs-build/logs/log6
