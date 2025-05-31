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
qbittorrent-nox mktorrent mediainfo transmission-cli transmission-daemon unzip unrar \
targetcli iscsi-initiator-utils ntfs-3g fuse \
sanoid samba samba-usershares cifs-utils wondershaper avahi avahi-tools nss-mdns dbus-daemon \
hdparm pciutils rclone snapraid usbutils xdg-dbus-proxy xdg-user-dirs \
perl-Config-IniFiles perl-Data-Dumper perl-Capture-Tiny perl-Getopt-Long lzop mbuffer mhash pv bc

# FULLRELEASE=$(curl -fsSL https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
# rm -f /usr/bin/qbittorrent-nox
# curl -fsSL "https://github.com/userdocs/qbittorrent-nox-static/releases/download/${FULLRELEASE}/x86_64-qbittorrent-nox" -o /usr/bin/qbittorrent-nox
# chmod +x /usr/bin/qbittorrent-nox

TMP="$(mktemp)"
cat <<EOF > "$TMP"
docker.service
nginx.service
autoreboot.timer
docker-cleanup.timer
zfs-snap@mirpool.timer
zpool-pushover@mirpool.timer
zpool-scrub@mirpool.timer
EOF

systemctl disable fwupd-refresh.timer

cat "$TMP" | grep -v "^#" | grep '\.service$\|\.timer' | while IFS= read -r i; do
  systemctl enable "$i"
done

git clone https://github.com/zfsnap/zfsnap.git /usr/src/zfsnap
cp /usr/src/zfsnap/sbin/zfsnap.sh /usr/sbin/zfsnap
cp /usr/src/zfsnap/man/man8/zfsnap.8 /usr/share/man/man8/zfsnap.8
cp -r /usr/src/zfsnap/share /usr
chmod +x /usr/sbin/zfsnap
rm -rf /usr/src/zfsnap

curl -sSL -o ffmpeg-master-latest-linux64-gpl.tar.xz "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz" \
&& xz -d ffmpeg-master-latest-linux64-gpl.tar.xz \
&& tar xvf ffmpeg-master-latest-linux64-gpl.tar 2>&1 | grep 'bin/ff' | while IFS= read -r i; do
  FILENAME="$(echo "$i" | rev | cut -d'/' -f1 | rev)"
  mv "$i" /usr/bin/
  chmod +x /usr/bin/${FILENAME}
done
rm -rf ./ffmpeg-master-latest-linux64-gpl*

find /usr/bin -type f | grep '\.sh$' | sort | while IFS= read -r i; do
  chmod +x "$i"
done

[ -f "$TMP" ] && rm -f "$TMP"
