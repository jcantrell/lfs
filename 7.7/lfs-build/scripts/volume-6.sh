bash /lfs-build/scripts/6/6.6.1.sh
bash /lfs-build/scripts/6/6.sh

bash /lfs-build/scripts/6/6.72.sh
bash /lfs-build/scripts/6/6.73.sh

cd /sources
tar -xf lfs-bootscripts-20150222.tar.bz2
cd lfs-bootscripts-20150222
make install
cd ..
rm -rf lfs-bootscripts-20150222

bash /lib/udev/init-net-rules.sh
bash /lfs-build/scripts/7/7.5.sh
bash /lfs-build/scripts/7/7.6.sh
bash /lfs-build/scripts/7/7.8.sh
bash /lfs-build/scripts/7/7.9.sh

bash /lfs-build/scripts/8/8.2.sh

cd /sources
tar -xf linux-3.19.tar.xz
cd linux-3.19
bash /lfs-build/scripts/8/8.3.sh
cd ..
rm -rf linux-3.19

bash /lfs-build/scripts/8/8.4.sh
