#!/bin/bash

DRIVE_LIST=("sda" "sdb" "sdc" "sdd")
USER_LIST=("nico" "belinda" "isabella")

set -e

echo "[+] Installing ZFS..."
sudo apt install -y zfsutils-linux

echo "Wipe drives..."
for DRIVE in "${DRIVE_LIST[@]}"; do
    sudo wipefs -a /dev/$DRIVE
done

echo "[+] Creating RAID-Z1 pool named 'tank'..."
sudo zpool create tank raidz /dev/${DRIVE_LIST[0]} /dev/${DRIVE_LIST[1]} /dev/${DRIVE_LIST[2]} /dev/${DRIVE_LIST[3]}

echo "[+] Creating datasets..."
for USER in "${USER_LIST[@]}"; do
    sudo zfs create tank/user_$USER
done
sudo zfs create tank/shared
