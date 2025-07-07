#!/bin/bash

# Raspberry Pi Monitoring Server Setup with Grafana Kiosk Mode
# Installs Prometheus, Grafana, and configures auto-start + kiosk dashboard

set -e

echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

# === PROMETHEUS SETUP ===
echo "⬇️ Installing Prometheus..."
cd /tmp
PROM_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/prometheus/prometheus/releases/download/$PROM_VERSION/prometheus-$(echo $PROM_VERSION | cut -c2-).linux-armv7.tar.gz
tar xvf prometheus-${PROM_VERSION#v}.linux-armv7.tar.gz
cd prometheus-${PROM_VERSION#v}.linux-armv7
sudo cp prometheus promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo cp -r consoles/ console_libraries/ /etc/prometheus/

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
  --storage.tsdb.path=/var/lib/prometheus \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now prometheus

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
KIOSK_FILE="/home/pi/.config/lxsession/LXDE-pi/autostart"

mkdir -p "$(dirname "$KIOSK_FILE")"
cat <<EOF > "$KIOSK_FILE"
@xset s off
@xset -dpms
@xset s noblank
@unclutter -idle 0
@chromium-browser --noerrdialogs --disable-infobars --kiosk $KIOSK_URL
EOF

echo "✅ Kiosk mode setup complete."

echo "🔁 Enabling boot to GUI (if not already)..."
sudo raspi-config nonint do_boot_behaviour B4

echo "🎉 DONE! Reboot your Pi and Grafana will auto-launch in full screen."
