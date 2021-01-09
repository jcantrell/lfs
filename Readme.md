This project attempts to automate the Linux From Scratch project.
Currently follows version 9.0 of LFS.

Step 0: Prepare host system and temporary tools  
Approximate time on dual-core Ubuntu server vm in libvirt: 62 minutes  
Approximate time on quad-core Ubuntu desktop vm in virtualbo, 23GB: 50 minutes  
Approximate time on quad-core Ubuntu chroot: 41 minutes  
`$ wget http://jcantrell.me:8002/jcantrell/lfs/raw/$BRANCH/src/lfs.sh`  
`$ export LFS=/mnt/lfs
`$ sh lfs.sh stage0 ubuntu sda 1 2`   
`$ bash $LFS/sources/lfs/src/lfs.sh stage2`
`$ time bash $LFS/sources/lfs/src/lfs.sh stage3`
Sometimes perl fails, especially on qemu on hudson. Specify one job at a time:
`$ time bash $LFS/sources/lfs/src/lfs.sh stage3 ubuntu sda 1 2 1`

Step 4: Prepare nodes as root  
`$ exit`  
`$ exit`  
`# export LFS=/mnt/lfs`  
`# bash $LFS/sources/lfs/src/lfs.sh stage4`  

Step 5: Change to chroot environment (source the script so it will see
  environment variables)  
`# . $LFS/sources/lfs/src/lfs.sh stage5`  

Step 6: Run new bash  
`# bash /sources/lfs/src/lfs.sh stage6`  

Step 7: Begin building sources  
Approximate time on single-core Ubuntu desktop vm in virtualbox: 237 minutes  
`# date` Run date just to give you an idea of when you started, and when it should be done  
Approximate time on quad-core Ubuntu desktop vm in virtualbox, 23GB: 68 minutes  
Approximate time on quad-core Ubuntu chroot: 70m
Approximate time on 16-core Ubuntu chroot: 44m
`# time bash /sources/lfs/src/lfs.sh stage7_1`  
`# exec /bin/bash --login +h`

Step 8: Build the rest of the packages with the bash we just built  
Approximate time on quad-core Ubuntu chroot: 110 minutes  
Approximate time on quad-core Ubuntu virtualbox vm: 80 minutes  
`# time bash /sources/lfs/src/lfs.sh stage8`  

Step 9: Strip binaries of debugging info  
`# exec /tools/bin/bash`  
`# bash /sources/lfs/src/lfs.sh stage9`  

Step 10: Leave and re-enter chroot environment  
`# exit`  
`# exit`  
```
chroot "$LFS" /usr/bin/env -i          \
    HOME=/root TERM="$TERM"            \
    PS1='(lfs chroot) \u:\w\$ '        \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login
```

Step 11: Strip debug info, perform further setup  
`# bash /sources/lfs/src/lfs.sh stage11 ubuntu sda 1 2`  

Step 12: Outside of the chroot environment, unmount virtual files  
`# exit`  
`# bash lfs.sh stage12`  
