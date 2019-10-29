echo -n "6.63.sh : " >> /lfs-build/logs/log6
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
make
echo -n $? >> /lfs-build/logs/log6
make BINDIR=/sbin install
echo $? >> /lfs-build/logs/log6
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF


