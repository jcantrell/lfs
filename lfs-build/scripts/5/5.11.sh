echo -n "5.11.sh : " >> $LFS/lfs-build/logs/log5
cd unix
./configure --prefix=/tools

make

TZ=UTC make test

make install
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
echo $? >> $LFS/lfs-build/logs/log5
ln -sv tclsh8.6 /tools/bin/tclsh
echo $? 
