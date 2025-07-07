✅ Step-by-Step Installation of OpenZFS on Raspberry Pi

# 🔧 Prerequisites

- Raspberry Pi OS (64-bit) preferred (Bullseye or Bookworm).
- Kernel headers must match your kernel.
- Root access (sudo) required.

## Update System

```bash
sudo apt update && sudo apt upgrade -y
```

## Install Required Packages

```bash
sudo apt install -y linux-headers-$(uname -r) build-essential git dkms zfsutils-linux
```

If zfsutils-linux is not found, you need to enable the contrib and non-free repositories in /etc/apt/sources.list.

## Install ZFS via DKMS (Dynamic Kernel Module Support)

This will build the ZFS kernel module on your Pi:

```bash
sudo apt install -y dkms
sudo apt install -y zfs-dkms zfsutils-linux
```

This will take several minutes to compile

## Load ZFS Kernel Module

```bash
sudo modprobe zfs
```

Check if it worked:

```bash
dmesg | grep ZFS
```

## Verify ZFS Installation

```bash
zfs version
```

You should see something like:

```bash
zfs-2.1.x
zfs-kmod-2.1.x
```

# ✅ Recommended ZFS Web Admin Interfaces

## Cockpit with cockpit-zfs-manager

- Cockpit is a modern web-based server admin interface.
- cockpit-zfs-manager is a plugin specifically for managing ZFS pools, snapshots, and datasets.

🔧 Installation on Raspberry Pi:

```bash
sudo apt install cockpit
sudo systemctl enable --now cockpit.socket
```

Then install the ZFS plugin:

```bash
git clone https://github.com/optimans/cockpit-zfs-manager.git
sudo cp -r cockpit-zfs-manager/zfs /usr/share/cockpit
```

### Samba

Update the System

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install samba -y
```

Edit the Samba config file:
```bash
sudo vi /etc/samba/smb.conf
```

Add to the end of the file:
```bash
[Shared]
   path = /srv/samba/share
   browseable = yes
   read only = no
   guest ok = yes
   force user = nobody
```

Auto generated snapshot names are created in YYYY.MM.DD-HH.MM.SS format.

It is recommended to add the following properties to the Samba configuration file to allow access to Previous Versions in Windows Explorer:

Append to [global] section or individual share sections
```bash
shadow: snapdir = .zfs/snapshot
shadow: sort = desc
shadow: format = %Y.%m.%d-%H.%M.%S
shadow: localtime = yes	
vfs objects = acl_xattr shadow_copy2
```

## Using Cockpit ZFS Manager

Login to Cockpit as an administrative user and click ZFS from the navigation list.

A Welcome to Cockpit ZFS Manager modal will display and allow you to configure initial settings.

### Caveats

#### Storage Pools

New storage pools are created with the following properties set (not visible in Create Storage Pool modal):

- aclinherit=passthrough
- acltype=posixacl
- casesensitivity=sensitive
- normalization=formD
- sharenfs=off
- sharesmb=off
- utf8only=on
- xattr=sa

#### File Systems
New file systems are created with the following properties set (not visible in Create File System modal):

- normalization=formD
- utf8only=on
- Passphrase is currently supported for encrypted file systems.

If SELinux contexts for Samba is selected, the following properties are set:

- context=system_u:object_r:samba_share_t:s0
- fscontext=system_u:object_r:samba_share_t:s0
- defcontext=system_u:object_r:samba_share_t:s0
- rootcontext=system_u:object_r:samba_share_t:s0

#### Samba
ZFS always creates shares in /var/lib/samba/usershares folder when ShareSMB property is enabled. This is also the case even if Cockpit ZFS Manager is managing the shares. To avoid duplicate shares of the same file system, it is recommended to configure a different usershares folder path if required or to disable usershares in the Samba configuration file.

Note: Newer versions of Samba may require the usershares folder to be set to a new path instead of disabled in configuration:

```bash
sudo mkdir /var/lib/samba/usershares2
sudo vi /etc/samba/smb.conf
```

Append/Change to [global] section

```bash
usershare path = /var/lib/samba/usershares2
```

If enabled, Cockpit ZFS Manager manages shares for the file systems only. Samba global configuration will need to be configured externally.

### Restart Samba

```bash
sudo systemctl restart smbd
```
