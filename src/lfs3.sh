# Chapter 5 - Constructing a Temporary System
set -xe

LB=~/lfs-build
fi=$LB/scripts/5
lp=$LB/logs
LP=$LB/logs
mkdir -p $LP
#HACK
PATH=/tools/bin:/usr/local/bin:/bin:/usr/bin

ch5_4() {
  echo -n "5.4.sh : " >> $LP/log5
  mkdir -v ../binutils-build
  cd ../binutils-build

  ../binutils-2.25/configure     \
    --prefix=/tools            \
    --with-sysroot=$LFS        \
    --with-lib-path=/tools/lib \
    --target=$LFS_TGT          \
    --disable-nls              \
    --disable-werror

  make

  case $(uname -m) in
    x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
  esac

  make install
  echo $? >> $LP/log5
}

ch5_5() {
  echo -n "5.5.sh : " >> $LP/log5
  tar -xf ../mpfr-3.1.2.tar.xz
  mv -v mpfr-3.1.2 mpfr
  tar -xf ../gmp-6.0.0a.tar.xz
  mv -v gmp-6.0.0 gmp
  tar -xf ../mpc-1.0.2.tar.gz
  mv -v mpc-1.0.2 mpc
  
  for file in \
   $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
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
  
  sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure
  
  mkdir -v ../gcc-build
  cd ../gcc-build
  
  ../gcc-4.9.2/configure                               \
      --target=$LFS_TGT                                \
      --prefix=/tools                                  \
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
      --disable-libitm                                 \
      --disable-libquadmath                            \
      --disable-libsanitizer                           \
      --disable-libssp                                 \
      --disable-libvtv                                 \
      --disable-libcilkrts                             \
      --disable-libstdc++-v3                           \
      --enable-languages=c,c++
  
  make
  
  make install
  
  echo $? >> $LP/log5
}

ch5_6() {
  echo -n "5.6.sh : " >> $LP/log5
  make mrproper
  make INSTALL_HDR_PATH=dest headers_install
  echo $? >> $LFS/lfs-build/logs/log5
  cp -rv dest/include/* /tools/include
}

ch5_7() {
  echo -n "5.7.sh : " >> $LP/log5
  if [ ! -r /usr/include/rpc/types.h ]; then
    su -c 'mkdir -pv /usr/include/rpc'
    su -c 'cp -v sunrpc/rpc/*.h /usr/include/rpc'
  fi
  sed -e '/ia32/s/^/1:/' \
      -e '/SSE2/s/^1://' \
      -i  sysdeps/i386/i686/multiarch/mempcpy_chk.S
  mkdir -v ../glibc-build
  cd ../glibc-build
  ../glibc-2.21/configure                             \
        --prefix=/tools                               \
        --host=$LFS_TGT                               \
        --build=$(../glibc-2.21/scripts/config.guess) \
        --disable-profile                             \
        --enable-kernel=2.6.32                        \
        --with-headers=/tools/include                 \
        libc_cv_forced_unwind=yes                     \
        libc_cv_ctors_header=yes                      \
        libc_cv_c_cleanup=yes
  make
  make install
  echo $? >> $LP/log5
   # Now test to make sure we compile correctly
  echo 'main(){}' > dummy.c
  $LFS_TGT-gcc dummy.c
  readelf -l a.out | grep ': /tools' >> $LP/log5
  rm -v dummy.c a.out
  
  echo $? >> $LP/log5
}

ch5_8() {
  echo -n "5.8.sh : " >> $LP/log5
  mkdir -pv ../gcc-build
  cd ../gcc-build
  ../gcc-4.9.2/libstdc++-v3/configure \
      --host=$LFS_TGT                 \
      --prefix=/tools                 \
      --disable-multilib              \
      --disable-shared                \
      --disable-nls                   \
      --disable-libstdcxx-threads     \
      --disable-libstdcxx-pch         \
      --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/4.9.2
  make
  make install
  echo $? >> $LP/log5
}

ch5_9() {
  echo -n "5.9.sh : " >> $LP/log5
  mkdir -v ../binutils-build
  cd ../binutils-build
  
  CC=$LFS_TGT-gcc                \
  AR=$LFS_TGT-ar                 \
  RANLIB=$LFS_TGT-ranlib         \
  ../binutils-2.25/configure     \
      --prefix=/tools            \
      --disable-nls              \
      --disable-werror           \
      --with-lib-path=/tools/lib \
      --with-sysroot
  
  make
  make install
  make -C ld clean
  make -C ld LIB_PATH=/usr/lib:/lib
  echo $? >> $LP/log5
  cp -v ld/ld-new /tools/bin
}

ch5_10() {
  echo -n "5.10.sh : " >> $LP/log5
  cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h
  for file in \
   $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
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
  tar -xf ../mpfr-3.1.2.tar.xz
  mv -v mpfr-3.1.2 mpfr
  tar -xf ../gmp-6.0.0a.tar.xz
  mv -v gmp-6.0.0 gmp
  tar -xf ../mpc-1.0.2.tar.gz
  mv -v mpc-1.0.2 mpc
  
  mkdir -v ../gcc-build
  cd ../gcc-build
  
  CC=$LFS_TGT-gcc                                      \
  CXX=$LFS_TGT-g++                                     \
  AR=$LFS_TGT-ar                                       \
  RANLIB=$LFS_TGT-ranlib                               \
  ../gcc-4.9.2/configure                               \
      --prefix=/tools                                  \
      --with-local-prefix=/tools                       \
      --with-native-system-header-dir=/tools/include   \
      --enable-languages=c,c++                         \
      --disable-libstdcxx-pch                          \
      --disable-multilib                               \
      --disable-bootstrap                              \
      --disable-libgomp
  
  make
  make install
  echo $? >> $LP/log5
  ln -sv gcc /tools/bin/cc
  
  echo 'main(){}' > dummy.c
  cc dummy.c
  readelf -l a.out | grep ': /tools' >> $LFS/logs/log5
  rm -v dummy.c a.out
  echo $? >> $LP/log5
}

ch5_11() {
  echo -n "5.11.sh : " >> $LP/log5
  cd unix
  ./configure --prefix=/tools
  
  make
  
  TZ=UTC make test
  
  make install
  chmod -v u+w /tools/lib/libtcl8.6.so
  make install-private-headers
  echo $? >> $LFS/lfs-build/logs/log5
  ln -sv tclsh8.6 /tools/bin/tclsh
  echo $? 
}

ch5_12() {
  echo -n "5.12.sh : " >> $LP/log5
  cp -v configure{,.orig}
  sed 's:/usr/local/bin:/bin:' configure.orig > configure
  
  ./configure --prefix=/tools       \
              --with-tcl=/tools/lib \
              --with-tclinclude=/tools/include
  
  make
  
  make test
  
  make SCRIPTS="" install
  echo $? >> $LP/log5
}

ch5_13() {
  echo -n "5.13.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make install
  echo $? >> $LP/log5
  make check
}

ch5_14() {
  echo -n "5.14.sh : " >> $LP/log5
  PKG_CONFIG= ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_15() {
  echo -n "5.15.sh : " >> $LP/log5
  ./configure --prefix=/tools \
              --with-shared   \
              --without-debug \
              --without-ada   \
              --enable-widec  \
              --enable-overwrite
  
  make
  make install
  echo $? >> $LP/log5
}

ch5_16() {
  echo -n "5.16.sh : " >> $LP/log5
  ./configure --prefix=/tools --without-bash-malloc
  make
  make test
  make install
  echo $? >> $LP/log5
  ln -sv bash /tools/bin/sh
}

ch5_17() {
  echo -n "5.17.sh : " >> $LP/log5
  make
  make PREFIX=/tools install
  echo $? >> $LP/log5
}

ch5_18() {
  echo -n "5.18.sh : " >> $LP/log5
  ./configure --prefix=/tools --enable-install-program=hostname
  make
  make RUN_EXPENSIVE_TESTS=yes check
  make install
  echo $? >> $LP/log5
}

ch5_19() {
  echo -n "5.19.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_20() {
  echo -n "5.20.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_21() {
  echo -n "5.21.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_22() {
  echo -n "5.22.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_23() {
  echo -n "5.23.sh : " >> $LP/log5
  cd gettext-tools
  EMACS="no" ./configure --prefix=/tools --disable-shared
  make -C gnulib-lib
  make -C intl pluralx.c
  make -C src msgfmt
  make -C src msgmerge
  make -C src xgettext
  echo $? >> $LP/log5
  cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin
}

ch5_24() {
  echo -n "5.24.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_25() {
  echo -n "5.25.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_26() {
  echo -n "5.26.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_27() {
  echo -n "5.27.sh : " >> $LP/log5
  ./configure --prefix=/tools --without-guile
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_28() {
  echo -n "5.28.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_29() {
  echo -n "5.29.sh : " >> $LP/log5
  sh Configure -des -Dprefix=/tools -Dlibs=-lm
  
  make
  echo $? >> $LP/log5
  
  cp -v perl cpan/podlators/pod2man /tools/bin
  mkdir -pv /tools/lib/perl5/5.20.2
  cp -Rv lib/* /tools/lib/perl5/5.20.2
}

ch5_30() {
  echo -n "5.30.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_31() {
  echo -n "5.31.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_32() {
  echo -n "5.32.sh : " >> $LP/log5
  ./configure -prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_33() {
  echo -n "5.33.sh : " >> $LP/log5
  ./configure --prefix=/tools                \
              --without-python               \
              --disable-makeinstall-chown    \
              --without-systemdsystemunitdir \
              PKG_CONFIG=""
  
  make
  make install
  echo $? >> $LP/log5
}

ch5_34() {
  echo -n "5.34.sh : " >> $LP/log5
  ./configure --prefix=/tools
  make
  make check
  make install
  echo $? >> $LP/log5
}

ch5_35() {
  echo -n "5.35.sh : " >> $LP/log5
  strip --strip-debug /tools/lib/*
  /usr/bin/strip --strip-unneeded /tools/{,s}bin/*
  rm -rf /tools/{,share}/{info,man,doc}
  echo $? >> $LP/log5
}

ch5_36() {
  chown -R root:root $LFS/tools
}

#buildit
bi() {
  tar -xf $LFS/sources/$1$2
  cd $1
  $3
  cd ..
  rm -rf $1 $4
}

# compile source
cs() {
  echo "hello"
}

#bi=$LFS/lfs-build/scripts/buildit.sh
#fi=$LFS/tools/lfs-build/scripts/5
#lp=$LFS/tools/lfs-build/logs # logpath
cd $LFS/sources

{ time bi binutils-2.25	.tar.bz2	ch5_4	binutils-build >$lp/5.4.log 2>$lp/5.4.err ;  } 2> $lp/sbu
bi gcc-4.9.2		.tar.bz2	ch5_5	gcc-build	>$lp/5.5.log	2>$lp/5.5.err
bi linux-3.19		.tar.xz		ch5_6 >$lp/5.6.log	2>$lp/5.6.err
bi glibc-2.21		.tar.xz		ch5_7	glibc-build	>$lp/5.7.log	2>$lp/5.7.err
bi gcc-4.9.2		.tar.bz2	ch5_8	gcc-build	>$lp/5.8.log	2>$lp/5.8.err
bi binutils-2.25	.tar.bz2	ch5_9	binutils-build	>$lp/5.9.log	2>$lp/5.9.err
bi gcc-4.9.2		.tar.bz2	ch5_10	gcc-build	>$lp/5.10.log	2>$lp/5.10.err
bi tcl8.6.3		-src.tar.gz	ch5_11			>$lp/5.11.log	2>$lp/5.11.err
bi expect5.45		.tar.gz		ch5_12			>$lp/5.12.log	2>$lp/5.12.err
bi dejagnu-1.5.2	.tar.gz		ch5_13			>$lp/5.13.log	2>$lp/5.13.err
bi check-0.9.14	.tar.gz		ch5_14			>$lp/5.14.log	2>$lp/5.14.err
bi ncurses-5.9		.tar.gz		ch5_15			>$lp/5.15.log	2>$lp/5.15.err
bi bash-4.3.30		.tar.gz		ch5_16			>$lp/5.16.log	2>$lp/5.16.err
bi bzip2-1.0.6		.tar.gz		ch5_17			>$lp/5.17.log	2>$lp/5.17.err
bi coreutils-8.23	.tar.xz		ch5_18			>$lp/5.18.log	2>$lp/5.18.err
bi diffutils-3.3	.tar.xz		ch5_19			>$lp/5.19.log	2>$lp/5.19.err
bi file-5.22		.tar.gz		ch5_20			>$lp/5.20.log	2>$lp/5.20.err
bi findutils-4.4.2	.tar.gz		ch5_21			>$lp/5.21.log	2>$lp/5.21.err
bi gawk-4.1.1		.tar.xz		ch5_22			>$lp/5.22.log	2>$lp/5.22.err
bi gettext-0.19.4	.tar.xz		ch5_23			>$lp/5.23.log	2>$lp/5.23.err
bi grep-2.21		.tar.xz		ch5_24			>$lp/5.24.log	2>$lp/5.24.err
bi gzip-1.6		.tar.xz		ch5_25			>$lp/5.25.log	2>$lp/5.25.err
bi m4-1.4.17		.tar.xz		ch5_26			>$lp/5.26.log	2>$lp/5.26.err
bi make-4.1		.tar.bz2	ch5_27			>$lp/5.27.log	2>$lp/5.27.err
bi patch-2.7.4		.tar.xz		ch5_28			>$lp/5.28.log	2>$lp/5.28.err
bi perl-5.20.2		.tar.bz2	ch5_29			>$lp/5.29.log	2>$lp/5.29.err
bi sed-4.2.2		.tar.bz2	ch5_30			>$lp/5.30.log	2>$lp/5.30.err
bi tar-1.28		.tar.xz		ch5_31			>$lp/5.31.log	2>$lp/5.31.err
bi texinfo-5.2		.tar.xz		ch5_32			>$lp/5.32.log	2>$lp/5.32.err
bi util-linux-2.26	.tar.xz		ch5_33			>$lp/5.33.log	2>$lp/5.33.err
bi xz-5.2.0		.tar.xz		ch5_34			>$lp/5.34.log	2>$lp/5.34.err
ch5_35								>$lp/5_35.log	2>$lp/5.35.err
