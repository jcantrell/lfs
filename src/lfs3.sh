# Chapter 5 - Constructing a Temporary System
set -xe

LP=~/lfs-build/logs
mkdir -p $LP
TESTS=""
JOPT="-j `nproc`"
#JOPT=""

#HACK
#PATH=/tools/bin:/usr/local/bin:/bin:/usr/bin

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
  echo $? >> $LP/log5
   # Now test to make sure we compile correctly
  echo 'int main(){}' > dummy.c
  $LFS_TGT-gcc dummy.c
  readelf -l a.out | grep ': /tools' >> $LP/log5
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
  readelf -l a.out | grep ': /tools' >> $LP/log5
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
  su - root -c "chown -R root:root $LFS/tools"
}

#buildit
# package,version,extension,chapter/section number
bi() {
  tar -xf $LFS/sources/$1$2
  cd $1
  $3
  cd ..
  rm -rf $1 #$4
}

# compile source
cs() { # package, extension, chapternum
  PK=$1; EXT=$2; NUM=$3;
  tar -xf $LFS/sources/$PK$EXT
  cd $PK
  ch5_$NUM >$LP/5.$NUM.log 2>$LP/5.$NUM.err
  cd ..
  rm -rf $PK
  #bi $PK $EXT ch5_$NUM >$LP/5.$NUM.log 2>$LP/5.$NUM.err
}

cd $LFS/sources

{ time cs binutils-2.32 .tar.xz 4; } 2> $LP/sbu
cs gcc-9.2.0       .tar.xz 5
cs linux-5.2.8     .tar.xz 6
cs glibc-2.30      .tar.xz 7
cs gcc-9.2.0       .tar.xz 8
cs binutils-2.32   .tar.xz 9
cs gcc-9.2.0       .tar.xz 10
cs tcl8.6.9    -src.tar.gz 11
cs expect5.45.4    .tar.gz 12
cs dejagnu-1.6.2   .tar.gz 13
cs m4-1.4.18       .tar.xz 14 
cs ncurses-6.1     .tar.gz 15
cs bash-5.0        .tar.gz 16
cs bison-3.4.1     .tar.xz 17 
cs bzip2-1.0.8     .tar.gz 18
cs coreutils-8.31  .tar.xz 19 
cs diffutils-3.7   .tar.xz 20
cs file-5.37       .tar.gz 21
cs findutils-4.6.0 .tar.gz 22 
cs gawk-5.0.1      .tar.xz 23
cs gettext-0.20.1  .tar.xz 24
cs grep-3.3        .tar.xz 25
cs gzip-1.10       .tar.xz 26
cs make-4.2.1      .tar.gz 27
cs patch-2.7.6     .tar.xz 28
cs perl-5.30.0     .tar.xz 29
cs Python-3.7.4    .tar.xz 30
cs sed-4.7         .tar.xz 31
cs tar-1.32        .tar.xz 32
cs texinfo-6.6     .tar.xz 33
cs xz-5.2.4        .tar.xz 34
ch5_35 >$LP/5_35.log 2>$LP/5.35.err
ch5_36 # where to put this?
