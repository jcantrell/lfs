echo -n "6.22.sh : " >> /lfs-build/logs/log6
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" \
    libacl/__acl_to_any_text.c
./configure --prefix=/usr \
            --bindir=/bin \
            --libexecdir=/usr/lib
echo -n $? >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
make install install-dev install-lib
echo $? >> /lfs-build/logs/log6
chmod -v 755 /usr/lib/libacl.so

mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
