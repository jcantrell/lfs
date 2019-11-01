This project attempts to automate the Linux From Scratch project.
Currently follows version 9.0 of LFS.

Step 1: Prepare the disk
`# sudo bash lfs1.sh`
Step 2: Prepare lfs user environment
`$ bash lfs2.sh`
Step 3: Build temporary tools
`$ bash lfs3.sh`
Step 4: Change owner of tools to root, to avoid UID conflicts
`$ chown -R root:root $LFS/tools`
