#!/bin/bash

DRIVE_LIST=("sda" "sdb" "sdc" "sdd")
USER_LIST=("nico" "belinda" "isabella")
POOL_NAME="tank"

set -e

echo "[+] Installing ZFS..."
sudo apt install -y linux-headers-$(uname -r) build-essential dkms zfs-dkms zfsutils-linux

sudo modprobe zfs
git clone https://github.com/optimans/cockpit-zfs-manager.git
sudo cp -r cockpit-zfs-manager/zfs /usr/share/cockpit

echo "Wipe drives..."
for DRIVE in "${DRIVE_LIST[@]}"; do
    sudo wipefs -a /dev/$DRIVE
done

echo "[+] Creating RAID-Z1 pool named 'tank'..."
sudo zpool create $POOL_NAME raidz -f -o ashift=12 /dev/${DRIVE_LIST[0]} /dev/${DRIVE_LIST[1]} /dev/${DRIVE_LIST[2]} /dev/${DRIVE_LIST[3]}

echo "[+] Creating datasets..."
for USER in "${USER_LIST[@]}"; do
    sudo zfs create $POOL_NAME/user_$USER
    mkdir -p /$POOL_NAME/users/$USER
    chown $USER:$USER /$POOL_NAME/users/$USER
    chmod 700 /$POOL_NAME/users/$USER
done

zfs create $POOL_NAME/public
mkdir -p /$POOL_NAME/public
groupadd shared
chmod 2775 /$POOL_NAME/public
chown root:shared /$POOL_NAME/public
