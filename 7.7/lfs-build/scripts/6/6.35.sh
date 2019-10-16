echo -n "6.35.sh : " >> /lfs-build/logs/log6
patch -Np1 -i ../readline-6.3-upstream_fixes-3.patch
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr --docdir=/usr/share/doc/readline-6.3
echo -n $? >> /lfs-build/logs/log6
make SHLIB_LIBS=-lncurses
echo -n $? >> /lfs-build/logs/log6
make SHLIB_LIBS=-lncurses install
echo $? >> /lfs-build/logs/log6
mv -v /usr/lib/lib{readline,history}.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-6.3
