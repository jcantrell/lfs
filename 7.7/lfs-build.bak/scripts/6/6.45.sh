echo -n "6.45.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.15
make
echo -n $? >> /lfs-build/logs/log6
sed -i "s:./configure:LEXLIB=/usr/lib/libfl.a &:" t/lex-{clean,depend}-cxx.sh
make -j4 check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
