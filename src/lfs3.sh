# Chapter 5 - Constructing a Temporary System
set -xe

LB=~/lfs-build
fi=$LB/scripts/5
lp=$LB/logs
LP=$LB/logs
mkdir -p $LP
TESTS=""
JOPT="-j `nproc`"
#HACK
PATH=/tools/bin:/usr/local/bin:/bin:/usr/bin

ch5_4() {
  echo -n "5.4.sh : " >> $LP/log5
  mkdir -v ../binutils-build
  cd ../binutils-build

  ../"$1"/configure --prefix=/tools            \
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
  echo $? >> $LP/log5
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
      --disable-libstdc++                              \
      --enable-languages=c,c++
  
  make $JOPT
  
  make install
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
  echo $? >> $LP/log5
   # Now test to make sure we compile correctly
  echo 'int main(){}' > dummy.c
  $LFS_TGT-gcc dummy.c
  readelf -l a.out | grep ': /tools' >> $LP/log5
  rm -v dummy.c a.out
}

ch5_8() {
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
  readelf -l a.out | grep ': /tools' >> $LFS/logs/log5
  rm -v dummy.c a.out
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
  [ ! -z $TESTS ] && make check
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
  make
  [ ! -z $TESTS ] && make check
  make install
}

ch5_18() {
  make $JOPT
  make PREFIX=/tools install
}

ch5_19() {
  ./configure --prefix=/tools --enable-install-program=hostname
  make
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
  make
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

#buildit
bi() {
  tar -xf $LFS/sources/$1$2
  cd $1
  $3 $1
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

{ time 
bi binutils-2.32	.tar.xz	ch5_4	binutils-build >$lp/5.4.log 2>$lp/5.4.err ;
} 2> $lp/sbu
bi gcc-9.2.0		.tar.bz2	ch5_5	gcc-build	>$lp/5.5.log	2>$lp/5.5.err
bi linux-5.2.8		.tar.xz		ch5_6 >$lp/5.6.log	2>$lp/5.6.err
bi glibc-2.30		.tar.xz		ch5_7	glibc-build	>$lp/5.7.log	2>$lp/5.7.err
bi gcc-9.2.0		.tar.bz2	ch5_8	gcc-build	>$lp/5.8.log	2>$lp/5.8.err
bi binutils-2.32	.tar.bz2	ch5_9	binutils-build	>$lp/5.9.log	2>$lp/5.9.err
bi gcc-9.2.0		.tar.bz2	ch5_10	gcc-build	>$lp/5.10.log	2>$lp/5.10.err
bi tcl8.6.9		-src.tar.gz	ch5_11			>$lp/5.11.log	2>$lp/5.11.err
bi expect5.45.4		.tar.gz		ch5_12			>$lp/5.12.log	2>$lp/5.12.err
bi dejagnu-1.6.2	.tar.gz		ch5_13			>$lp/5.13.log	2>$lp/5.13.err
bi m4-1.4.18	.tar.xz		ch5_14			>$lp/5.14.log	2>$lp/5.14.err
bi ncurses-6.1     .tar.gz ch5_15 >$lp/5.15.log 2>$lp/5.15.err
bi bash-5.0        .tar.gz ch5_16 >$lp/5.16.log 2>$lp/5.16.err
bi bison-3.4.1     .tar.xz ch5_17 >$LP/5.17.log 2>$LP/5.17.err
bi bzip2-1.0.8     .tar.gz ch5_18 >$lp/5.18.log 2>$lp/5.18.err
bi coreutils-8.31  .tar.xz ch5_19 >$lp/5.19.log 2>$lp/5.19.err
bi diffutils-3.7   .tar.xz ch5_20 >$lp/5.20.log 2>$lp/5.20.err
bi file-5.37       .tar.gz ch5_21 >$lp/5.21.log 2>$lp/5.21.err
bi findutils-4.6.0 .tar.gz ch5_22 >$lp/5.22.log 2>$lp/5.22.err
bi gawk-5.0.1      .tar.xz ch5_23 >$lp/5.23.log 2>$lp/5.23.err
bi gettext-0.20.1  .tar.xz ch5_24 >$lp/5.24.log 2>$lp/5.24.err
bi grep-3.3        .tar.xz ch5_25 >$lp/5.25.log 2>$lp/5.25.err
bi gzip-1.10       .tar.xz ch5_26 >$lp/5.26.log 2>$lp/5.26.err
bi make-4.2.1      .tar.gz ch5_27 >$lp/5.27.log 2>$lp/5.27.err
bi patch-2.7.6     .tar.xz ch5_28 >$lp/5.28.log 2>$lp/5.28.err
bi perl-5.30.0     .tar.xz ch5_29 >$lp/5.29.log 2>$lp/5.29.err
bi Python-3.7.4    .tar.xz ch5_30 >$LP/5.30.log 2>$LP/5.30.err
bi sed-4.7         .tar.xz ch5_31 >$lp/5.31.log 2>$lp/5.31.err
bi tar-1.32        .tar.xz ch5_32 >$lp/5.32.log 2>$lp/5.32.err
bi texinfo-6.6     .tar.xz ch5_33 >$lp/5.33.log 2>$lp/5.33.err
bi xz-5.2.4        .tar.xz ch5_34 >$lp/5.34.log 2>$lp/5.34.err
ch5_35                            >$lp/5_35.log 2>$lp/5.35.err
