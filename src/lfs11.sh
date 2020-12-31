#!/bin/bash

ch6_80_1() {
  rm -f /usr/lib/lib{bfd,opcodes}.a
  rm -f /usr/lib/libbz2.a
  rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
  rm -f /usr/lib/libltdl.a
  rm -f /usr/lib/libfl.a
  rm -f /usr/lib/libz.a
  find /usr/lib /usr/libexec -name \*.la -delete
}

ch7_2() {
  PK="lfs-bootscripts-20190524"; EXT=".tar.xz";
  cd /sources
  tar -xf $PK$EXT
  cd $PK
  make install
  cd ..
  rm -rf $PK
}

ch7_4() {
  bash /lib/udev/init-net-rules.sh
}

ch7_5() {
cd /etc/sysconfig/
cat > ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static
IP=192.168.1.2
GATEWAY=192.168.1.1
PREFIX=24
BROADCAST=192.168.1.255
EOF

cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
# End /etc/resolv.conf
EOF

echo "lfsbox" > /etc/hostname

cat > /etc/hosts << "EOF"
127.0.0.1 localhost
127.0.1.1 lfsbox
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOF
}

ch7_6() {
cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S016:once:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF

cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF
}

ch7_7() {
cat > /etc/profile <<"EOF"
export LANG=en_US.UTF-8
EOF
}

ch7_8() {
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF
}

ch7_9() {
cat > /etc/shells << "EOF"
/bin/sh
/bin/bash
EOF
}

ch8_2() {
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sda1     /            ext4    defaults            1     1
/dev/sda2     swap         swap     pri=1               0     0
proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs          /run         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF
}

ch8_3() {
cd /sources
tar -xf linux-5.2.8.tar.xz
cd linux-5.2.8

make mrproper
make menuconfig
make
make modules_install
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-5.2.8-lfs-9.0
cp -iv System.map /boot/System.map-5.2.8
cp -iv .config /boot/config-5.2.8
install -d /usr/share/doc/linux-5.2.8
cp -r Documentation/* /usr/share/doc/linux-5.2.8
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF

cd ..
rm -rf linux-5.2.8
}

ch8_4() {
grub-install /dev/sda

cat > /boot/grub/grub.cfg << "EOF"
set default=0
set timeout=5

insmod ext2
set root=(hd0,2)

menuentry "GNU/Linux, Linux 5.2.8-lfs-9.0" {
	linux /boot/vmlinuz-5.2.8-lfs-9.0 root=/dev/sda2 ro
}
EOF
}

ch9_1() {
echo 9.0 > /etc/lfs-release
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="9.0"
DISTRIB_CODENAME="badidea"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF
}

ch9_3() {
# TODO: install dhcpcd, openssh, wget from BLFS
# Install dhcpcd as described in Ch. 14 of BLFS
PK=dhcpcd-8.0.3
EXT=.tar.xz
cd /sources
tar -xf $PK$EXT
cd $PK
./configure --libexecdir=/lib/dhcpcd \
            --dbdir=/var/lib/dhcpcd  &&
make
make install
# run script from lfs-bootscriptsd
make install-service-dhcpcd
# create config file as root
cat > /etc/sysconfig/ifconfig.eth0 << "EOF"
ONBOOT="yes"
IFACE="eth0"
SERVICE="dhcpcd"
DHCP_START="-b -q <insert appropriate start options here>"
DHCP_STOP="-k <insert additional stop options here>"
EOF
cd ..
rm -rf $PK

# Install wget as described in Ch 15. of BLFS
PK=wget-1.20.3
EXT=.tar.gz
cd /sources
tar -xf $PK$EXT
cd $PK
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl &&
make
make install
cd ..
rm -rf $PK

# Install openssh as described in Ch 15. of BLFS
PK=openssh-8.0p1
EXT=.tar.gz
cd /sources
tar -xf $PK$EXT
cd $PK
# TODO: Run install, chown groupadd, useradd as root
install  -v -m700 -d /var/lib/sshd &&
chown    -v root:sys /var/lib/sshd &&

groupadd -g 50 sshd        &&
useradd  -c 'sshd PrivSep' \
         -d /var/lib/sshd  \
         -g sshd           \
         -s /bin/false     \
         -u 50 sshd
./configure --prefix=/usr                     \
            --sysconfdir=/etc/ssh             \
            --with-md5-passwords              \
            --with-privsep-path=/var/lib/sshd &&
make
# TODO: install as root user
make install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&

install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-8.0p1     &&
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-8.0p1
cd ..
rm -rf $PK

  #logout
}

ch6_80_1
ch7_2
ch7_4
ch7_5
ch7_6
ch7_7
ch7_8
ch7_9
ch8_2
ch8_3
ch8_4
ch9_1
ch9_3
