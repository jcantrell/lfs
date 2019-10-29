echo -n "6.67.sh : " >> /lfs-build/logs/log6
sed -r -i 's|/usr(/bin/test)|\1|' test/udev-test.pl
BLKID_CFLAGS=-I/tools/include       \
BLKID_LIBS='-L/tools/lib -lblkid'   \
./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-split-usr      \
            --enable-libkmod        \
            --enable-rule_generator \
            --enable-keymap         \
            --disable-introspection \
            --disable-gudev         \
            --disable-gtk-doc-html
make
echo -n $? >> /lfs-build/logs/log6
mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d

make check
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
tar -xvf ../eudev-2.1.1-manpages.tar.bz2 -C /usr/share
tar -xvf ../udev-lfs-20140408.tar.bz2
make -f udev-lfs-20140408/Makefile.lfs install
udevadm hwdb --update
