#!/bin/bash
sudo apt update
sudo apt install certbot python3-certbot-nginx -y

CRON_JOB="*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1"
DOMAIN=nicopretorius
DUCK_TOKEN=0633b16b-ed78-4eb0-8af0-11ad81d21dbf
EXT_IP=$(curl -s ifconfig.me)

mkdir -p ~/duckdns
cd ~/duckdns

sudo tee ./duck.sh > /dev/null <<EOF

echo url="https://www.duckdns.org/update?domains=$DOMAIN&token=$DUCK_TOKEN&ip=$EXT_IP" | curl -k -o ~/duckdns/duck.log -K -

EOF

sudo chmod +x duck.sh
./duck.sh

# Check if it already exists
(crontab -l 2>/dev/null | grep -F -q "$CRON_JOB") && {
  echo "✅ Cron job already exists."
  exit 0
}

# Add the job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "✅ Cron job added."

sudo certbot --nginx -d $DOMAIN.duckdns.org
sudo systemctl list-timers | grep certbot

ECHO "✅ Installation finished."
