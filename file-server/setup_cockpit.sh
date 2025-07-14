sudo apt update && sudo apt upgrade -y

# installing cockpit
sudo apt install cockpit -y
sudo systemctl enable --now cockpit.socket

# isntalling samba

USER1=nico
USER2=belinda
USER3=isabella

sudo apt install samba -y

cat <<EOF | sudo tee /etc/samba/smb.conf
[public]
   path = /tank/public
   browsable = yes
   writable = yes
   guest ok = yes
   create mask = 0775

[private]
   path = /tank/users/%U
   browsable = no
   writable = yes
   valid users = %U
   create mask = 0700
EOF

sudo mkdir -p /tank/users/$USER1 /tank/users/$USER2 /tank/users/$USER3 /tank/public
sudo chown $USER1:$USER1 /tank/users/$USER1
sudo chown $USER2:$USER2 /tank/users/$USER2
sudo chown $USER3:$USER3 /tank/users/$USER3

sudo smbpasswd -a $USER1
sudo smbpasswd -a $USER2
sudo smbpasswd -a $USER3

# installing zsf

