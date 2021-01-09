#!/bin/bash
set -xe
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
BRANCH="onefile"
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
mkdir -v $LFS/tools
ln -sv $LFS/tools /
}

ch4_3_1() {
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
chown -v lfs $LFS/tools
chown -vR lfs $LFS/sources
}

ch4_3_2() {
# make sure to run lfs2.sh as user lfs - could we pass the file to su?
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
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF

# /usr/local/bin isn't official; for tinycore only
# that is where tce-load seems to install everything
[ $SYS = "tinycore" ] && sed -i ~/.bashrc '/^PATH/c\PATH=\/tools\/bin:\/usr\/local\/bin:\/bin:\/usr\/bin'

source ~/.bash_profile
}

ch5_4() {
  mkdir -v build
  cd build

  ../configure --prefix=/tools            \
                             --with-sysroot=$LFS        \
                             --with-lib-path=/tools/lib \
                             --target=$LFS_TGT          \
                             --disable-nls              \
                             --disable-werror

  make $JOPT

  case $(uname -m) in
    x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
  esac

  make install

  cd ..
}

ch5_5() {
  tar -xf ../mpfr-4.0.2.tar.xz
  mv -v mpfr-4.0.2 mpfr
  tar -xf ../gmp-6.1.2.tar.xz
  mv -v gmp-6.1.2 gmp
  tar -xf ../mpc-1.1.0.tar.gz
  mv -v mpc-1.1.0 mpc
  
  for file in gcc/config/{linux,i386/linux{,64}}.h
  do
    cp -uv $file{,.orig}
    sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
        -e 's@/usr@/tools@g' $file.orig > $file
    echo '
  #undef STANDARD_STARTFILE_PREFIX_1
  #undef STANDARD_STARTFILE_PREFIX_2
  #define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
  #define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
    touch $file.orig
  done

  case $(uname -m) in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
    ;;
  esac
  
  mkdir -v build
  cd build
  
  ../configure                                         \
      --target=$LFS_TGT                                \
      --prefix=/tools                                  \
      --with-glibc-version=2.11                        \
      --with-sysroot=$LFS                              \
      --with-newlib                                    \
      --without-headers                                \
      --with-local-prefix=/tools                       \
      --with-native-system-header-dir=/tools/include   \
      --disable-nls                                    \
      --disable-shared                                 \
      --disable-multilib                               \
      --disable-decimal-float                          \
      --disable-threads                                \
      --disable-libatomic                              \
      --disable-libgomp                                \
      --disable-libquadmath                            \
      --disable-libssp                                 \
      --disable-libvtv                                 \
      --disable-libstdcxx                              \
      --enable-languages=c,c++
  
  make $JOPT
  
  make install

  cd ..
}

ch5_6() {
  make mrproper
  make INSTALL_HDR_PATH=dest headers_install
  cp -rv dest/include/* /tools/include
}

ch5_7() {
  mkdir -v build
  cd build
  ../configure                                        \
        --prefix=/tools                               \
        --host=$LFS_TGT                               \
        --build=$(../scripts/config.guess)            \
        --enable-kernel=3.2                           \
        --with-headers=/tools/include                 
  make $JOPT
  make install
   # Now test to make sure we compile correctly
  echo 'int main(){}' > dummy.c
  $LFS_TGT-gcc dummy.c
  readelf -l a.out | grep ': /tools'
  rm -v dummy.c a.out
  cd ..
}

ch5_8() {
  mkdir -v build
  cd build
  ../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/9.2.0
  make $JOPT
  make install
  cd ..
}

ch5_9() {
  mkdir -v build
  cd build
  
  CC=$LFS_TGT-gcc                \
  AR=$LFS_TGT-ar                 \
  RANLIB=$LFS_TGT-ranlib         \
  ../configure     \
      --prefix=/tools            \
      --disable-nls              \
      --disable-werror           \
      --with-lib-path=/tools/lib \
      --with-sysroot
  
  make $JOPT
  make install
  make -C ld clean
  make -C ld LIB_PATH=/usr/lib:/lib
  cp -v ld/ld-new /tools/bin

  cd ..
}

ch5_10() {
  cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h
  for file in gcc/config/{linux,i386/linux{,64}}.h
  do
    cp -uv $file{,.orig}
    sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
        -e 's@/usr@/tools@g' $file.orig > $file
    echo '
  #undef STANDARD_STARTFILE_PREFIX_1
  #undef STANDARD_STARTFILE_PREFIX_2
  #define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
  #define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
    touch $file.orig
  done

  case $(uname -m) in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
    ;;
  esac

  tar -xf ../mpfr-4.0.2.tar.xz
  mv -v mpfr-4.0.2 mpfr
  tar -xf ../gmp-6.1.2.tar.xz
  mv -v gmp-6.1.2 gmp
  tar -xf ../mpc-1.1.0.tar.gz
  mv -v mpc-1.1.0 mpc
  
  mkdir -v build
  cd build
  
  CC=$LFS_TGT-gcc                                      \
  CXX=$LFS_TGT-g++                                     \
  AR=$LFS_TGT-ar                                       \
  RANLIB=$LFS_TGT-ranlib                               \
  ../configure                               \
      --prefix=/tools                                  \
      --with-local-prefix=/tools                       \
      --with-native-system-header-dir=/tools/include   \
      --enable-languages=c,c++                         \
      --disable-libstdcxx-pch                          \
      --disable-multilib                               \
      --disable-bootstrap                              \
      --disable-libgomp
  
  make $JOPT
  make install
  ln -sv gcc /tools/bin/cc
  
  echo 'int main(){}' > dummy.c
  cc dummy.c
  readelf -l a.out | grep ': /tools'
  rm -v dummy.c a.out
  cd ..
}

ch5_11() {
  cd unix
  ./configure --prefix=/tools
  
  make $JOPT
  
  TZ=UTC make test
  
  make install
  chmod -v u+w /tools/lib/libtcl8.6.so
  make install-private-headers
  ln -sv tclsh8.6 /tools/bin/tclsh

  cd ..
}

ch5_12() {
  cp -v configure{,.orig}
  sed 's:/usr/local/bin:/bin:' configure.orig > configure
  
  ./configure --prefix=/tools       \
              --with-tcl=/tools/lib \
              --with-tclinclude=/tools/include
  
  make $JOPT
  
  [ ! -z $TESTS ] && make test
  
  make SCRIPTS="" install
}

ch5_13() {
  ./configure --prefix=/tools
  make install
  if [ ! -z $TESTS ]; then make check; fi
}

ch5_14() {
  sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
  echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
  ./configure --prefix=/tools
  make $JOPT
  
  [ ! -z $TESTS ] && make check
  make install
}

ch5_15() {
  sed -i s/mawk// configure
  ./configure --prefix=/tools \
              --with-shared   \
              --without-debug \
              --without-ada   \
              --enable-widec  \
              --enable-overwrite
  
  make $JOPT
  make install
  ln -s libncursesw.so /tools/lib/libncurses.so
}

ch5_16() {
  ./configure --prefix=/tools --without-bash-malloc
  make $JOPT
  [ ! -z $TESTS ] && make tests
  make install
  ln -sv bash /tools/bin/sh
}

ch5_17() {
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_18() {
  make $JOPT
  make PREFIX=/tools install
}

ch5_19() {
  ./configure --prefix=/tools --enable-install-program=hostname
  make $JOPT
  [ ! -z $TESTS ] && make RUN_EXPENSIVE_TESTS=yes check
  make install
}

ch5_20() {
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_21() {
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_22() {
  sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
  sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
  echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_23() {
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_24() {
  ./configure --disable-shared
  make $JOPT
  cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /tools/bin
}

ch5_25() {
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_26() {
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_27() {
  sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
  ./configure --prefix=/tools --without-guile
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_28() {
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_29() {
  sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth
  
  make $JOPT
  
  cp -v perl cpan/podlators/scripts/pod2man /tools/bin
  mkdir -pv /tools/lib/perl5/5.30.0
  cp -Rv lib/* /tools/lib/perl5/5.30.0
}

ch5_30() {
  sed -i '/def add_multiarch_paths/a \        return' setup.py
  ./configure --prefix=/tools --without-ensurepip
  make $JOPT
  make install
}

ch5_31() {
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_32() {
  ./configure -prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_33() {
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_34() {
  ./configure --prefix=/tools
  make $JOPT
  [ ! -z $TESTS ] && make check
  make install
}

ch5_35() {
  strip --strip-debug /tools/lib/*
  /usr/bin/strip --strip-unneeded /tools/{,s}bin/*
  rm -rf /tools/{,share}/{info,man,doc}
  find /tools/{lib,libexec} -name \*.la -delete
}

ch5_36() {
  chown -R root:root $LFS/tools
}

ch6_2() {
  mkdir -pv $LFS/{dev,proc,sys,run}
  
  [ ! -f $LFS/dev/console ] && mknod -m 600 $LFS/dev/console c 5 1
  [ ! -f $LFS/dev/null ] && mknod -m 666 $LFS/dev/null c 1 3
  
  mount -v --bind /dev $LFS/dev
  
  mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
  mount -vt proc proc $LFS/proc
  mount -vt sysfs sysfs $LFS/sys
  mount -vt tmpfs tmpfs $LFS/run
  
  if [ -h $LFS/dev/shm ]; then
    mkdir -pv $LFS/$(readlink $LFS/dev/shm)
  fi
}

ch6_4() {
  chroot "$LFS" /tools/bin/env -i \
      HOME=/root                  \
      TERM="$TERM"                \
      PS1='\u:\w\$ '              \
      PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
      /tools/bin/bash --login +h
}

ch6_5() {
  mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
  mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
  install -dv -m 0750 /root
  install -dv -m 1777 /tmp /var/tmp
  mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
  mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
  mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
  mkdir -v  /usr/libexec
  mkdir -pv /usr/{,local/}share/man/man{1..8}
  
  case $(uname -m) in
   x86_64) ln -sv lib /lib64
           ln -sv lib /usr/lib64
           ln -sv lib /usr/local/lib64 ;;
  esac
  
  mkdir -v /var/{log,mail,spool}
  ln -sv /run /var/run
  ln -sv /run/lock /var/lock
  mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}
}

ch6_6_1() {
  ln -sv /tools/bin/{bash,cat,chmod,dd,echo,ln,mkdir,pwd,rm,stty,touch} /bin
  ln -sv /tools/bin/{env,install,perl,printf}         /usr/bin
  ln -sv /tools/lib/libgcc_s.so{,.1}                  /usr/lib
  ln -sv /tools/lib/libstdc++.{a,so{,.6}}             /usr/lib
  
  ln -sv bash /bin/sh
  
  ln -sv /proc/self/mounts /etc/mtab

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

  # This will need to be run separately
  exec /tools/bin/bash --login +h
}

ch6_6_2() {
  touch /var/log/{btmp,lastlog,wtmp}
  chgrp -v utmp /var/log/lastlog
  chmod -v 664  /var/log/lastlog
  chmod -v 600  /var/log/btmp
}

ch6_7() {
  make mrproper
  make INSTALL_HDR_PATH=dest headers_install
  find dest/include \( -name .install -o -name ..install.cmd \) -delete
  cp -rv dest/include/* /usr/include
}

ch6_8() {
  make install
}

ch6_9() {
patch -Np1 -i ../glibc-2.30-fhs-1.patch
sed -i '/asm.socket.h/a# include <linux/sockios.h>' \
   sysdeps/unix/sysv/linux/bits/socket.h
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
    ;;
esac
mkdir -v build
cd       build
CC="gcc -ffile-prefix-map=/tools=/usr" \
../configure --prefix=/usr                          \
             --disable-werror                       \
             --enable-kernel=3.2                    \
             --enable-stack-protector=strong        \
             --with-headers=/usr/include            \
             libc_cv_slibdir=/lib	\
						>$LP/ch6_9.conf.log 2>$LP/ch6_9.conf.err
make $JOPT >$LP/ch6_9.conf.log 2>$LP/ch6_9.conf.err
case $(uname -m) in
  i?86)   ln -sfnv $PWD/elf/ld-linux.so.2        /lib ;;
  x86_64) ln -sfnv $PWD/elf/ld-linux-x86-64.so.2 /lib ;;
esac
make check >$LP/ch6_9.conf.log 2>$LP/ch6_9.conf.err
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install >$LP/ch6_9.conf.log 2>$LP/ch6_9.conf.err
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
make localedata/install-locales

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

tar -xf ../../tzdata2019b.tar.gz

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

  cd ..
}

ch6_10() {
  mv -v /tools/bin/{ld,ld-old}
  mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
  mv -v /tools/bin/{ld-new,ld}
  ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld
  
  gcc -dumpspecs | sed -e 's@/tools@@g'                   \
      -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
      -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
      `dirname $(gcc --print-libgcc-file-name)`/specs
  
  echo 'int main(){}' > dummy.c
  cc dummy.c -v -Wl,--verbose &> dummy.log
  readelf -l a.out | grep ': /lib'
  
  grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
  grep -B1 '^ /usr/include' dummy.log
  grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
  grep "/lib.*/libc.so.6 " dummy.log
  grep found dummy.log
  rm -v dummy.c a.out dummy.log
}

ch6_11() {
  ./configure --prefix=/usr
  make $JOPT 
  make check
  make install
  mv -v /usr/lib/libz.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
}

ch6_12() {
  ./configure --prefix=/usr
  make $JOPT 
  make check
  make install
}

ch6_13() {
  sed -i '/MV.*old/d' Makefile.in
  sed -i '/{OLDSUFF}/c:' support/shlib-install
  
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/readline-8.0
  
  make $JOPT SHLIB_LIBS="-L/tools/lib -lncursesw"
  make SHLIB_LIBS="-L/tools/lib -lncursesw" install
  mv -v /usr/lib/lib{readline,history}.so.* /lib
  chmod -v u+w /lib/lib{readline,history}.so.*
  ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
  ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
  install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.0
}

ch6_14() {
  sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
  echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
  ./configure --prefix=/usr
  make $JOPT 
  make check
  make install
}

ch6_15() {
  PREFIX=/usr CC=gcc CFLAGS="-std=c99" ./configure.sh -G -O3
  make $JOPT 
  make test
  make install
}

ch6_16() {
  expect -c "spawn ls"
  sed -i '/@\tincremental_copy/d' gold/testsuite/Makefile.in
  mkdir -v build
  cd build
  ../configure --prefix=/usr       \
               --enable-gold       \
               --enable-ld=default \
               --enable-plugins    \
               --enable-shared     \
               --disable-werror    \
               --enable-64-bit-bfd \
               --with-system-zlib
  
  make $JOPT tooldir=/usr
  make -k check
  make tooldir=/usr install
}

ch6_17() {
  ./configure --prefix=/usr    \
              --enable-cxx     \
              --disable-static \
              --docdir=/usr/share/doc/gmp-6.1.2
  make $JOPT 
  make html
  make check 2>&1 | tee gmp-check-log
  awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
  make install
  make install-html
}

ch6_18() {
  ./configure --prefix=/usr        \
              --disable-static     \
              --enable-thread-safe \
              --docdir=/usr/share/doc/mpfr-4.0.2
  make $JOPT 
  make html
  make check
  make install
  make install-html
}

ch6_19() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/mpc-1.1.0
  make $JOPT 
  make html
  make check
  make install
  make install-html
}

ch6_20() {
  sed -i 's/groups$(EXEEXT) //' src/Makefile.in
  find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
  find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
  find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
  
  sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
         -e 's@/var/spool/mail@/var/mail@' etc/login.defs
  
  sed -i 's/1000/999/' etc/useradd
  ./configure --sysconfdir=/etc --with-group-name-max-length=32
  make $JOPT 
  make install
  mv -v /usr/bin/passwd /bin

  pwconv
  grpconv
  echo root:rootpass | chpasswd
}

ch6_21() {
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir -v build
cd       build
SED=sed                               \
../configure --prefix=/usr            \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --with-system-zlib
make $JOPT
ulimit -s 32768
chown -Rv nobody . 
su nobody -s /bin/bash -c "PATH=$PATH make -k check"
../contrib/test_summary
make install
rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/9.2.0/include-fixed/bits/

chown -v -R root:root \
    /usr/lib/gcc/*linux-gnu/9.2.0/include{,-fixed}

ln -sv ../usr/bin/cpp /lib

ln -sv gcc /usr/bin/cc
install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/9.2.0/liblto_plugin.so \
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
cd ..
}

ch6_22() {
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

ch6_23() {
  ./configure --prefix=/usr              \
              --with-internal-glib       \
              --disable-host-tool        \
              --docdir=/usr/share/doc/pkg-config-0.29.2
  make $JOPT
  make check
  make install
}

ch6_24 () {
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
  mkdir -v       /usr/share/doc/ncurses-6.1
  cp -v -R doc/* /usr/share/doc/ncurses-6.1
}

ch6_25 () {
  ./configure --prefix=/usr     \
              --bindir=/bin     \
              --disable-static  \
              --sysconfdir=/etc \
              --docdir=/usr/share/doc/attr-2.4.48
  make $JOPT
  make check
  make install
  mv -v /usr/lib/libattr.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
}

ch6_26() {
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

ch6_27() {
  sed -i '/install.*STALIBNAME/d' libcap/Makefile
  make $JOPT
  make RAISE_SETFCAP=no lib=lib prefix=/usr install
  chmod -v 755 /usr/lib/libcap.so.2.27
  mv -v /usr/lib/libcap.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
}

ch6_28() {
  sed -i 's/usr/tools/'                 build-aux/help2man
  sed -i 's/testsuite.panic-tests.sh//' Makefile.in
  ./configure --prefix=/usr --bindir=/bin
  make $JOPT
  make html
  make check
  make install
  install -d -m755           /usr/share/doc/sed-4.7
  install -m644 doc/sed.html /usr/share/doc/sed-4.7
}

ch6_29() {
  ./configure --prefix=/usr
  make $JOPT
  make install
  mv -v /usr/bin/fuser   /bin
  mv -v /usr/bin/killall /bin
}

ch6_30() {
  make $JOPT
  make install
}

ch6_31() {
  sed -i '6855 s/mv/cp/' Makefile.in
  ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.4.1
  make -j1
  make install
}

ch6_32() {
  sed -i "/math.h/a #include <malloc.h>" src/flexdef.h
  HELP2MAN=/tools/bin/true \
  ./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4
  make $JOPT
  make check
  make install
  ln -sv flex /usr/bin/lex
}

ch6_33() {
  ./configure --prefix=/usr --bindir=/bin
  make $JOPT
  make -k check
  make install
}

ch6_34() {
  ./configure --prefix=/usr                    \
              --docdir=/usr/share/doc/bash-5.0 \
              --without-bash-malloc            \
              --with-installed-readline
  make $JOPT
  chown -Rv nobody .
  su nobody -s /bin/bash -c "PATH=$PATH HOME=/home make tests"
  make install
  mv -vf /usr/bin/bash /bin
}

ch6_35() {
  ./configure --prefix=/usr
  make $JOPT
  make check # TESTSUITEFLAGS=-j`nproc
  make install
}

ch6_36() {
  ./configure --prefix=/usr    \
              --disable-static \
              --enable-libgdbm-compat
  make $JOPT
  make check
  make install
}

ch6_37() {
  ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
  make $JOPT
  make -j1 check
  make install
}

ch6_38() {
  sed -i 's|usr/bin/env |bin/|' run.sh.in
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/expat-2.2.7
  make $JOPT
  make check
  make install
  install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.7
}

ch6_39() {
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

ch6_40() {
  echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
  export BUILD_ZLIB=False
  export BUILD_BZIP2=0
  sh Configure -des -Dprefix=/usr                 \
                    -Dvendorprefix=/usr           \
                    -Dman1dir=/usr/share/man/man1 \
                    -Dman3dir=/usr/share/man/man3 \
                    -Dpager="/usr/bin/less -isR"  \
                    -Duseshrplib                  \
                    -Dusethreads
  make $JOPT
  make -k test
  make install
  unset BUILD_ZLIB BUILD_BZIP2
}

ch6_41() {
  perl Makefile.PL
  make $JOPT
  make test
  make install
}

ch6_42() {
  sed -i 's:\\\${:\\\$\\{:' intltool-update.in
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
  install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
}

ch6_43() {
  sed '361 s/{/\\{/' -i bin/autoscan.in
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch6_44() {
  ./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1
  make $JOPT
  make -j4 check
  make install
}

ch6_45() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/xz-5.2.4
  make $JOPT
  make check
  make install
  mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
  mv -v /usr/lib/liblzma.so.* /lib
  ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
}

ch6_46() {
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

ch6_47() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/gettext-0.20.1
  make $JOPT
  make check
  make install
  chmod -v 0755 /usr/lib/preloadable_libintl.so
}

ch6_48() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make -C libelf install
  install -vm644 config/libelf.pc /usr/lib/pkgconfig
}

ch6_49() {
  sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
      -i include/Makefile.in
  
  sed -e '/^includedir/ s/=.*$/=@includedir@/' \
      -e 's/^Cflags: -I${includedir}/Cflags:/' \
      -i libffi.pc.in
  ./configure --prefix=/usr --disable-static --with-gcc-arch=native
  make $JOPT
  make check
  make install
}

ch6_50() {
  sed -i '/\} data/s/ =.*$/;\n    memset(\&data, 0, sizeof(data));/' \
    crypto/rand/rand_lib.c
  ./config --prefix=/usr         \
           --openssldir=/etc/ssl \
           --libdir=lib          \
           shared                \
           zlib-dynamic
  make $JOPT
  make test
  sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
  make MANSUFFIX=ssl install
  mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.1c
  cp -vfr doc/* /usr/share/doc/openssl-1.1.1c
}

ch6_51() {
  ./configure --prefix=/usr       \
              --enable-shared     \
              --with-system-expat \
              --with-system-ffi   \
              --with-ensurepip=yes
  make $JOPT
  make install
  chmod -v 755 /usr/lib/libpython3.7m.so
  chmod -v 755 /usr/lib/libpython3.so
  ln -sfv pip3.7 /usr/bin/pip3
  install -v -dm755 /usr/share/doc/python-3.7.4/html 
  
  tar --strip-components=1  \
      --no-same-owner       \
      --no-same-permissions \
      -C /usr/share/doc/python-3.7.4/html \
      -xvf ../python-3.7.4-docs-html.tar.bz2
}

ch6_52() {
  python3 configure.py --bootstrap
  
  
  ./ninja ninja_test
  ./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
  
  install -vm755 ninja /usr/bin/
  install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
  install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
}

ch6_53() {
  python3 setup.py build
  python3 setup.py install --root=dest
  cp -rv dest/* /
}

ch6_54() {
  patch -Np1 -i ../coreutils-8.31-i18n-1.patch
  sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
  autoreconf -fiv
  FORCE_UNSAFE_CONFIGURE=1 ./configure \
              --prefix=/usr            \
              --enable-no-install-program=kill,uptime
  make $JOPT
  make NON_ROOT_USERNAME=nobody check-root
  echo "dummy:x:1000:nobody" >> /etc/group
  chown -Rv nobody . 
  su nobody -s /bin/bash \
            -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
  sed -i '/dummy/d' /etc/group
  make install
  mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
  mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
  mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
  mv -v /usr/bin/chroot /usr/sbin
  mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
  sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
  
  mv -v /usr/bin/{head,nice,sleep,touch} /bin
}

ch6_55() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make docdir=/usr/share/doc/check-0.12.0 install
  sed -i '1 s/tools/usr/' /usr/bin/checkmk
}

ch6_56() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch6_57() {
  sed -i 's/extras//' Makefile.in
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
  mkdir -v /usr/share/doc/gawk-5.0.1
  cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.0.1
}

ch6_58() {
  sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in
  sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
  sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
  echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
  ./configure --prefix=/usr --localstatedir=/var/lib/locate
  make $JOPT
  make check
  make install
  mv -v /usr/bin/find /bin
  sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
}

ch6_59() {
  PAGE=letter ./configure --prefix=/usr
  make -j1
  make install
}

ch6_60() {
  ./configure --prefix=/usr          \
              --sbindir=/sbin        \
              --sysconfdir=/etc      \
              --disable-efiemu       \
              --disable-werror
  make $JOPT
  make install
  mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
}

ch6_61() {
  ./configure --prefix=/usr --sysconfdir=/etc
  make $JOPT
  make install
}

ch6_62() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
  mv -v /usr/bin/gzip /bin
}

ch6_63() {
  sed -i /ARPD/d Makefile
  rm -fv man/man8/arpd.8
  sed -i 's/.m_ipt.o//' tc/Makefile
  make $JOPT
  make DOCDIR=/usr/share/doc/iproute2-5.2.0 install
}

ch6_64() {
  patch -Np1 -i ../kbd-2.2.0-backspace-1.patch
  sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
  sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
  PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
  make $JOPT
  make check
  make install
  mkdir -v       /usr/share/doc/kbd-2.2.0
  cp -R -v docs/doc/* /usr/share/doc/kbd-2.2.0
}

ch6_65() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch6_66() {
  sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
  ./configure --prefix=/usr
  make $JOPT
  make PERL5LIB=$PWD/tests/ check
  make install
}

ch6_67() {
  ./configure --prefix=/usr
  make $JOPT
  make check
  make install
}

ch6_68() {
  ./configure --prefix=/usr                        \
              --docdir=/usr/share/doc/man-db-2.8.6.1 \
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

ch6_69() {
  FORCE_UNSAFE_CONFIGURE=1  \
  ./configure --prefix=/usr \
              --bindir=/bin
  make $JOPT
  make check
  make install
  make -C doc install-html docdir=/usr/share/doc/tar-1.32
}

ch6_70() {
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

ch6_71() {
  echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
  ./configure --prefix=/usr
  make $JOPT
  chown -Rv nobody .
  su nobody -s /bin/bash -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log
  make install
  ln -sv vim /usr/bin/vi
  for L in  /usr/share/man/{,*/}man1/vim.1; do
      ln -sv vim.1 $(dirname $L)/vi.1
  done
  ln -sv ../vim/vim81/doc /usr/share/doc/vim-8.1.1846
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

ch6_72() {
  ./configure --prefix=/usr                            \
              --exec-prefix=                           \
              --libdir=/usr/lib                        \
              --docdir=/usr/share/doc/procps-ng-3.3.15 \
              --disable-static                         \
              --disable-kill
  make $JOPT
  sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
  sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
  rm testsuite/pgrep.test/pgrep.exp
  make check
  make install
  mv -v /usr/lib/libprocps.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
}

ch6_73() {
  mkdir -pv /var/lib/hwclock
  ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
              --docdir=/usr/share/doc/util-linux-2.34 \
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
  
  
  chown -Rv nobody .
  su nobody -s /bin/bash -c "PATH=$PATH make -k check"
  
  make install
}

ch6_74() {
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
  make install-libs
  chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
  gunzip -v /usr/share/info/libext2fs.info.gz
  install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
  makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
  install -v -m644 doc/com_err.info /usr/share/info
  install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
  cd ..
}

ch6_75() {
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

ch6_76() {
  patch -Np1 -i ../sysvinit-2.95-consolidated-1.patch
  make $JOPT
  make install
}

ch6_77() {
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

ch6_79_1() {
save_lib="ld-2.30.so libc-2.30.so libpthread-2.30.so libthread_db-1.0.so"

cd /lib

for LIB in $save_lib; do
    objcopy --only-keep-debug $LIB $LIB.dbg 
    strip --strip-unneeded $LIB
    objcopy --add-gnu-debuglink=$LIB.dbg $LIB 
done    

save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.27
             libitm.so.1.0.0 libatomic.so.1.2.0" 

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug $LIB $LIB.dbg
    strip --strip-unneeded $LIB
    objcopy --add-gnu-debuglink=$LIB.dbg $LIB
done

unset LIB save_lib save_usrlib
}

ch6_79_2() {
/tools/bin/find /usr/lib -type f -name \*.a \
   -exec /tools/bin/strip --strip-debug {} ';'

/tools/bin/find /lib /usr/lib -type f \( -name \*.so* -a ! -name \*dbg \) \
   -exec /tools/bin/strip --strip-unneeded {} ';'

/tools/bin/find /{bin,sbin} /usr/{bin,sbin,libexec} -type f \
    -exec /tools/bin/strip --strip-all {} ';'
}

ch6_80_1() {
  rm -rf /tmp/*
}

ch6_80_2() {
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
cat > /etc/fstab << EOF
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

${LFSPART}       /            ext4    defaults            1     1
${SWAPPART}     swap         swap     pri=1               0     0
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
grub-install /dev/"${DSK}"

cat > /boot/grub/grub.cfg << EOF
set default=0
set timeout=5

insmod ext2
set root=(hd0,2)

menuentry "GNU/Linux, Linux 5.2.8-lfs-9.0" {
	linux /boot/vmlinuz-5.2.8-lfs-9.0 root=/dev/${DSK}${DSK2} ro
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

dhcpcd() {
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

wget() {
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl &&
make
make install
}

openssh() {
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

ch9_3() {
  cd /sources
case "$1" in
  1)
    # Install dhcpcd as described in Ch. 14 of BLFS
    bs dhcpcd dhcpcd-8.0.3 .tar.xz
    ;;
  2)
    # Install wget as described in Ch 15. of BLFS
    bs wget wget-1.20.3 .tar.gz
    ;;
  3)
  # Install openssh as described in Ch 15. of BLFS
  bs openssh openssh-8.0p1 .tar.gz
  ;;
  *) 
    for i in {1..3}
    do
      #bash $LFS/sources/lfs/src/lfs3.sh $i
      stage3 $i
    done
    ;;
esac
  #logout
}

# compile source
cs() { # package, extension, chapternum
  PK=$1; EXT=$2; NUM=$3;
  tar -xf $LFS/sources/$PK$EXT
  cd $PK
  ch5_$NUM >$LP/5.$NUM.log 2>$LP/5.$NUM.err
  cd ..
  rm -rf $PK
}

# compile source
bs() { # package, extension, chapternum
  PK=$2; EXT=$3; NUM=$1;
  tar -xf /sources/$PK$EXT
  cd $PK
  $NUM >$LP/$NUM.log 2>$LP/$NUM.err
  cd ..
  rm -rf $PK
}

stage0() {
  if [ $SYS = "ubuntu" ]; then
    sudo sed -i '/ focal /s/$/ universe multiverse/' /etc/apt/sources.list
  fi
  # This script seeks to set up a system for lfs
  wget http://jcantrell.me/jordan/files/setup/jopm/jopm.sh
  # Run basic workstation setup
  sh jopm.sh usecase minimumcore
  sh jopm.sh install valgrind
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
  ch4_3_1
  ch4_3_2
}

stage2() {
  ch4_4
}

stage3() {
cd $LFS/sources
case "$1" in
  4) { time cs binutils-2.32 .tar.xz 4; } 2> $LP/sbu ;;
  5) cs gcc-9.2.0       .tar.xz 5 ;;
  6) cs linux-5.2.8     .tar.xz 6 ;;
  7) cs glibc-2.30      .tar.xz 7 ;;
  8) cs gcc-9.2.0       .tar.xz 8 ;;
  9) cs binutils-2.32   .tar.xz 9 ;;
  10) cs gcc-9.2.0       .tar.xz 10 ;;
  11) cs tcl8.6.9    -src.tar.gz 11 ;;
  12) cs expect5.45.4    .tar.gz 12 ;;
  13) cs dejagnu-1.6.2   .tar.gz 13 ;;
  14) cs m4-1.4.18       .tar.xz 14 ;;
  15) cs ncurses-6.1     .tar.gz 15 ;;
  16) cs bash-5.0        .tar.gz 16 ;;
  17) cs bison-3.4.1     .tar.xz 17 ;;
  18) cs bzip2-1.0.8     .tar.gz 18 ;;
  19) cs coreutils-8.31  .tar.xz 19 ;;
  20) cs diffutils-3.7   .tar.xz 20 ;;
  21) cs file-5.37       .tar.gz 21 ;;
  22) cs findutils-4.6.0 .tar.gz 22 ;;
  23) cs gawk-5.0.1      .tar.xz 23 ;;
  24) cs gettext-0.20.1  .tar.xz 24 ;;
  25) cs grep-3.3        .tar.xz 25 ;;
  26) cs gzip-1.10       .tar.xz 26 ;;
  27) cs make-4.2.1      .tar.gz 27 ;;
  28) cs patch-2.7.6     .tar.xz 28 ;;
  29) cs perl-5.30.0     .tar.xz 29 ;;
  30) cs Python-3.7.4    .tar.xz 30 ;;
  31) cs sed-4.7         .tar.xz 31 ;;
  32) cs tar-1.32        .tar.xz 32 ;;
  33) cs texinfo-6.6     .tar.xz 33 ;;
  34) cs xz-5.2.4        .tar.xz 34 ;;
  35) ch5_35 >$LP/5.35.log 2>$LP/5.35.err ;;
  *) 
    for i in {4..36}
    do
      #bash $LFS/sources/lfs/src/lfs3.sh $i
      stage3 $i
    done
    ;;
esac
}

stage4() {
  ch5_36
  ch6_2
}

stage5() {
  ch6_4
}

stage6() {
  ch6_5
  ch6_6_1
}

stage7_1() {
set +e
cd /sources
ch6_6_2
bs ch6_7 linux-5.2.8    .tar.xz
bs ch6_8 man-pages-5.02 .tar.xz
bs ch6_9 glibc-2.30     .tar.xz
ch6_10
bs ch6_11 zlib-1.2.11   .tar.xz
bs ch6_12 file-5.37     .tar.gz
bs ch6_13 readline-8.0  .tar.gz
bs ch6_14 m4-1.4.18     .tar.xz
bs ch6_15 bc-2.1.3      .tar.gz
bs ch6_16 binutils-2.32 .tar.xz
bs ch6_17 gmp-6.1.2     .tar.xz
bs ch6_18 mpfr-4.0.2    .tar.xz
bs ch6_19 mpc-1.1.0     .tar.gz
bs ch6_20 shadow-4.7    .tar.xz
bash /sources/lfs/src/lfs.sh stage7_2
}

stage7_2() {
set +e
cd /sources
bs ch6_21 gcc-9.2.0     .tar.xz
bs ch6_22 bzip2-1.0.8   .tar.gz
bs ch6_23 pkg-config-0.29.2 .tar.gz
bs ch6_24 ncurses-6.1   .tar.gz
bs ch6_25 attr-2.4.48   .tar.gz
bs ch6_26 acl-2.2.53    .tar.gz
bs ch6_27 libcap-2.27   .tar.xz
bs ch6_28 sed-4.7       .tar.xz
bs ch6_29 psmisc-23.2   .tar.xz
bs ch6_30 iana-etc-2.30 .tar.bz2
bs ch6_31 bison-3.4.1   .tar.xz
bs ch6_32 flex-2.6.4    .tar.gz
bs ch6_33 grep-3.3      .tar.xz
bs ch6_34 bash-5.0      .tar.gz
}

stage8() {
  set +e
  cd /sources
  case "$1" in
    35) bs ch6_35 libtool-2.4.6   .tar.xz ;;
    36) bs ch6_36 gdbm-1.18.1     .tar.gz ;;
    37) bs ch6_37 gperf-3.1       .tar.gz ;;
    38) bs ch6_38 expat-2.2.7     .tar.xz ;;
    39) bs ch6_39 inetutils-1.9.4 .tar.xz ;;
    40) bs ch6_40 perl-5.30.0     .tar.xz ;;
    41) bs ch6_41 XML-Parser-2.44 .tar.gz ;;
    42) bs ch6_42 intltool-0.51.0 .tar.gz ;;
    43) bs ch6_43 autoconf-2.69   .tar.xz ;;
    44) bs ch6_44 automake-1.16.1 .tar.xz ;;
    45) bs ch6_45 xz-5.2.4        .tar.xz ;;
    46) bs ch6_46 kmod-26         .tar.xz ;;
    47) bs ch6_47 gettext-0.20.1  .tar.xz ;;
    48) bs ch6_48 elfutils-0.177  .tar.bz2 ;;
    49) bs ch6_49 libffi-3.2.1    .tar.gz ;;
    50) bs ch6_50 openssl-1.1.1c  .tar.gz ;;
    51) bs ch6_51 Python-3.7.4    .tar.xz ;;
    52) bs ch6_52 ninja-1.9.0     .tar.gz ;;
    53) bs ch6_53 meson-0.51.1    .tar.gz ;;
    54) bs ch6_54 coreutils-8.31  .tar.xz ;;
    55) bs ch6_55 check-0.12.0    .tar.gz ;;
    56) bs ch6_56 diffutils-3.7   .tar.xz ;;
    57) bs ch6_57 gawk-5.0.1      .tar.xz ;;
    58) bs ch6_58 findutils-4.6.0 .tar.gz ;;
    59) bs ch6_59 groff-1.22.4    .tar.gz ;;
    60) bs ch6_60 grub-2.04       .tar.xz ;;
    61) bs ch6_61 less-551        .tar.gz ;;
    62) bs ch6_62 gzip-1.10       .tar.xz ;;
    63) bs ch6_63 iproute2-5.2.0  .tar.xz ;;
    64) bs ch6_64 kbd-2.2.0       .tar.xz ;;
    65) bs ch6_65 libpipeline-1.5.1 .tar.gz ;;
    66) bs ch6_66 make-4.2.1      .tar.gz ;;
    67) bs ch6_67 patch-2.7.6     .tar.xz ;;
    68) bs ch6_68 man-db-2.8.6.1  .tar.xz ;;
    69) bs ch6_69 tar-1.32        .tar.xz ;;
    70) bs ch6_70 texinfo-6.6     .tar.xz ;;
    71) bs ch6_71 vim-8.1.1846    .tar.gz ;;
    72) bs ch6_72 procps-ng-3.3.15 .tar.xz ;;
    73) bs ch6_73 util-linux-2.34 .tar.xz ;;
    74) bs ch6_74 e2fsprogs-1.45.3 .tar.gz ;;
    75) bs ch6_75 sysklogd-1.5.1 .tar.gz ;;
    76) bs ch6_76 sysvinit-2.95  .tar.xz ;;
    77) bs ch6_77 eudev-3.2.8    .tar.gz ;;
    *) 
      for i in {35..77}
      do
        #bash $LFS/sources/lfs/src/lfs3.sh $i
        stage8 $i
      done
      ch6_79_1
      ;;
  esac
}

stage9() {
ch6_79_2
ch6_80_1
}

stage11() {
  ch6_80_2
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
}

stage12() {
  umount -v $LFS/dev/pts
  umount -v $LFS/dev
  umount -v $LFS/run
  umount -v $LFS/proc
  umount -v $LFS/sys
  umount -v $LFS
  shutdown -r now
}

clean() {
  swapoff /dev/${DSK}${DSK1}
  umount /dev/${DSK}${DSK2}
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$DSK
  d   # delete partition
      # default
  d   # delete partition
      # default
  w   #
EOF
  userdel -r lfs
  rm /tools
}

$1 $7
