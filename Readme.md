This project attempts to automate the Linux From Scratch project.
Currently follows version 9.0 of LFS.

Step 0: Prepare host system
On tinycore linux:
`wget http://jcantrell.me/jordan/files/preparesystem.sh`
`time sh preparesystem.sh`

Step 1: Prepare the disk
`$ cd lfs/src`
`$ sudo su`
`# bash lfs1.sh`

Step 2: Prepare lfs user environment
`$ git clone http://jcantrell.me:3000/jcantrell/lfs.git $LFS/sources/lfs`
`$ bash $LFS/sources/lfs/src/lfs2.sh`

Step 3: Build temporary tools
`$ time bash $LFS/sources/lfs/src/lfs3.sh`

Step 4: Change owner of tools to root, to avoid UID conflicts
`# mv lfs $LFS/sources/`
`# mv lfs-build $LFS/sources/`
`# exit`
`# chown -R root:root $LFS/tools` # Doesn't this happen at the end of lfs3?

Step 5: Prepare nodes
`# bash $LFS/sources/lfs/src/lfs4.sh`

Step 6: Change to chroot environment (source the script so it will see
  environment variables)
`# . $LFS/sources/lfs/src/lfs5.sh`

Step 8: Run new bash
`# bash /sources/lfs/src/lfs6.sh`

Step 9: Begin building sources
`# bash /sources/lfs/src/lfs7.sh`
