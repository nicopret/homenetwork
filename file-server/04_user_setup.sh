#!/bin/bash

USER_LIST=("nico" "belinda" "isabella")

set -e

echo "[+] Creating users..."
for USER in "${USER_LIST[@]}"; do
  sudo adduser --disabled-password --gecos "" "$USER"
done

echo "[+] Setting ownership for datasets..."
for USER in "${USER_LIST[@]}"; do
    sudo chown $USER:$USER /tank/user_$USER
done
sudo chmod 700 /tank/user_*
sudo chmod 755 /tank/shared
