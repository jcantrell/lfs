mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
#wget --input-file=wget-list-local --continue --directory-prefix=$LFS/sources
mv $LFS/lfs-build/tarballs/* $LFS/sources
pushd $LFS/sources
#wget wally/jordan/LFS7.7/md5sums
cp ../lfs-build/md5sums .
md5sum -c md5sums
popd
