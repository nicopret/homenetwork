#!/bin/bash

set -e

echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y raspberrypi-ui-mods xserver-xorg xinit x11-xserver-utils unclutter chromium-browser
sudo apt install -y apt-transport-https software-properties-common xdotool jq

sudo mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt update && sudo apt install -y grafana

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

chown pi:pi "$KIOSK_FILE"

sudo raspi-config nonint do_boot_behaviour B4

sudo mkdir -p /var/lib/grafana/dashboards
sudo wget -O /var/lib/grafana/dashboards/node_exporter_full.json https://grafana.com/api/dashboards/1860/revisions/29/download

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

sudo sed -i 's/;enabled = false/enabled = true/' /etc/grafana/grafana.ini
sudo sed -i 's/;org_name = Main Org./org_name = Main Org./' /etc/grafana/grafana.ini
sudo sed -i 's/;org_role = Viewer/org_role = Viewer/' /etc/grafana/grafana.ini

sudo systemctl enable --now grafana-server
sudo systemctl start grafana-server

# Wait for Grafana to start
echo "⏳ Waiting for Grafana to start..."
sleep 10

# Add Prometheus data source
echo "📡 Adding Prometheus data source..."
curl -s -X POST http://localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n admin:admin | base64)" \
  -d '{
    "name":"Prometheus",
    "type":"prometheus",
    "url":"http://localhost:9100",
    "access":"proxy",
    "basicAuth":false
  }'

# Download Node Exporter Full dashboard JSON
echo "📥 Downloading Node Exporter Full dashboard..."
wget -q https://grafana.com/api/dashboards/1860/revisions/34/download -O /tmp/node_exporter_full.json

# Import dashboard
echo "📊 Importing Node Exporter Full dashboard..."
sudo curl -s -X POST http://localhost:3000/api/dashboards/import \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n admin:admin | base64)" \
  -d @- <<EOF
{
  "dashboard": $(cat /tmp/node_exporter_full.json),
  "overwrite": true,
  "inputs": [
    {
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "Prometheus"
    }
  ]
}
EOF

sudo curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n admin:admin | base64)" \
  -d @- <<EOF
{
  "dashboard": $(jq . node_exporter_full.json),
  "overwrite": true,
  "inputs": [
    {
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "Prometheus"
    }
  ]
}
EOF

echo "🎯 Setting default home dashboard..."
sudo sed -i "s|^;*default_home_dashboard_path.*|default_home_dashboard_path = /d/rYdddlPWk|" /etc/grafana/grafana.ini

sudo curl -X PUT http://localhost:3000/api/org/preferences \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n admin:admin | base64)" \
  -d '{
    "homeDashboardId": 1

  }'

mkdir -p ~/.config/openbox
echo 'chromium-browser --kiosk http://localhost:3000/d/rYdddlPWk/node-exporter-full' > ~/.config/openbox/autostart
sudo systemctl restart grafana-server
