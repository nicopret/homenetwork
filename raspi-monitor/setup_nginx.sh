
CRON_JOB="*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1"
DOMAIN=nicopretorius
DUCK_TOKEN=0633b16b-ed78-4eb0-8af0-11ad81d21dbf
EXT_IP=$(curl -s ifconfig.me)

sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

sudo tee /etc/nginx/sites-available/grafana > /dev/null <<EOF
server {
    listen 80;
    server_name nicopretorius.duckdns.org;

    location / {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

sudo systemctl restart nginx

sudo certbot --nginx -d nicopretorius.duckdns.org
sudo systemctl list-timers | grep certbot

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

echo "✅ Installation finished."
