#!/bin/bash
set -x
SYS="ubuntu" # or ubuntu
[ ! -z "$2" ] && SYS="$2"
DSK="sda"
DSK1="1"
DSK2="2"
[ ! -z "$3" ] && DSK="$3"
[ ! -z "$4" ] && DSK1="$4"
[ ! -z "$5" ] && DSK2="$5"
SWAPPART=/dev/"${DSK}${DSK1}"
LFSPART=/dev/"${DSK}${DSK2}"
BRANCH="master"
LP=$LFS/sources/lfs/logs
mkdir -p $LP
TESTS=""
JOPT="-j `nproc`"
[ ! -z "$6" ] && JOPT="-j $6"
IFACE="eth0"
[ ! -z "$7" ] && IFACE="$7"
URL=http://jcantrell.me:8002/jcantrell

ch2_2() {
cat > version-check.sh << "EOF"
#!/bin/bash
# Simple script to list version numbers of critical development tools
export LC_ALL=C
bash --version | head -n1 | cut -d" " -f2-4
MYSH=$(readlink -f /bin/sh)
echo "/bin/sh -> $MYSH"
echo $MYSH | grep -q bash || echo "ERROR: /bin/sh does not point to bash"
unset MYSH

echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
bison --version | head -n1

if [ -h /usr/bin/yacc ]; then
  echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
elif [ -x /usr/bin/yacc ]; then
  echo yacc is `/usr/bin/yacc --version | head -n1`
else
  echo "yacc not found" 
fi

bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
diff --version | head -n1
find --version | head -n1
gawk --version | head -n1

if [ -h /usr/bin/awk ]; then
  echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
elif [ -x /usr/bin/awk ]; then
  echo awk is `/usr/bin/awk --version | head -n1`
else 
  echo "awk not found" 
fi

gcc --version | head -n1
g++ --version | head -n1
ldd --version | head -n1 | cut -d" " -f2-  # glibc version
grep --version | head -n1
gzip --version | head -n1
cat /proc/version
m4 --version | head -n1
make --version | head -n1
patch --version | head -n1
echo Perl `perl -V:version`
python3 --version
sed --version | head -n1
tar --version | head -n1
makeinfo --version | head -n1  # texinfo version
xz --version | head -n1

echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
if [ -x dummy ]
  then echo "g++ compilation OK";
  else echo "g++ compilation failed"; fi
rm -f dummy.c dummy
EOF
bash version-check.sh
}

ch2_5() {
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$DSK
  n   # new partition
  p   # partition
  1   # first
      # default
  +2G # 2GB partition size
  n   # new entry
  p   # partition
  2   # second
      # default
      # default
  a   #
  2   # second
  t   # 
  1   #
  82  #
  w   #
EOF

# Chapter 2
SWAPPART="/dev/${DSK}${DSK1}"
LFSPART="/dev/${DSK}${DSK2}"
mkfs -v -t ext4 "$LFSPART"
mkswap "$SWAPPART"
}

ch2_6() {
export LFS=/mnt/lfs
}

ch2_7() {
  mkdir -pv $LFS
  mount -v -t ext4 "$LFSPART" $LFS
  swapon -v "$SWAPPART"
}

# Chapter 3 - Packages and Patches
ch3_1() {
  mkdir -v $LFS/sources
  chmod -v a+wt $LFS/sources

  wget $URL/lfs/raw/"$BRANCH"/src/wget-list-external -O wget-list
  wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
  git clone $URL/lfs.git $LFS/sources/lfs --branch $BRANCH

  # Place md5sums file in sources directory
  wget $URL/lfs/raw/"$BRANCH"/src/md5sums -P $LFS/sources
  bash version-check.sh >$LFS/sources/version-check.out 2>&1

  pushd $LFS/sources
  md5sum -c md5sums
  popd
}

# Chapter 4 - Final Preparations
ch4_2() {
  mkdir -pv $LFS/{bin,etc,lib,sbin,usr,var}
  case $(uname -m) in
    x86_64) mkdir -pv $LFS/lib64 ;;
  esac
  mkdir -v $LFS/tools
}

ch4_3() {
  if [ "$SYS" = "tinycore" ]; then
    # HACK: Why doesn't grep find this after 5.35?
    ln -s /usr/local/lib/libpcre.so.1 /tools/lib/
    addgroup lfs
    adduser -s /bin/bash -G lfs -k /dev/null lfs
  else
    groupadd lfs
    useradd -s /bin/bash -g lfs -m -k /dev/null lfs
    #passwd lfs
    echo lfs:lfspassword | chpasswd
  fi
  chown -v lfs $LFS/{usr,lib,var,etc,bin,sbin,tools}
  case  $(uname -m) in
    x86_64) chown -v lfs $LFS/lib64 ;;
  esac
  chown -vR lfs $LFS/sources
  su - lfs --whitelist-environment=LFS
}

ch4_4() {
# Chapter 4 - Setup lfs user environment
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
export LFS LC_ALL LFS_TGT PATH
EOF

# /usr/local/bin isn't official; for tinycore only
# that is where tce-load seems to install everything
[ $SYS = "tinycore" ] && sed -i ~/.bashrc '/^PATH/c\PATH=\/tools\/bin:\/usr\/local\/bin:\/bin:\/usr\/bin'

source ~/.bash_profile
}

ch5_2() {
  mkdir -v build
  cd build
  ../configure --prefix=$LFS/tools        \
               --with-sysroot=$LFS        \
               --target=$LFS_TGT          \
               --disable-nls              \
               --disable-werror
  make $JOPT
  make install
  cd ..
}

ch5_3() {
  tar -xf ../mpfr-4.1.0.tar.xz
  mv -v mpfr-4.1.0 mpfr
  tar -xf ../gmp-6.2.0.tar.xz
  mv -v gmp-6.2.0 gmp
  tar -xf ../mpc-1.1.0.tar.gz
  mv -v mpc-1.1.0 mpc
  
  case $(uname -m) in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
    ;;
  esac
  
  mkdir -v build
  cd build
  
  ../configure                                       \
      --target=$LFS_TGT                              \
      --prefix=$LFS/tools                            \
      --with-glibc-version=2.11                      \
      --with-sysroot=$LFS                            \
      --with-newlib                                  \
      --without-headers                              \
      --enable-initfini-array                        \
      --disable-nls                                  \
      --disable-shared                               \
      --disable-multilib                             \
      --disable-decimal-float                        \
      --disable-threads                              \
      --disable-libatomic                            \
      --disable-libgomp                              \
      --disable-libquadmath                          \
      --disable-libssp                               \
      --disable-libvtv                               \
      --disable-libstdcxx                            \
      --enable-languages=c,c++
  
  make $JOPT
  make install
  cd ..
  cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h
}

ch5_4() {
  make mrproper
  make headers
  find usr/include -name '.*' -delete
  rm usr/include/Makefile
  cp -rv usr/include $LFS/usr
}

ch5_5() {
  case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
  esac
  patch -Np1 -i ../glibc-2.32-fhs-1.patch

  mkdir -v build
  cd build
  ../configure                                        \
        --prefix=/usr                                 \
        --host=$LFS_TGT                               \
        --build=$(../scripts/config.guess)            \
        --enable-kernel=3.2                           \
        --with-headers=$LFS/usr/include               \
        libc_cv_slibdir=/lib
  make $JOPT
  make DESTDIR=$LFS install
   # Now test to make sure we compile correctly
  echo 'int main(){}' > dummy.c
  $LFS_TGT-gcc dummy.c
  readelf -l a.out | grep '/ld-linux'
  rm -v dummy.c a.out
  cd ..
  $LFS/tools/libexec/gcc/$LFS_TGT/10.2.0/install-tools/mkheaders
}

ch5_6() {
  mkdir -v build
  cd build
  ../libstdc++-v3/configure         \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/10.2.0
  make $JOPT
  make DESTDIR=$LFS install
  cd ..
}

ch6_2() {
  sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
  echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
  ./configure --prefix=/usr \
              --host=$LFS_TGT \
              --build=$(build-aux/config.guess)
  make $JOPT
  make DESTDIR=$LFS install
}

ch6_3() {
  sed -i s/mawk// configure
  mkdir build
  pushd build
    ../configure
    make -C include
    make -C progs tic
  popd
  ./configure --prefix=/usr                \
              --host=$LFS_TGT              \
              --build=$(./config.guess)    \
              --mandir=/usr/share/man      \
              --with-manpage-format=normal \
              --with-shared                \
              --without-debug              \
              --without-ada                \
              --without-normal             \
              --enable-widec
  
  make $JOPT
  make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
  echo "INPUT(-lncursesw)" > $LFS/usr/lib/libncurses.so
  mv -v $LFS/usr/lib/libncursesw.so.6* $LFS/lib
  ln -sfv ../../lib/$(readlink $LFS/usr/lib/libncursesw.so) $LFS/usr/lib/libncursesw.so
}

ch6_4() {
  ./configure --prefix=/usr                   \
              --build=$(support/config.guess) \
              --host=$LFS_TGT                 \
              --without-bash-malloc
  make
  make DESTDIR=$LFS install
  mv $LFS/usr/bin/bash $LFS/bin/bash
  ln -sv bash $LFS/bin/sh
}

ch6_5() {
  ./configure --prefix=/usr                     \
              --host=$LFS_TGT                   \
              --build=$(build-aux/config.guess) \
              --enable-install-program=hostname \
              --enable-no-install-program=kill,uptime
  make $JOPT
  make DESTDIR=$LFS install
  mv -v $LFS/usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} $LFS/bin
  mv -v $LFS/usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm}        $LFS/bin
  mv -v $LFS/usr/bin/{rmdir,stty,sync,true,uname}               $LFS/bin
  mv -v $LFS/usr/bin/{head,nice,sleep,touch}                    $LFS/bin
  mv -v $LFS/usr/bin/chroot                                     $LFS/usr/sbin
  mkdir -pv $LFS/usr/share/man/man8
  mv -v $LFS/usr/share/man/man1/chroot.1                        $LFS/usr/share/man/man8/chroot.8
  sed -i 's/"1"/"8"/'                                           $LFS/usr/share/man/man8/chroot.8
}

ch6_6() {
  ./configure --prefix=/usr --host=$LFS_TGT
  make $JOPT
  make DESTDIR=$LFS install
}

ch6_7() {
  ./configure --prefix=/usr --host=$LFS_TGT
  make $JOPT
  make DESTDIR=$LFS install
}

ch6_8() {
  ./configure --prefix=/usr   \
              --host=$LFS_TGT \
              --build=$(build-aux/config.guess)
  make $JOPT
  make DESTDIR=$LFS install
  mv -v $LFS/usr/bin/find $LFS/bin
  sed -i 's|find:=${BINDIR}|find:=/bin|' $LFS/usr/bin/updatedb
}

ch6_9() {
  sed -i 's/extras//' Makefile.in
  ./configure --prefix=/usr   \
              --host=$LFS_TGT \
              --build=$(./config.guess)
  make $JOPT
  make DESTDIR=$LFS install
}

ch6_10() {
  ./configure --prefix=/usr   \
              --host=$LFS_TGT \
              --bindir=/bin
  make $JOPT
  make DESTDIR=$LFS install
}

ch6_11() {
  ./configure --prefix=/usr --host=$LFS_TGT
  make
  make DESTDIR=$LFS install
  mv -v $LFS/usr/bin/gzip $LFS/bin
}

ch6_12() {
  ./configure --prefix=/usr   \
              --without-guile \
              --host=$LFS_TGT \
              --build=$(build-aux/config.guess)

  make $JOPT
  make DESTDIR=$LFS install
}

ch6_13() {
  ./configure --prefix=/usr   \
              --host=$LFS_TGT \
              --build=$(build-aux/config.guess)
  make $JOPT
  make DESTDIR=$LFS install
}

ch6_14() {
  ./configure --prefix=/usr   \
              --host=$LFS_TGT \
              --bindir=/bin
  make $JOPT
  make DESTDIR=$LFS install
}

ch6_15() {
  ./configure --prefix=/usr                     \
              --host=$LFS_TGT                   \
              --build=$(build-aux/config.guess) \
              --bindir=/bin
  make $JOPT
  make DESTDIR=$LFS install
}

ch6_16() {
  ./configure --prefix=/usr                     \
              --host=$LFS_TGT                   \
              --build=$(build-aux/config.guess) \
              --disable-static                  \
              --docdir=/usr/share/doc/xz-5.2.5
  make $JOPT
  make DESTDIR=$LFS install
  mv -v $LFS/usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat}  $LFS/bin
  mv -v $LFS/usr/lib/liblzma.so.*                       $LFS/lib
  ln -svf ../../lib/$(readlink $LFS/usr/lib/liblzma.so) $LFS/usr/lib/liblzma.so
}

ch6_17() {
  mkdir -v build
  cd build
  
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --disable-werror           \
    --enable-64-bit-bfd
  make $JOPT
  make DESTDIR=$LFS install
  cd ..
}

ch6_18() {
  tar -xf ../mpfr-4.1.0.tar.xz
  mv -v mpfr-4.1.0 mpfr
  tar -xf ../gmp-6.2.0.tar.xz
  mv -v gmp-6.2.0 gmp
  tar -xf ../mpc-1.1.0.tar.gz
  mv -v mpc-1.1.0 mpc
  
  case $(uname -m) in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
    ;;
  esac

  mkdir -v build
  cd build
  
  mkdir -pv $LFS_TGT/libgcc
  ln -s ../../../libgcc/gthr-posix.h $LFS_TGT/libgcc/gthr-default.h
  ../configure                                       \
      --build=$(../config.guess)                     \
      --host=$LFS_TGT                                \
      --prefix=/usr                                  \
      CC_FOR_TARGET=$LFS_TGT-gcc                     \
      --with-build-sysroot=$LFS                      \
      --enable-initfini-array                        \
      --disable-nls                                  \
      --disable-multilib                             \
      --disable-decimal-float                        \
      --disable-libatomic                            \
      --disable-libgomp                              \
      --disable-libquadmath                          \
      --disable-libssp                               \
      --disable-libvtv                               \
      --disable-libstdcxx                            \
      --enable-languages=c,c++
  make $JOPT
  make DESTDIR=$LFS install
  ln -sv gcc $LFS/usr/bin/cc
  
  cd ..
}

ch7_2() {
  chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
  case $(uname -m) in
    x86_64) chown -R root:root $LFS/lib64 ;;
  esac
}

ch7_3() {
  mkdir -pv $LFS/{dev,proc,sys,run}
  
  [ ! -f $LFS/dev/console ] && mknod -m 600 $LFS/dev/console c 5 1
  [ ! -f $LFS/dev/null ]    && mknod -m 666 $LFS/dev/null c 1 3
  
  mount -v --bind /dev $LFS/dev
  
  mount -v --bind /dev/pts $LFS/dev/pts
  mount -vt proc proc $LFS/proc
  mount -vt sysfs sysfs $LFS/sys
  mount -vt tmpfs tmpfs $LFS/run
  
  if [ -h $LFS/dev/shm ]; then
    mkdir -pv $LFS/$(readlink $LFS/dev/shm)
  fi
}

ch7_4() {
  chroot "$LFS" /usr/bin/env -i \
      HOME=/root                  \
      TERM="$TERM"                \
      PS1='(lfs chroot) \u:\w\$ ' \
      PATH=/bin:/usr/bin:/sbin:/usr/sbin \
      /bin/bash --login +h
}

ch7_5() {
  mkdir -pv /{boot,home,mnt,opt,srv}
  mkdir -pv /etc/{opt,sysconfig}
  mkdir -pv /lib/firmware
  mkdir -pv /media/{floppy,cdrom}
  mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
  mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
  mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
  mkdir -pv /usr/{,local/}share/man/man{1..8}
  mkdir -pv /var/{cache,local,log,mail,opt,spool}
  mkdir -pv /var/lib/{color,misc,locate}

  ln -sfv /run /var/run
  ln -sfv /run/lock /var/lock

  install -dv -m 0750 /root
  install -dv -m 1777 /tmp /var/tmp
}

ch7_6_1() {
  ln -sv /proc/self/mounts /etc/mtab
  echo "127.0.0.1 localhost $(hostname)" > /etc/hosts

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF

  echo "tester:x:$(ls -n $(tty) | cut -d" " -f3):101::/home/tester:/bin/bash" >> /etc/passwd
  echo "tester:x:101:" >> /etc/group
  install -o tester -d /home/tester

  # This will need to be run separately
  exec /bin/bash --login +h
}

ch7_6_2() {
  touch /var/log/{btmp,lastlog,faillog,wtmp}
  chgrp -v utmp /var/log/lastlog
  chmod -v 664  /var/log/lastlog
  chmod -v 600  /var/log/btmp
}

ch7_7() {
  ln -s gthr-posix.h libgcc/gthr-default.h
  mkdir -v build
  cd       build
  ../libstdc++-v3/configure            \
      CXXFLAGS="-g -O2 -D_GNU_SOURCE"  \
      --prefix=/usr                    \
      --disable-multilib               \
      --disable-nls                    \
      --host=$(uname -m)-lfs-linux-gnu \
      --disable-libstdcxx-pch
  make $JOPT
  make install
  cd ..
}

ch7_8() {
  ./configure --disable-shared
  make $JOPT
  cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
}

ch7_9() {
  ./configure --prefix=/usr \
              --docdir=/usr/share/doc/bison-3.7.1
  make $JOPT
  make install
}

ch7_10() {
  sh Configure -des                                        \
               -Dprefix=/usr                               \
               -Dvendorprefix=/usr                         \
               -Dprivlib=/usr/lib/perl5/5.32/core_perl     \
               -Darchlib=/usr/lib/perl5/5.32/core_perl     \
               -Dsitelib=/usr/lib/perl5/5.32/site_perl     \
               -Dsitearch=/usr/lib/perl5/5.32/site_perl    \
               -Dvendorlib=/usr/lib/perl5/5.32/vendor_perl \
               -Dvendorarch=/usr/lib/perl5/5.32/vendor_perl
  make $JOPT
  make install
}

ch7_11() {
  ./configure --prefix=/usr   \
              --enable-shared \
              --without-ensurepip
  make $JOPT
  make install
}

ch7_12() {
  ./configure --prefix=/usr
  make $JOPT
  make install
}

ch7_13() {
  mkdir -pv /var/lib/hwclock
  ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
              --docdir=/usr/share/doc/util-linux-2.36 \
              --disable-chfn-chsh  \
              --disable-login      \
              --disable-nologin    \
              --disable-su         \
              --disable-setpriv    \
              --disable-runuser    \
              --disable-pylibmount \
              --disable-static     \
              --without-python
  make $JOPT
  make install
}

ch7_14_1() {
  find /usr/{lib,libexec} -name \*.la -delete
  rm -rf /usr/share/{info,man,doc}/*
  exit
}

ch7_14_2() {
  umount $LFS/dev{/pts,}
  umount $LFS/{sys,proc,run}
  strip --strip-debug $LFS/usr/lib/*
  strip --strip-unneeded $LFS/usr/{,s}bin/*
  strip --strip-unneeded $LFS/tools/bin/*


  # Backup tools
  cd $LFS &&
  tar -cJpf $HOME/lfs-temp-tools-10.0.tar.xz .

}

ch7_14_3() {
  # Restore from backup
  cd $LFS &&
  rm -rf ./* &&
  tar -xpf $HOME/lfs-temp-tools-10.0.tar.xz
}

ch8_3() {
  make install
}

ch8_4() {
  tar -xf ../tcl8.6.10-html.tar.gz --strip-components=1
  SRCDIR=$(pwd)
  cd unix
  ./configure --prefix=/usr           \
              --mandir=/usr/share/man \
              $([ "$(uname -m)" = x86_64 ] && echo --enable-64bit)
  make

  sed -e "s|$SRCDIR/unix|/usr/lib|" \
      -e "s|$SRCDIR|/usr/include|"  \
      -i tclConfig.sh

  sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.1|/usr/lib/tdbc1.1.1|" \
      -e "s|$SRCDIR/pkgs/tdbc1.1.1/generic|/usr/include|"    \
      -e "s|$SRCDIR/pkgs/tdbc1.1.1/library|/usr/lib/tcl8.6|" \
      -e "s|$SRCDIR/pkgs/tdbc1.1.1|/usr/include|"            \
      -i pkgs/tdbc1.1.1/tdbcConfig.sh

  sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.0|/usr/lib/itcl4.2.0|" \
      -e "s|$SRCDIR/pkgs/itcl4.2.0/generic|/usr/include|"    \
      -e "s|$SRCDIR/pkgs/itcl4.2.0|/usr/include|"            \
      -i pkgs/itcl4.2.0/itclConfig.sh

  unset SRCDIR
  make install
  make test
  chmod -v u+w /usr/lib/libtcl8.6.so
  make install-private-headers
  ln -sfv tclsh8.6 /usr/bin/tclsh
}

ch8_5() {
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
make
make test
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
}

ch8_6() {
  ./configure --prefix=/usr
  makeinfo --html --no-split -o doc/dejagnu.html doc/dejagnu.texi
  makeinfo --plaintext       -o doc/dejagnu.txt  doc/dejagnu.texi

  make install
  install -v -dm755  /usr/share/doc/dejagnu-1.6.2
  install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.2

  make check
}

ch8_7() {
  cp services protocols /etc
}

ch8_8() {
patch -Np1 -i ../glibc-2.32-fhs-1.patch
mkdir -v build
cd       build
../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=3.2                      \
             --enable-stack-protector=strong          \
             --with-headers=/usr/include              \
             libc_cv_slibdir=/lib
make
case $(uname -m) in
  i?86)   ln -sfnv $PWD/elf/ld-linux.so.2        /lib ;;
  x86_64) ln -sfnv $PWD/elf/ld-linux-x86-64.so.2 /lib ;;
esac
make check
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SIJS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2020a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

ln -sfv /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d
}

ch8_9() {
./configure --prefix=/usr
make $JOPT
make check
make install
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
}

ch8_10() {
  patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
  sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
  sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
  make -f Makefile-libbz2_so
  make clean
  make $JOPT
  make PREFIX=/usr install
  cp -v bzip2-shared /bin/bzip2
  cp -av libbz2.so* /lib
  ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
  rm -v /usr/bin/{bunzip2,bzcat,bzip2}
  ln -sv bzip2 /bin/bunzip2
  ln -sv bzip2 /bin/bzcat
}

ch8_11() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/xz-5.2.5
  make $JOPT
  make check
  make install
  mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
  mv -v /usr/lib/liblzma.so.* /lib
  ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
}

ch8_12() {
  make $JOPT
  make prefix=/usr install
  rm -v /usr/lib/libzstd.a
  mv -v /usr/lib/libzstd.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libzstd.so) /usr/lib/libzstd.so
}

ch8_13() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch8_14() {
  sed -i '/MV.*old/d' Makefile.in
  sed -i '/{OLDSUFF}/c:' support/shlib-install
  ./configure --prefix=/usr    \
              --disable-static \
              --with-curses    \
              --docdir=/usr/share/doc/readline-8.0
  make SHLIB_LIBS="-lncursesw"
  make SHLIB_LIBS="-lncursesw" install
  mv -v /usr/lib/lib{readline,history}.so.* /lib
  chmod -v u+w /lib/lib{readline,history}.so.*
  ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
  ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
  install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.0
}

ch8_15() {
  sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
  echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch8_16() {
  PREFIX=/usr CC=gcc CFLAGS="-std=c99" ./configure.sh -G -O3
  make $JOPT
  make test
  make install
}

ch8_17() {
  ./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4
  make $JOPT
  make check
  make install
  ln -sv flex /usr/bin/lex
}

ch8_18() {
  expect -c "spawn ls"
  sed -i '/@\tincremental_copy/d' gold/testsuite/Makefile.in
  mkdir -v build
  cd       build
  ../configure --prefix=/usr       \
               --enable-gold       \
               --enable-ld=default \
               --enable-plugins    \
               --enable-shared     \
               --disable-werror    \
               --enable-64-bit-bfd \
               --with-system-zlib
  make tooldir=/usr
  make -k check
  make tooldir=/usr install
}

ch8_19() {
  ./configure --prefix=/usr    \
              --enable-cxx     \
              --disable-static \
              --docdir=/usr/share/doc/gmp-6.2.0
  make $JOPT
  make html
  make check 2>&1 | tee gmp-check-log
  awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
  make install
  make install-html
}

ch8_20() {
  ./configure --prefix=/usr        \
              --disable-static     \
              --enable-thread-safe \
              --docdir=/usr/share/doc/mpfr-4.1.0
  make $JOPT
  make html
  make check
  make install
  make install-html
}

ch8_21() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/mpc-1.1.0
  make $JOPT
  make html
  make check
  make install
  make install-html
}

ch8_22() {
  ./configure --prefix=/usr     \
              --bindir=/bin     \
              --disable-static  \
              --sysconfdir=/etc \
              --docdir=/usr/share/doc/attr-2.4.48
  make
  make check
  make install
  mv -v /usr/lib/libattr.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
}

ch8_23() {
  ./configure --prefix=/usr         \
              --bindir=/bin         \
              --disable-static      \
              --libexecdir=/usr/lib \
              --docdir=/usr/share/doc/acl-2.2.53
  make $JOPT
  make install
  mv -v /usr/lib/libacl.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
}

ch8_24() {
  sed -i '/install -m.*STACAPLIBNAME/d' libcap/Makefile
  make lib=lib
  make test
  make lib=lib PKGCONFIGDIR=/usr/lib/pkgconfig install
  chmod -v 755 /lib/libcap.so.2.42
  mv -v /lib/libpsx.a /usr/lib
  rm -v /lib/libcap.so
  ln -sfv ../../lib/libcap.so.2 /usr/lib/libcap.so
}

ch8_25() {
  sed -i 's/groups$(EXEEXT) //' src/Makefile.in
  find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
  find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
  find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
  sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
      -e 's:/var/spool/mail:/var/mail:'                 \
      -i etc/login.defs
  sed -i 's/1000/999/' etc/useradd
  touch /usr/bin/passwd
  ./configure --sysconfdir=/etc \
              --with-group-name-max-length=32
  make $JOPT
  make install
  pwconv
  grpconv
  #passwd root
  echo "root:lfspassword" | chpasswd
}

ch8_26() {
  case $(uname -m) in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' \
          -i.orig gcc/config/i386/t-linux64
    ;;
  esac

  mkdir -v build
  cd       build
  ../configure --prefix=/usr            \
               LD=ld                    \
               --enable-languages=c,c++ \
               --disable-multilib       \
               --disable-bootstrap      \
               --with-system-zlib
  make $JOPT
  ulimit -s 32768
  chown -Rv tester . 
  su tester -c "PATH=$PATH make -k check"
  ../contrib/test_summary
  make install
  rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/10.2.0/include-fixed/bits/
  chown -v -R root:root \
      /usr/lib/gcc/*linux-gnu/10.2.0/include{,-fixed}
  ln -sv ../usr/bin/cpp /lib
  install -v -dm755 /usr/lib/bfd-plugins
  ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/10.2.0/liblto_plugin.so \
          /usr/lib/bfd-plugins/
  echo 'int main(){}' > dummy.c
  cc dummy.c -v -Wl,--verbose &> dummy.log
  readelf -l a.out | grep ': /lib'
  grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
  grep -B4 '^ /usr/include' dummy.log
  grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
  grep "/lib.*/libc.so.6 " dummy.log
  grep found dummy.log
  rm -v dummy.c a.out dummy.log
  mkdir -pv /usr/share/gdb/auto-load/usr/lib
  mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
}

ch8_27() {
  ./configure --prefix=/usr              \
              --with-internal-glib       \
              --disable-host-tool        \
              --docdir=/usr/share/doc/pkg-config-0.29.2
  make $JOPT
  make check
  make install
}

ch8_28() {
  sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
  ./configure --prefix=/usr           \
              --mandir=/usr/share/man \
              --with-shared           \
              --without-debug         \
              --without-normal        \
              --enable-pc-files       \
              --enable-widec
  make $JOPT
  make install
  mv -v /usr/lib/libncursesw.so.6* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
  for lib in ncurses form panel menu ; do
      rm -vf                    /usr/lib/lib${lib}.so
      echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
      ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
  done
  rm -vf                     /usr/lib/libcursesw.so
  echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
  ln -sfv libncurses.so      /usr/lib/libcurses.so


  mkdir -v       /usr/share/doc/ncurses-6.2
  cp -v -R doc/* /usr/share/doc/ncurses-6.2
}

ch8_29() {
  ./configure --prefix=/usr --bindir=/bin
  make $JOPT
  make html
  chown -Rv tester .
  su tester -c "PATH=$PATH make check"
  make install
  install -d -m755           /usr/share/doc/sed-4.8
  install -m644 doc/sed.html /usr/share/doc/sed-4.8
}

ch8_30() {
./configure --prefix=/usr
make $JOPT
make install
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin
}

ch8_31() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/gettext-0.21
  make $JOPT
  make check
  make install
  chmod -v 0755 /usr/lib/preloadable_libintl.so
}

ch8_32() {
  ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.7.1
  make $JOPT
  make check
  make install
}

ch8_33() {
  ./configure --prefix=/usr --bindir=/bin
  make $JOPT
  make check
  make install
}

ch8_34() {
  patch -Np1 -i ../bash-5.0-upstream_fixes-1.patch
  ./configure --prefix=/usr                    \
              --docdir=/usr/share/doc/bash-5.0 \
              --without-bash-malloc            \
              --with-installed-readline
  make $JOPT
  chown -Rv tester .
su tester << EOF
PATH=$PATH make tests < $(tty)
EOF
  make install
  mv -vf /usr/bin/bash /bin
}

ch8_34_1() {
  exec /bin/bash --login +h
}

ch8_35() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch8_36() {
  sed -r -i '/^char.*parseopt_program_(doc|args)/d' src/parseopt.c
  ./configure --prefix=/usr    \
              --disable-static \
              --enable-libgdbm-compat
  make $JOPT
  make check
  make install
}

ch8_37() {
  ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
  make $JOPT
  make -j1 check
  make install
}

ch8_38() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/expat-2.2.9
  make $JOPT
  make check
  make install
  install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.9
}

ch8_39() {
  ./configure --prefix=/usr        \
              --localstatedir=/var \
              --disable-logger     \
              --disable-whois      \
              --disable-rcp        \
              --disable-rexec      \
              --disable-rlogin     \
              --disable-rsh        \
              --disable-servers
  make $JOPT
  make check
  make install
  mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
  mv -v /usr/bin/ifconfig /sbin
}

ch8_40() {
  export BUILD_ZLIB=False
  export BUILD_BZIP2=0
  sh Configure -des                                         \
               -Dprefix=/usr                                \
               -Dvendorprefix=/usr                          \
               -Dprivlib=/usr/lib/perl5/5.32/core_perl      \
               -Darchlib=/usr/lib/perl5/5.32/core_perl      \
               -Dsitelib=/usr/lib/perl5/5.32/site_perl      \
               -Dsitearch=/usr/lib/perl5/5.32/site_perl     \
               -Dvendorlib=/usr/lib/perl5/5.32/vendor_perl  \
               -Dvendorarch=/usr/lib/perl5/5.32/vendor_perl \
               -Dman1dir=/usr/share/man/man1                \
               -Dman3dir=/usr/share/man/man3                \
               -Dpager="/usr/bin/less -isR"                 \
               -Duseshrplib                                 \
               -Dusethreads
  make $JOPT
  make test
  make install
  unset BUILD_ZLIB BUILD_BZIP2
}

ch8_41() {
  perl Makefile.PL
  make $JOPT
  make test
  make install
}

ch8_42() {
  sed -i 's:\\\${:\\\$\\{:' intltool-update.in
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
  install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
}

ch8_43() {
  sed -i '361 s/{/\\{/' bin/autoscan.in
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch8_44() {
  sed -i "s/''/etags/" t/tags-lisp-space.sh
  ./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.2
  make $JOPT
  make -j4 check
  make install
}

ch8_45() {
  ./configure --prefix=/usr          \
              --bindir=/bin          \
              --sysconfdir=/etc      \
              --with-rootlibdir=/lib \
              --with-xz              \
              --with-zlib
  make $JOPT
  make install
  for target in depmod insmod lsmod modinfo modprobe rmmod; do
    ln -sfv ../bin/kmod /sbin/$target
  done

  ln -sfv kmod /bin/lsmod
}

ch8_46() {
  ./configure --prefix=/usr --disable-debuginfod --libdir=/lib
  make $JOPT
  make check
  make -C libelf install
  install -vm644 config/libelf.pc /usr/lib/pkgconfig
  rm /lib/libelf.a
}

ch8_47() {
  ./configure --prefix=/usr --disable-static --with-gcc-arch=native
  make $JOPT
  make check
  make install
}

ch8_48() {
  ./config --prefix=/usr         \
           --openssldir=/etc/ssl \
           --libdir=lib          \
           shared                \
           zlib-dynamic
  make $JOPT
  make test
  sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
  make MANSUFFIX=ssl install
  mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.1g
  cp -vfr doc/* /usr/share/doc/openssl-1.1
}

ch8_49() {
  ./configure --prefix=/usr       \
              --enable-shared     \
              --with-system-expat \
              --with-system-ffi   \
              --with-ensurepip=yes
  make $JOPT
  make install
  chmod -v 755 /usr/lib/libpython3.8.so
  chmod -v 755 /usr/lib/libpython3.so
  ln -sfv pip3.8 /usr/bin/pip3

  install -v -dm755 /usr/share/doc/python-3.8.5/html 

  tar --strip-components=1  \
      --no-same-owner       \
      --no-same-permissions \
      -C /usr/share/doc/python-3.8.5/html \
      -xvf ../python-3.8.5-docs-html.tar.bz2
}

ch8_50() {
  sed -i '/int Guess/a \
    int   j = 0;\
    char* jobs = getenv( "NINJAJOBS" );\
    if ( jobs != NULL ) j = atoi( jobs );\
    if ( j > 0 ) return j;\
  ' src/ninja.cc
  python3 configure.py --bootstrap
  ./ninja ninja_test
  ./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
  install -vm755 ninja /usr/bin/
  install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
  install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
}

ch8_51() {
  python3 setup.py build
  python3 setup.py install --root=dest
  cp -rv dest/* /
}

ch8_52() {
  patch -Np1 -i ../coreutils-8.32-i18n-1.patch
  sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
  autoreconf -fiv
  FORCE_UNSAFE_CONFIGURE=1 ./configure \
              --prefix=/usr            \
              --enable-no-install-program=kill,uptime
  make $JOPT
  make NON_ROOT_USERNAME=tester check-root
  echo "dummy:x:102:tester" >> /etc/group
  chown -Rv tester . 
  su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
  sed -i '/dummy/d' /etc/group
  make install
  mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
  mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
  mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
  mv -v /usr/bin/chroot /usr/sbin
  mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
  sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
  mv -v /usr/bin/{head,nice,sleep,touch} /bin
}

ch8_53() {
  ./configure --prefix=/usr --disable-static
  make $JOPT
  make check
  make docdir=/usr/share/doc/check-0.15.2 install
}

ch8_54() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch8_55() {
  sed -i 's/extras//' Makefile.in
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
  mkdir -v /usr/share/doc/gawk-5.1.0
  cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.1.0
}

ch8_56() {
  ./configure --prefix=/usr --localstatedir=/var/lib/locate
  make $JOPT
  chown -Rv tester .
  su tester -c "PATH=$PATH make check"
  make install
  mv -v /usr/bin/find /bin
  sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
}

ch8_57() {
  PAGE=letter ./configure --prefix=/usr
  make -j1
  make install
}

ch8_58() {
  ./configure --prefix=/usr          \
              --sbindir=/sbin        \
              --sysconfdir=/etc      \
              --disable-efiemu       \
              --disable-werror
  make $JOPT
  make install
  mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
}

ch8_59() {
  ./configure --prefix=/usr --sysconfdir=/etc
  make $JOPT
  make install
}

ch8_60() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
  mv -v /usr/bin/gzip /bin
}

ch8_61() {
  sed -i /ARPD/d Makefile
  rm -fv man/man8/arpd.8
  sed -i 's/.m_ipt.o//' tc/Makefile
  make $JOPT
  make DOCDIR=/usr/share/doc/iproute2-5.8.0 install
}

ch8_62() {
  patch -Np1 -i ../kbd-2.3.0-backspace-1.patch
  sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
  sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
  ./configure --prefix=/usr --disable-vlock
  make $JOPT
  make check
  make install
  rm -v /usr/lib/libtswrap.{a,la,so*}
  mkdir -v            /usr/share/doc/kbd-2.3.0
  cp -R -v docs/doc/* /usr/share/doc/kbd-2.3.0
}

ch8_63() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch8_64() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch8_65() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch8_66() {
  ./configure --prefix=/usr                        \
              --docdir=/usr/share/doc/man-db-2.9.3 \
              --sysconfdir=/etc                    \
              --disable-setuid                     \
              --enable-cache-owner=bin             \
              --with-browser=/usr/bin/lynx         \
              --with-vgrind=/usr/bin/vgrind        \
              --with-grap=/usr/bin/grap            \
              --with-systemdtmpfilesdir=           \
              --with-systemdsystemunitdir=
  make $JOPT
  make check
  make install
}

ch8_67() {
  FORCE_UNSAFE_CONFIGURE=1  \
  ./configure --prefix=/usr \
              --bindir=/bin
  make $JOPT
  make check
  make install
  make -C doc install-html docdir=/usr/share/doc/tar-1.32
}

ch8_68() {
  ./configure --prefix=/usr --disable-static
  make $JOPT
  make check
  make install
  make TEXMF=/usr/share/texmf install-tex
  pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
  popd
}

ch8_69() {
  echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
  ./configure --prefix=/usr
  make $JOPT
  chown -Rv tester .
  su tester -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log
  make install
  ln -sv vim /usr/bin/vi
  for L in  /usr/share/man/{,*/}man1/vim.1; do
      ln -sv vim.1 $(dirname $L)/vi.1
  done
  ln -sv ../vim/vim82/doc /usr/share/doc/vim-8.2.1361
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1 

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
}

ch8_70() {
  ./configure --prefix=/usr           \
              --bindir=/sbin          \
              --sbindir=/sbin         \
              --libdir=/usr/lib       \
              --sysconfdir=/etc       \
              --libexecdir=/lib       \
              --with-rootprefix=      \
              --with-rootlibdir=/lib  \
              --enable-manpages       \
              --disable-static
  make $JOPT
  mkdir -pv /lib/udev/rules.d
  mkdir -pv /etc/udev/rules.d
  make check
  make install
  tar -xvf ../udev-lfs-20171102.tar.xz
  make -f udev-lfs-20171102/Makefile.lfs install
  udevadm hwdb --update
}

ch8_71() {
  ./configure --prefix=/usr                            \
              --exec-prefix=                           \
              --libdir=/usr/lib                        \
              --docdir=/usr/share/doc/procps-ng-3.3.16 \
              --disable-static                         \
              --disable-kill
  make $JOPT
  make check
  make install
  mv -v /usr/lib/libprocps.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
}

ch8_72() {
  mkdir -pv /var/lib/hwclock
  ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
              --docdir=/usr/share/doc/util-linux-2.36 \
              --disable-chfn-chsh  \
              --disable-login      \
              --disable-nologin    \
              --disable-su         \
              --disable-setpriv    \
              --disable-runuser    \
              --disable-pylibmount \
              --disable-static     \
              --without-python     \
              --without-systemd    \
              --without-systemdsystemunitdir
  make $JOPT
  chown -Rv tester .
  su tester -c "make -k check"
  make install
}

ch8_73() {
  mkdir -v build
  cd       build
  ../configure --prefix=/usr           \
               --bindir=/bin           \
               --with-root-prefix=""   \
               --enable-elf-shlibs     \
               --disable-libblkid      \
               --disable-libuuid       \
               --disable-uuidd         \
               --disable-fsck
  make $JOPT
  make check
  make install
  chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
  gunzip -v /usr/share/info/libext2fs.info.gz
  install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
  makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
  install -v -m644 doc/com_err.info /usr/share/info
  install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
  cd ..
}

ch8_74() {
  sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
  sed -i 's/union wait/int/' syslogd.c
  make $JOPT
  make BINDIR=/sbin install
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
}

ch8_75() {
  patch -Np1 -i ../sysvinit-2.97-consolidated-1.patch
  make $JOPT
  make install
}

ch8_77() {
  save_lib="ld-2.32.so libc-2.32.so libpthread-2.32.so libthread_db-1.0.so"

  cd /lib

  for LIB in $save_lib; do
      objcopy --only-keep-debug $LIB $LIB.dbg 
      strip --strip-unneeded $LIB
      objcopy --add-gnu-debuglink=$LIB.dbg $LIB 
  done    

  save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.28
               libitm.so.1.0.0 libatomic.so.1.2.0" 

  cd /usr/lib

  for LIB in $save_usrlib; do
      objcopy --only-keep-debug $LIB $LIB.dbg
      strip --strip-unneeded $LIB
      objcopy --add-gnu-debuglink=$LIB.dbg $LIB
  done

  unset LIB save_lib save_usrlib

  find /usr/lib -type f -name \*.a \
     -exec strip --strip-debug {} ';'

  find /lib /usr/lib -type f -name \*.so* ! -name \*dbg \
     -exec strip --strip-unneeded {} ';'

  find /{bin,sbin} /usr/{bin,sbin,libexec} -type f \
      -exec strip --strip-all {} ';'
}

ch8_78_1() {
  rm -rf /tmp/*
  logout
}

ch8_78_2() {
  chroot "$LFS" /usr/bin/env -i          \
      HOME=/root TERM="$TERM"            \
      PS1='(lfs chroot) \u:\w\$ '        \
      PATH=/bin:/usr/bin:/sbin:/usr/sbin \
      /bin/bash --login
}

ch8_78_3() {
  rm -f /usr/lib/lib{bfd,opcodes}.a
  rm -f /usr/lib/libctf{,-nobfd}.a
  rm -f /usr/lib/libbz2.a
  rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
  rm -f /usr/lib/libltdl.a
  rm -f /usr/lib/libfl.a
  rm -f /usr/lib/libz.a
  find /usr/lib /usr/libexec -name \*.la -delete
  find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
  rm -rf /tools
  userdel -r tester
}

ch9_2() {
  make install
}

ch9_4() {
  bash /lib/udev/init-net-rules.sh
  cat /etc/udev/rules.d/70-persistent-net.rules
}

ch9_5() {
cd /etc/sysconfig/
cat > ifconfig."$IFACE" << EOF
ONBOOT=yes
IFACE="$IFACE"
SERVICE=ipv4-static
IP=192.168.1.2
GATEWAY=192.168.1.1
PREFIX=24
BROADCAST=192.168.1.255
EOF

cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf
#domain lfsbox
nameserver 8.8.8.8
nameserver 8.8.4.4
# End /etc/resolv.conf
EOF

echo "lfsbox" > /etc/hostname

cat > /etc/hosts << "EOF"
127.0.0.1 localhost.localdomain localhost
127.0.1.1 lfsbox
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOF
}

ch9_6() {
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

ch9_7() {
cat > /etc/profile <<"EOF"
export LANG=en_US.UTF-8
EOF
}

ch9_8() {
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

ch9_9() {
cat > /etc/shells << "EOF"
/bin/sh
/bin/bash
EOF
}

ch10_2() {
cat > /etc/fstab << EOF
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

${LFSPART}     /             ext4    defaults            1     1
${SWAPPART}    swap         swap     pri=1               0     0
proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs          /run         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF
}

ch10_3() {
make mrproper
#make menuconfig
cp /sources/lfs/src/.config .config
make
make modules_install
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-5.8.3-lfs-10.0
cp -iv System.map /boot/System.map-5.8.3
cp -iv .config /boot/config-5.8.3
install -d /usr/share/doc/linux-5.8.3
cp -r Documentation/* /usr/share/doc/linux-5.8.3
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
}

ch10_4() {
grub-install /dev/"${DSK}"

cat > /boot/grub/grub.cfg << EOF
set default=0
set timeout=5

insmod ext2
set root=(hd0,2)

menuentry "GNU/Linux, Linux 5.8.3-lfs-10.0" {
	linux /boot/vmlinuz-5.8.3-lfs-10.0 root=/dev/${DSK}${DSK2} ro
}
EOF
}

ch11_1() {
echo 10.0 > /etc/lfs-release
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="10.0"
DISTRIB_CODENAME="badidea"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF
cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="10.0"
ID=lfs
PRETTY_NAME="Linux From Scratch 10.0"
VERSION_CODENAME="badidea"
EOF
}

dhcpcd_8_0_3() {
./configure --libexecdir=/lib/dhcpcd \
            --dbdir=/var/lib/dhcpcd  &&
make
make install

# run script from lfs-bootscriptsd
pushd /sources
tar -xvf blfs-bootscripts-20190609.tar.xz
cd blfs-bootscripts-20190609
make install-service-dhcpcd
cd ..
rm -rf blfs-bootscripts-20190609
popd
# create config file as root
cat > /etc/sysconfig/ifconfig."$IFACE" << EOF
ONBOOT="yes"
IFACE="$IFACE"
SERVICE="dhcpcd"
DHCP_START="-b -q"
DHCP_STOP="-k"
EOF
}

wget_1_20_3() {
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl &&
make
make install
}

openssh_8_0p1() {
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
make install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&

install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-8.0p1     &&
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-8.0p1
}

ch11_3_1() {
  cd /sources
  case "$1" in
  1) bs dhcpcd_8_0_3 dhcpcd-8.0.3 .tar.xz ;; # BLFS Ch. 14
  2) bs wget_1_20_3 wget-1.20.3 .tar.gz ;; # BLFS Ch. 15
  3) bs openssh_8_0p1 openssh-8.0p1 .tar.gz ;; # BLFS Ch. 15
  *) 
    for i in {1..3}
    do
      ch11_3_1 $i
    done
    ;;
  esac
}

ch11_3_2() {
  logout
}

ch11_3_3() {
  umount -v $LFS/dev/pts
  umount -v $LFS/dev
  umount -v $LFS/run
  umount -v $LFS/proc
  umount -v $LFS/sys
  umount -v $LFS/usr
  umount -v $LFS/home
  umount -v $LFS
  umount -v $LFS
}

ch11_3_4() {
  shutdown -r now
}

# compile source
bs() { # package, extension, chapternum
  PK=$2; EXT=$3; NUM=$1; BD=$4;
  cd $BD/sources
  tar -xf $BD/sources/$PK$EXT
  cd $PK
  $NUM >$LP/$NUM.log 2>$LP/$NUM.err
  cd $BD/sources
  rm -rf $PK
}

stage0() {
  if [ $SYS = "ubuntu" ]; then
    sudo sed -i '/archive.ubuntu.com\/ubuntu\/ focal /s/$/ universe multiverse/' /etc/apt/sources.list
    sudo apt update
  fi
  # This script seeks to set up a system for lfs
  wget http://jcantrell.me/jordan/files/setup/jopm/jopm.sh
  # Run basic workstation setup
  sh jopm.sh usecase minimumcore
  sh jopm.sh install valgrind
  sh jopm.sh install git
  if [ $SYS = "tinycore" ]; then
    # Blindly clobber sh and make it a link to bash
    sudo rm /bin/sh
    sudo ln -s /usr/local/bin/bash /bin/sh
    sudo rm /usr/bin/ar
    sudo cp -P /usr/local/bin/* /bin
    sudo cp -P /usr/local/sbin/* /sbin
  fi
  wget $URL/lfs/raw/"$BRANCH"/src/lfs.sh
  sudo bash lfs.sh stage1 "$SYS" "$DSK" "$DSK1" "$DSK2"
}

stage1() {
  [ $SYS = "tinycore" ] && export PATH=/usr/local/sbin:$PATH
  ch2_2
  ch2_5
  ch2_6
  ch2_7
  ch3_1
  ch4_2
  ch4_3
}

stage2() {
  ch4_4
}

stage3() {
cd $LFS/sources
case "$1" in
  2) { time bs ch5_2 binutils-2.35 .tar.xz $LFS; } 2> $LP/sbu ;;
  3) bs ch5_3 gcc-10.2.0       .tar.xz $LFS ;;
  4) bs ch5_4 linux-5.8.3      .tar.xz $LFS ;;
  5) bs ch5_5 glibc-2.32       .tar.xz $LFS ;;
  6) bs ch5_6 gcc-10.2.0       .tar.xz $LFS ;;
  *) 
    for i in {2..6}
    do
      stage3 $i
    done
    ;;
  esac
}

stage4() {
  cd $LFS/sources
  case "$1" in
  2)  bs ch6_2  m4-1.4.18       .tar.xz $LFS ;;
  3)  bs ch6_3  ncurses-6.2     .tar.gz $LFS ;;
  4)  bs ch6_4  bash-5.0        .tar.gz $LFS ;;
  5)  bs ch6_5  coreutils-8.32  .tar.xz $LFS ;;
  6)  bs ch6_6  diffutils-3.7   .tar.xz $LFS ;;
  7)  bs ch6_7  file-5.39       .tar.gz $LFS ;;
  8)  bs ch6_8  findutils-4.7.0 .tar.xz $LFS ;;
  9)  bs ch6_9  gawk-5.1.0      .tar.xz $LFS ;;
  10) bs ch6_10 grep-3.4        .tar.xz $LFS ;;
  11) bs ch6_11 gzip-1.10       .tar.xz $LFS ;;
  12) bs ch6_12 make-4.3        .tar.gz $LFS ;;
  13) bs ch6_13 patch-2.7.6     .tar.xz $LFS ;;
  14) bs ch6_14 sed-4.8         .tar.xz $LFS ;;
  15) bs ch6_15 tar-1.32        .tar.xz $LFS ;;
  16) bs ch6_16 xz-5.2.5        .tar.xz $LFS ;;
  17) bs ch6_17 binutils-2.35   .tar.xz $LFS ;;
  18) bs ch6_18 gcc-10.2.0      .tar.xz $LFS ;;
  *) 
    for i in {2..18}
    do
      stage4 $i
    done
    ;;
  esac
}

stage5() {
  ch7_2
  ch7_3
}

stage5_2() {
  ch7_4
}

stage6() {
  ch7_5
  ch7_6_1
}

stage6_2() {
  ch7_6_2
}

stage7() {
  cd /sources
  case "$1" in
  7)  bs ch7_7  gcc-10.2.0      .tar.xz $LFS ;;
  8)  bs ch7_8  gettext-0.21    .tar.xz $LFS ;;
  9)  bs ch7_9  bison-3.7.1     .tar.xz $LFS ;;
  10) bs ch7_10 perl-5.32.0     .tar.xz $LFS ;;
  11) bs ch7_11 Python-3.8.5    .tar.xz $LFS ;;
  12) bs ch7_12 texinfo-6.7     .tar.xz $LFS ;;
  13) bs ch7_13 util-linux-2.36 .tar.xz $LFS ;;
  14) ch7_14_1 ;;
  *) 
    for i in {7..14}
    do
      stage7 $i
    done
    ;;
  esac
}

stage7_2() {
  ch7_14_2
}

stage8() {
  set +e
  cd $LFS/sources
  case "$1" in
    3)  bs ch8_3  man-pages-5.08    .tar.xz ;;
    4)  bs ch8_4  tcl8.6.10     -src.tar.gz ;;
    5)  bs ch8_5  expect5.45.4      .tar.gz ;;
    6)  bs ch8_6  dejagnu-1.6.2     .tar.gz ;;
    7)  bs ch8_7  iana-etc-20200821 .tar.gz ;;
    8)  bs ch8_8  glibc-2.32        .tar.xz ;;
    9)  bs ch8_9  zlib-1.2.11       .tar.xz ;;
    10) bs ch8_10 bzip2-1.0.8       .tar.gz ;;
    11) bs ch8_11 xz-5.2.5          .tar.xz ;;
    12) bs ch8_12 zstd-1.4.5        .tar.gz ;;
    13) bs ch8_13 file-5.39         .tar.gz ;;
    14) bs ch8_14 readline-8.0      .tar.gz ;;
    15) bs ch8_15 m4-1.4.18         .tar.xz ;;
    16) bs ch8_16 bc-3.1.5          .tar.xz ;;
    17) bs ch8_17 flex-2.6.4        .tar.gz ;;
    18) bs ch8_18 binutils-2.35     .tar.xz ;;
    19) bs ch8_19 gmp-6.2.0         .tar.xz ;;
    20) bs ch8_20 mpfr-4.1.0        .tar.xz ;;
    21) bs ch8_21 mpc-1.1.0         .tar.gz ;;
    22) bs ch8_22 attr-2.4.48       .tar.gz ;;
    23) bs ch8_23 acl-2.2.53        .tar.gz ;;
    24) bs ch8_24 libcap-2.42       .tar.xz ;;
    25) bs ch8_25 shadow-4.8.1      .tar.xz ;;
    26) bs ch8_26 gcc-10.2.0        .tar.xz ;;
    27) bs ch8_27 pkg-config-0.29.2 .tar.gz ;;
    28) bs ch8_28 ncurses-6.2       .tar.gz ;;
    29) bs ch8_29 sed-4.8           .tar.xz ;;
    30) bs ch8_30 psmisc-23.3       .tar.xz ;;
    31) bs ch8_31 gettext-0.21      .tar.xz ;;
    32) bs ch8_32 bison-3.7.1        .tar.xz ;;
    33) bs ch8_33 grep-3.4          .tar.xz ;;
    34) bs ch8_34 bash-5.0          .tar.gz ;;
    *) 
      for i in {3..34}
      do
        stage8 $i
      done
      ;;
  esac
}

stage8_1() {
  ch8_34_1
}

stage8_2() {
  set +e
  cd $LFS/sources
  case "$1" in
    35) bs ch8_35 libtool-2.4.6     .tar.xz ;;
    36) bs ch8_36 gdbm-1.18.1       .tar.gz ;;
    37) bs ch8_37 gperf-3.1         .tar.gz ;;
    38) bs ch8_38 expat-2.2.9       .tar.xz ;;
    39) bs ch8_39 inetutils-1.9.4   .tar.xz ;;
    40) bs ch8_40 perl-5.32.0       .tar.xz ;;
    41) bs ch8_41 XML-Parser-2.46   .tar.gz ;;
    42) bs ch8_42 intltool-0.51.0   .tar.gz ;;
    43) bs ch8_43 autoconf-2.69     .tar.xz ;;
    44) bs ch8_44 automake-1.16.2   .tar.xz ;;
    45) bs ch8_45 kmod-27           .tar.xz ;;
    46) bs ch8_46 elfutils-0.180    .tar.bz2 ;;
    47) bs ch8_47 libffi-3.3        .tar.gz ;;
    48) bs ch8_48 openssl-1.1.1g    .tar.gz ;;
    49) bs ch8_49 Python-3.8.5      .tar.xz ;;
    50) bs ch8_50 ninja-1.10.0      .tar.gz ;;
    51) bs ch8_51 meson-0.55.0      .tar.gz ;;
    52) bs ch8_52 coreutils-8.32    .tar.xz ;;
    53) bs ch8_53 check-0.15.2      .tar.gz ;;
    54) bs ch8_54 diffutils-3.7     .tar.xz ;;
    55) bs ch8_55 gawk-5.1.0        .tar.xz ;;
    56) bs ch8_56 findutils-4.7.0   .tar.xz ;;
    57) bs ch8_57 groff-1.22.4      .tar.gz ;;
    58) bs ch8_58 grub-2.04         .tar.xz ;;
    59) bs ch8_59 less-551          .tar.gz ;;
    60) bs ch8_60 gzip-1.10         .tar.xz ;;
    61) bs ch8_61 iproute2-5.8.0    .tar.xz ;;
    62) bs ch8_62 kbd-2.3.0         .tar.xz ;;
    63) bs ch8_63 libpipeline-1.5.3 .tar.gz ;;
    64) bs ch8_64 make-4.3          .tar.gz ;;
    65) bs ch8_65 patch-2.7.6       .tar.xz ;;
    66) bs ch8_66 man-db-2.9.3      .tar.xz ;;
    67) bs ch8_67 tar-1.32          .tar.xz ;;
    68) bs ch8_68 texinfo-6.7       .tar.xz ;;
    69) bs ch8_69 vim-8.2.1361      .tar.gz ;;
    70) bs ch8_70 eudev-3.2.9       .tar.gz ;;
    71) bs ch8_71 procps-ng-3.3.16  .tar.xz ;;
    72) bs ch8_72 util-linux-2.36   .tar.xz ;;
    73) bs ch8_73 e2fsprogs-1.45.6  .tar.gz ;;
    74) bs ch8_74 sysklogd-1.5.1    .tar.gz ;;
    75) bs ch8_75 sysvinit-2.97     .tar.xz ;;
    77) ch8_77 ;;
    78) ch8_78_1 ;;
    *) 
      for i in {35..75}
      do
        stage8_2 $i
      done
      stage8_2 77
      stage8_2 78
      ;;
  esac
}

stage8_3() {
  ch8_78_2
}

stage8_4() {
  ch8_78_3
}

stage9() {
  bs ch9_2 lfs-bootscripts-20200818 .tar.xz
  ch9_4
  ch9_5
  ch9_6
  ch9_7
  ch9_8
  ch9_9
  ch10_2
  bs ch10_3 linux-5.8.3 .tar.xz
  ch10_4
  ch11_1
  ch11_3_1
  ch11_3_2
}

stage10() {
  ch11_3_3
  ch11_3_4
}

clean() {
  umount -v $LFS/dev/pts
  umount -v $LFS/dev
  umount -v $LFS/run
  umount -v $LFS/proc
  umount -v $LFS/sys
  umount -v $LFS
  swapoff /dev/${DSK}${DSK1}
  dd if=/dev/zero of=/dev/${DSK}${DSK2} bs=1M count=1
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$DSK
  d   # delete partition
      # default
  d   # delete partition
      # default
  w   #
EOF
  userdel -r lfs
}

restoreBackup() {
  ch7_14_3
  ch7_3
  ch7_4
}

initchroot() {
  ch2_7 # mount $LFS
  ch7_3 # mount virtual filesystems
}

finalchroot() {
  ch8_78_2
}

$1 $8
