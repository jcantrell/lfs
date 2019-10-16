r=1
while [ $r -ne 0 ]
do
	bash lfs-build/scripts/sectioni.sh
	r=$?
done

r=1
while [ $r -ne 0 ]
do
	source lfs-build/scripts/sectionii.sh
	r=$?
done

r=1
while [ $r -ne 0 ]
do
	bash $LFS/lfs-build/scripts/sectioniii.sh
	r=$?
done

r=1
while [ $r -ne 0 ]
do
	bash $LFS/lfs-build/scripts/sectioniv.sh
	r=$?
done

r=1
while [ $r -ne 0 ]
do
	bash $LFS/lfs-build/scripts/4/4.sh
	r=$?
done

