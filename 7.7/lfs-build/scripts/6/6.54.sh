echo -n "6.54.sh : " >> /lfs-build/logs/log6
./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-grub-emu-usb \
            --disable-efiemu       \
            --disable-werror
make
make install
echo $? >> /lfs-build/logs/log6
