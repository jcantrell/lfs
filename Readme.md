This project attempts to automate the Linux From Scratch project.
Currently follows version 9.0 of LFS.

Step 1: Prepare the disk
`# sudo bash lfs1.sh`
Step 2: Prepare lfs user environment
`$ git clone pi@10.0.0.133:/srv/git/lfs
`$ bash lfs/src/lfs2.sh`
Step 3: Build temporary tools
`$ time bash lfs/src/lfs3.sh`
Step 4: Change owner of tools to root, to avoid UID conflicts
`export LFS=/mnt/lfs` # WHERE TO PUT THIS?
`git clone pi@10.0.0.133:/srv/git/lfs $LFS/sources/lfs`
`# chown -R root:root $LFS/tools`
Step 5: Prepare nodes
`# bash lfs/src/lfs4.sh`
Step 6: Change to chroot environment (source the script so it will see
  environment variables)
`# . lfs/src/lfs5.sh`
#Step 7: Obtain lfs scripts within chroot environment
#`wget 10.0.0.133/lfs/9.0/src/lfs6.sh`
Step 8: Run new bash
`$ bash lfs/src/lfs6.sh`
Step 9: Begin building sources
`$ bash lfs/src/lfs7.sh`
