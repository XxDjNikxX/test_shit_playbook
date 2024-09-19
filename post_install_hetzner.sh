#!/bin/bash

add_rfc3442_hook() {
  cat << EOF > /etc/initramfs-tools/hooks/add-rfc3442-dhclient-hook
#!/bin/sh

PREREQ=""

prereqs()
{
        echo "\$PREREQ"
}

case \$1 in
prereqs)
        prereqs
        exit 0
        ;;
esac

if [ ! -x /sbin/dhclient ]; then
        exit 0
fi

. /usr/share/initramfs-tools/scripts/functions
. /usr/share/initramfs-tools/hook-functions

mkdir -p \$DESTDIR/etc/dhcp/dhclient-exit-hooks.d/
cp -a /etc/dhcp/dhclient-exit-hooks.d/rfc3442-classless-routes \$DESTDIR/etc/dhcp/dhclient-exit-hooks.d/
EOF

  chmod +x /etc/initramfs-tools/hooks/add-rfc3442-dhclient-hook
}

remove_unwanted_netplan_config() {
  cat << EOF > /etc/initramfs-tools/scripts/init-bottom/remove_unwanted_netplan_config
#!/bin/sh

if [ -d "/run/netplan" ]; then
  interface=\$(ls /run/netplan/ | cut -d'.' -f1)

  if [ \${interface:+x} ]; then
    rm -f /run/netplan/"\${interface}".yaml
  fi
fi
EOF

  chmod +x /etc/initramfs-tools/scripts/init-bottom/remove_unwanted_netplan_config
}

# Install rfc3442 hook
add_rfc3442_hook

# Adding an initramfs-tools script to remove /run/netplan/{interface}.yaml,
# because it is creating unwanted routes
remove_unwanted_netplan_config

# Update system
apt-get update >/dev/null
apt-get -y install cryptsetup-initramfs dropbear-initramfs

# Copy SSH keys for dropbear and change the port
cp /root/.ssh/authorized_keys /etc/dropbear/initramfs/
sed -ie 's/#DROPBEAR_OPTIONS=/DROPBEAR_OPTIONS="-I 600 -j -k -p 2222 -s"/' /etc/dropbear/initramfs/dropbear.conf
dpkg-reconfigure dropbear-initramfs
update-initramfs -u
