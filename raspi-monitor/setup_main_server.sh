#!/bin/bash

# This script is for the Raspberry Lite OS
# Raspberry Pi Monitoring Server Setup with Grafana Kiosk Mode
# Installs Prometheus, Grafana, and configures auto-start + kiosk dashboard

set -e

echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing xserver and drivers ..."
sudo apt install -y raspberrypi-ui-mods xserver-xorg xinit x11-xserver-utils unclutter chromium-browser

echo "📦 Installing Grafana server ..."
sudo apt install -y nginx grafana xdotool

# === PROMETHEUS SETUP ===
echo "⬇️ Installing Prometheus..."
cd /tmp
PROM_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep tag_name | cut -d '"' -f 4)
PROM_VERSION_CLEAN=${PROM_VERSION#v}
FOLDER="prometheus-${PROM_VERSION_CLEAN}.linux-armv7"

wget https://github.com/prometheus/prometheus/releases/download/${PROM_VERSION}/${FOLDER}.tar.gz
tar xvf ${FOLDER}.tar.gz
cd $FOLDER

# Installing Prometheus binaries
sudo cp prometheus promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus /var/lib/prometheus

echo "📝 Writing Prometheus config..."
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'main-pi'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'raspberry-pis'
    static_configs:
      - targets: ['pi1.local:9100', 'pi2.local:9100']  # Replace with your actual Pis
EOF

echo "⚙️ Creating Prometheus service..."
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=pi
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now prometheus

# Installing Node Exporter
echo "⬇️ Installing Node Exporter ..."
cd /tmp
NODE_VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name | cut -d '"' -f 4)
NODE_VERSION_CLEAN=${NODE_VERSION#v}
NODE_FOLDER="node_exporter-${NODE_VERSION_CLEAN}.linux-armv7"

sudo wget https://github.com/prometheus/node_exporter/releases/download/${NODE_VERSION}/${NODE_FOLDER}.tar.gz
sudo tar xvf ${NODE_FOLDER}.tar.gz
cd $NODE_FOLDER
sudo cp node_exporter /usr/local/bin

# Create systemd service for Node Exporter
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable --now node_exporter

# === GRAFANA SETUP ===
echo "📦 Installing Grafana..."
sudo apt install -y apt-transport-https software-properties-common
sudo mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt update
sudo apt install grafana -y
sudo systemctl enable --now grafana-server

# === GUI & KIOSK SETUP ===
echo "🖥️ Installing desktop GUI & Chromium..."
sudo apt install -y raspberrypi-ui-mods xserver-xorg x11-xserver-utils unclutter chromium-browser

echo "🛠️ Configuring kiosk mode on boot..."

KIOSK_URL="http://localhost:3000"
AUTOSTART_DIR="/home/pi/.config/lxsession/LXDE-pi"
KIOSK_FILE="$AUTOSTART_DIR/autostart"

mkdir -p "$AUTOSTART_DIR"
cat <<EOF > "$KIOSK_FILE"
@lxpanel --profile LXDE-pi
@pcmanfm --desktop --profile LXDE-pi
@xset s off
@xset -dpms
@xset s noblank
@unclutter -idle 0
@chromium-browser --noerrdialogs --disable-infobars --disable-translate --no-first-run --fast --kiosk http://localhost:3000/d/rYdddlPWk/node-exporter-full
EOF

# Ensure proper permissions
chown pi:pi "$KIOSK_FILE"

echo "✅ Kiosk mode setup complete."

echo "🔁 Enabling boot to GUI (if not already)..."
sudo raspi-config nonint do_boot_behaviour B4

echo "📥 Downloading Node Exporter Full dashboard JSON..."
sudo mkdir -p /var/lib/grafana/dashboards
sudo wget -O /var/lib/grafana/dashboards/node_exporter_full.json https://grafana.com/api/dashboards/1860/revisions/29/download

echo "🛠️ Configuring Grafana to auto-import dashboards..."
sudo tee /etc/grafana/provisioning/dashboards/node_exporter.yml > /dev/null <<EOF
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
EOF

echo "🔧 Configuring Grafana for anonymous access..."

# Update grafana.ini to allow anonymous viewing
sudo sed -i 's/;enabled = false/enabled = true/' /etc/grafana/grafana.ini
sudo sed -i 's/;org_name = Main Org./org_name = Main Org./' /etc/grafana/grafana.ini
sudo sed -i 's/;org_role = Viewer/org_role = Viewer/' /etc/grafana/grafana.ini

# Restart Grafana to apply changes
sudo systemctl enable nginx
sudo systemctl restart grafana-server

echo "🌐 Fetching external IP..."
EXT_IP=$(curl -s ifconfig.me)

echo "📝 Writing NGINX reverse proxy config with server_name = $EXT_IP"

sudo tee /etc/nginx/sites-available/grafana > /dev/null <<EOF
server {
    listen 80;
    server_name ${EXT_IP};

    location / {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade 'websocket';
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host ${EXT_IP};
        proxy_cache_bypass 'websocket';
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

echo "🎉 DONE! Reboot your Pi and Grafana will auto-launch in full screen."

# Set up kiosk autologin
sudo raspi-config nonint do_boot_behaviour B4
mkdir -p ~/.config/openbox
echo 'chromium-browser --kiosk http://localhost:3000/d/rYdddlPWk/node-exporter-full' > ~/.config/openbox/autostart

sudo reboot 0
