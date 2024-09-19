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
# Install hook
add_rfc3442_hook
# Update system
apt-get update >/dev/null
# Install clevis on the system and add clevis to the initramfs
apt-get -y install clevis clevis-luks clevis-initramfs cryptsetup-initramfs
# Get the key from the tang server and then bind the device to the tang server
curl -sfg http://<ip-tangserver>/adv -o /tmp/adv.jws
echo '<secret>' | clevis luks bind -d /dev/sda2 tang '{"url": "http://<ip-tangserver>" , "adv": "/tmp/adv.jws" }'
# Update the existing initramfs
update-initramfs -u
