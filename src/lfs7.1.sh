set -x
set -o functrace

LP="/sources/lfs/logs"
mkdir -p $LP
JOPT="-j `nproc`"

# This file follows lfs chapter 6, section 6 through 34 when
# the environment is changed to use the newly-compiled bash shell

ch6_6() {
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

cd /sources
ch6_6
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