Here’s a detailed guide to set up your Raspberry Pi 4 as a powerful ZFS-based file server using Cockpit for administration, parity-based ZFS, Samba, rsync to S3, and a reverse proxy for remote access. The setup will include:

- ZFS with parity (RAID-Z1)
- Cockpit for management
- Samba for file sharing
- Reverse proxy for remote access
- Rsync to S3 bucket
- Android sync logic with file lifecycle
- Per-user and shared storage setup

## 🧰 Prerequisites

- Raspberry Pi 4 (4GB or 8GB recommended)
- USB 3.0 drives for ZFS pool (3 or more recommended)
- Raspberry Pi OS Lite (64-bit) installed
- Internet access
- Static IP recommended

## 📁 Structure of Scripts

Each script is named by step for clarity:

- 01_base_setup.sh
- 02_cockpit.sh
- 03_zfs_setup.sh
- 04_user_setup.sh
- 05_samba_setup.sh
- 06_rclone_s3.sh
  After running this script, run rclone config manually to set up your S3 remote.
- 07_reverse_proxy.sh

You can run these scripts sequentially. Each one is self-contained and can be run independently.

## 📱 Android Sync Instructions (Manual):

1. Install FolderSync or Syncthing on Android device.
2. Configure it to sync to your Raspberry Pi SMB share:
   - Server: smb://<raspberrypi-local-ip>
   - Share: /alice, /bob, etc.
   - Credentials: your user/pass
3. Enable:
   - Sync only new files
   - Delete files after 5 days from device (keep on server)
4. Optional: Use Tasker to automate deletion based on file age.
