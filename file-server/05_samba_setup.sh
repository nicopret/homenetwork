#!/bin/bash

USER_LIST=("nico" "belinda" "isabella")
PASSWORD=pass123

set -e

echo "[+] Installing Samba..."
sudo apt install -y samba

echo "[+] Configuring Samba shares..."
sudo tee -a /etc/samba/smb.conf > /dev/null <<EOF
[${USER_LIST[0]}]
    comment = ${USER_LIST[0]} Private Folder
    path = /tank/user_${USER_LIST[0]}
    valid users = ${USER_LIST[0]}
    read only = no
    public = no
    browseable = yes
    writable = yes
    create mask = 0777
    directory mask = 0777

[${USER_LIST[1]}]
    comment = ${USER_LIST[1]} Private Folder
    path = /tank/user_${USER_LIST[1]}
    valid users = ${USER_LIST[1]}
    read only = no
    public = no
    browseable = yes
    writable = yes
    create mask = 0777
    directory mask = 0777

[${USER_LIST[2]}]
    comment = ${USER_LIST[2]} Private Folder
    path = /tank/user_${USER_LIST[2]}
    valid users = ${USER_LIST[2]}
    read only = no
    public = no
    browseable = yes
    writable = yes
    create mask = 0777
    directory mask = 0777

[shared]
    comment = Public Shared Folder
    path = /tank/public
    public = yes
    browseable = yes
    writable = yes
    create mask = 0777
    directory mask = 0777
    guest ok = yes
EOF

echo "[+] Setting Samba passwords..."
for USER in "${USER_LIST[@]}"; do
  sudo smbpasswd -a "$USER"
    useradd -p $PASSWORD -d /home/$USER -s /bin/bash $USER
    (echo $PASSWORD; echo $PASSWORD) | smbpasswd -a -s $USER
done


sudo systemctl restart smbd
