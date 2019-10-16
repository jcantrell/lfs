echo -n "6.37.sh : " >> /lfs-build/logs/log6
patch -Np1 -i ../bc-1.06.95-memory_leak-1.patch
./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info
echo -n $? >> /lfs-build/logs/log6

make
echo -n $? >> /lfs-build/logs/log6

echo "quit" | ./bc/bc -l Test/checklib.b
make install
echo $? >> /lfs-build/logs/log6
