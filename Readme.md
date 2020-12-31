This project attempts to automate the Linux From Scratch project.
Currently follows version 9.0 of LFS.

Step 0: Prepare host system  
Approximate time on dual-core Ubuntu vm: 10 seconds
On tinycore linux:  
`$ wget http://jcantrell.me:3000/jcantrell/lfs/raw/master/src/lfs0.sh`  
Edit the `SYS` variable for your system  
`$ sh lfs0.sh`   

Step 1: Prepare the disk  
Edit the `DSK` variable to point to the appropriate drive  
`$ sudo bash lfs1.sh`  

Step 2: Prepare lfs user environment  
`$ bash $LFS/sources/lfs/src/lfs2.sh`  

Step 3: Build temporary tools  
Approximate time on dual-core Ubuntu server vm in libvirt: 62 minutes  
`$ time bash $LFS/sources/lfs/src/lfs3.sh`  

Step 4: Prepare nodes as root  
`$ exit`  
`$ exit`  
`# export LFS=/mnt/lfs`  
`# bash $LFS/sources/lfs/src/lfs4.sh`  

Step 5: Change to chroot environment (source the script so it will see
  environment variables)  
`# . $LFS/sources/lfs/src/lfs5.sh`  

Step 6: Run new bash  
`# bash /sources/lfs/src/lfs6.sh`  

Step 7: Begin building sources  
Approximate time on single-core Ubuntu desktop vm in virtualbox: 237 minutes  
`# time bash /sources/lfs/src/lfs7.sh`  
`# exec /bin/bash --login +h`

Step 8: Build the rest of the packages with the bash we just built  
Approximate time on single-core Ubuntu desktop vm in virtualbox:  minutes  
`# time bash /sources/lfs/src/lfs8.sh`  

Step 9: Strip binaries of debugging info
`# exec /tools/bin/bash`
`# bash /sources/lfs/src/lfs.sh`

Step 10: Leave and re-enter chroot environment  
`# logout`  
```
chroot "$LFS" /usr/bin/env -i          \
    HOME=/root TERM="$TERM"            \
    PS1='(lfs chroot) \u:\w\$ '        \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login
```

Step 11: Strip debug info, perform further setup  
`# bash /sources/lfs/src/lfs11.sh`  

Step 12: Outside of the chroot environment, unmount virtual files  
`# bash lfs12.sh`  
