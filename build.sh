#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"
[ ! -d /tmp/rpms ] && mkdir -p /tmp/rpms
curl -s -Lo /tmp/rpms/rpmfusion-free-release-${RELEASE}.noarch.rpm https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${RELEASE}.noarch.rpm
curl -s -Lo /tmp/rpms/rpmfusion-nonfree-release-${RELEASE}.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${RELEASE}.noarch.rpm
dnf install -y \
    /tmp/rpms/*.rpm \
    fedora-repos-archive
    
dnf remove -y nfs-utils-coreos
dnf install -y htop nfs-utils \
qbittorrent-nox unzip unrar targetcli iscsi-initiator-utils \
sanoid samba samba-usershares hdparm pciutils rclone snapraid usbutils xdg-dbus-proxy xdg-user-dirs \
perl-Config-IniFiles perl-Data-Dumper perl-Capture-Tiny perl-Getopt-Long lzop mbuffer mhash pv

TMP="$(mktemp)"
cat <<EOF > "$TMP"
docker.service
nginx.service

portaineragent.service

autoreboot.timer
docker-cleanup.timer

zfs-snap@mirpool.timer
zpool-pushover@mirpool.timer
zpool-scrub@mirpool.timer
EOF

cat "$TMP" | grep -v "^#" | grep '\.service$\|\.timer' | while IFS= read -r i; do
  systemctl enable "$i"
done

git clone https://github.com/zfsnap/zfsnap.git /usr/src/zfsnap
cp /usr/src/zfsnap/sbin/zfsnap.sh /usr/sbin/zfsnap
cp /usr/src/zfsnap/man/man8/zfsnap.8 /usr/share/man/man8/zfsnap.8
cp -r /usr/src/zfsnap/share /usr
chmod +x /usr/sbin/zfsnap
rm -rf /usr/src/zfsnap

find /usr/bin -type f | grep '\.sh$' | sort | while IFS= read -r i; do
  chmod +x "$i"
done

[ -f "$TMP" ] && rm -f "$TMP"
