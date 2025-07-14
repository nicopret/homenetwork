#!/bin/bash

# Customize these
POOL_NAME="tank"
DISK="/dev/sda"
USER_LIST=("user1" "user2")
PUBLIC_GROUP="shared"

sudo apt install -y linux-headers-$(uname -r) build-essential
sudo apt install -y dkms
sudo apt install -y zfs-dkms zfsutils-linux
sudo modprobe zfs
git clone https://github.com/optimans/cockpit-zfs-manager.git
sudo cp -r cockpit-zfs-manager/zfs /usr/share/cockpit

# Create the ZFS pool
echo "Creating ZFS pool $POOL_NAME on $DISK"
zpool create -f $POOL_NAME $DISK

# Create dataset for each user
for USER in "${USER_LIST[@]}"; do
    echo "Creating dataset for $USER"
    zfs create $POOL_NAME/users/$USER
    mkdir -p /$POOL_NAME/users/$USER
    chown $USER:$USER /$POOL_NAME/users/$USER
    chmod 700 /$POOL_NAME/users/$USER
done

# Create public/shared dataset
echo "Creating public shared dataset"
zfs create $POOL_NAME/public
mkdir -p /$POOL_NAME/public
groupadd $PUBLIC_GROUP
chmod 2775 /$POOL_NAME/public
chown root:$PUBLIC_GROUP /$POOL_NAME/public

# Set mountpoints explicitly (optional)
zfs set mountpoint=/tank/users $POOL_NAME/users
zfs set mountpoint=/tank/public $POOL_NAME/public

# Confirm pool and datasets
zfs list
