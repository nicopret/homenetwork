#!/bin/bash
set -e

echo "[+] Installing rclone..."
sudo apt install -y rclone

echo "[+] Please run 'rclone config' manually to connect to your S3 provider."
echo "Run: rclone config"

cat <<EOF | sudo tee /usr/local/bin/zfs-to-s3.sh > /dev/null
#!/bin/bash
rsync -avh /tank/ mys3:backup-zfs
EOF

sudo chmod +x /usr/local/bin/zfs-to-s3.sh

echo "[+] Adding cron job for daily sync at 3AM..."
( crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/zfs-to-s3.sh" ) | crontab -

echo After running this script, run rclone config manually to set up your S3 remote.
