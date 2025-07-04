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

echo "🏠 Creating Home Assistant user..."
sudo useradd -rm homeassistant -G dialout,gpio,i2c

echo "📁 Creating Home Assistant directory..."
sudo mkdir -p /srv/homeassistant
sudo chown homeassistant:homeassistant /srv/homeassistant

echo "🐍 Creating virtual environment..."
sudo -u homeassistant -H bash -c "
cd /srv/homeassistant
python3 -m venv .
source bin/activate
pip install --upgrade pip
pip install wheel
pip install homeassistant
"

echo "✅ Home Assistant installed!"
echo "👉 To start Home Assistant:"
echo "   sudo -u homeassistant -H -s"
echo "   cd /srv/homeassistant"
echo "   source bin/activate"
echo "   hass"

echo "🌐 After first launch, open: http://<your-raspberry-ip>:8123"
