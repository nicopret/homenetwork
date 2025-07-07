#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing dependencies..."
sudo apt install -y python3 python3-venv python3-pip libffi-dev libssl-dev autoconf \
  build-essential libopenjp2-7 libjpeg-dev zlib1g-dev libturbojpeg0-dev libavdevice-dev \
  libavfilter-dev libavformat-dev libavcodec-dev libavutil-dev libswscale-dev libudev-dev \
  libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev libgdbm-dev liblzma-dev \
  libnss3-dev bluez libbluetooth-dev

echo "👤 Creating 'homeassistant' user..."
sudo useradd -rm homeassistant -G dialout,gpio,i2c

echo "📁 Creating virtual environment directory..."
sudo mkdir -p /srv/homeassistant
sudo chown homeassistant:homeassistant /srv/homeassistant

echo "🐍 Setting up Home Assistant in virtual environment..."
sudo -u homeassistant -H bash -c "
cd /srv/homeassistant
python3 -m venv .
source bin/activate
pip install --upgrade pip wheel
pip install homeassistant
pip install 'josepy==1.13.0'
"

echo "🛠 Creating systemd service for auto-start..."

cat <<EOF | sudo tee /etc/systemd/system/home-assistant@homeassistant.service
[Unit]
Description=Home Assistant
After=network-online.target

[Service]
Type=simple
User=%i
ExecStart=/srv/homeassistant/bin/hass -c /home/%i/.homeassistant
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

echo "🔁 Enabling and starting Home Assistant service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable home-assistant@homeassistant
sudo systemctl start home-assistant@homeassistant

echo "✅ Home Assistant Core is installed and running!"
echo "🌐 Access it at: http://<your-pi-ip>:8123"
echo "🔍 To check logs: sudo journalctl -u home-assistant@homeassistant -e"
