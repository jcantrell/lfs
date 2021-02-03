This project attempts to automate the Linux From Scratch project.
Currently follows version 10.0 of LFS.

Usage:
`lfs.sh stage-or-chapter host drive swappartnum installpartnum threads`

Step 0: Prepare host system and temporary tools  
`(system root) # wget http://jcantrell.me:8002/jcantrell/lfs/raw/$BRANCH/src/lfs.sh`  
`(system root) # export LFS=/mnt/lfs
`(system root) # sh lfs.sh stage0 ubuntu sda 1 2`   
`(lfs user) $ bash $LFS/sources/lfs/src/lfs.sh stage2`
`(lfs user) $ time bash $LFS/sources/lfs/src/lfs.sh stage3 ubuntu sda 1 2 1`
`$ time bash $LFS/sources/lfs/src/lfs.sh stage4`  
`$ exit`
`$ exit`
`(system root) # bash $LFS/sources/lfs/src/lfs.sh stage5`  

Step 5: Change to chroot environment
`(system root) # bash $LFS/sources/lfs/src/lfs.sh stage5_2`  

Step 6: Run new bash  
`(chroot) # bash /sources/lfs/src/lfs.sh stage6`  
`(new bash chroot) # bash /sources/lfs/src/lfs.sh stage6_2`

Step 7: Begin building sources  
`(chroot) # time bash /sources/lfs/src/lfs.sh stage7`  

Step 7.2 (optional): Exit chroot to make a backup, then re-enter the chroot
exit chroot
`# exit`
`# exit`
`# time bash $LFS/sources/lfs/src/lfs.sh stage7_2`  
# Remount the kernel virtual filesystem
`# bash $LFS/sources/lfs/src/lfs.sh ch7_3`
# Re-enter the chroot environment
`# bash $LFS/sources/lfs/src/lfs.sh ch7_4`

Step 8: Build the rest of the packages with the bash we just built  
`(chroot) # time bash /sources/lfs/src/lfs.sh stage8`  # Build
`(chroot) # bash /sources/lfs/src/lfs.sh stage8_1`  # Run new bash
`(new bash) # time bash /sources/lfs/src/lfs.sh stage8_2`  # build in new bash
`(system root) # bash $LFS/sources/lfs/src/lfs.sh stage8_3`  # reenter chroot
with new bash
`(new bash) # bash /sources/lfs/src/lfs.sh stage8_4`  

Step 9: Strip binaries of debugging info  
`# time bash /sources/lfs/src/lfs.sh stage9 ubuntu sdb`  

Step 10: Outside of the chroot environment, unmount virtual files  
`(system root) # bash lfs.sh stage10`  

# Timing Data
Stage 3:  65m44.110s
Stage 7:  11m51.246s, 13m30.483s
Stage 7.2: 21m32.050s
Stage 8: 191m32.042s, 497m11.804s, 367m50136s
Stage 8.2: 146m20.825s
  ch8_69: 7m34.422s
Stage 9: 2m56.588s

# TODO
 - [ ] Save some information in a configuration file, rather than passing as
       environment variables, to minimize amount of argument passing. This should make
       it easier in the future to automate some stages.
 - [ ] Also track successfully completed stages, to make it easier to start from a
       certain point
 - [ ] Direct logs to a master log file, that can be watched with a single tail -f
 - [ ] stage8_2 calling logout rather than exit
 - [ ] ch9_4 gives "no such file: /etc/udev/rules.d/70-persistent-net.rules"
 - [ ] ch11_3_2 gives "logout: not login shell: use exit"

# Notes
When running on a kvm/qemu host, set network source mode to bridge and device
model to e1000e
