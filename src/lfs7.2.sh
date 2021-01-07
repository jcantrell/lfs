set -x
set -o functrace

LP="/sources/lfs/logs"
mkdir -p $LP
JOPT="-j `nproc`"

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
