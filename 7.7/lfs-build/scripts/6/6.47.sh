echo -n "6.47.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr
make
echo -n $? >> /lfs-build/logs/log6
make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
mkdir -v /usr/share/doc/gawk-4.1.1
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.1.1
