echo -n "5.12.sh : " >> /mnt/lfs/lfs-build/logs/log5
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure

./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include

make

make test

make SCRIPTS="" install
echo $? >> $LFS/lfs-build/logs/log5
