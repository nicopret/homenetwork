#!/bin/bash
set -e

echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

echo "[+] Installing common packages..."
sudo apt install -y curl gnupg2 wget software-properties-common git

wget https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-1.8.1.linux-armv7.tar.gz
tar -xzf node_exporter-1.8.1.linux-armv7.tar.gz
sudo mv node_exporter-1.8.1.linux-armv7/node_exporter /usr/local/bin/

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reexec
sudo systemctl enable --now node_exporter

wget https://github.com/prometheus/prometheus/releases/latest/download/prometheus-2.52.0.linux-armv7.tar.gz
tar -xzf prometheus-2.52.0.linux-armv7.tar.gz
cd prometheus-2.52.0.linux-armv7
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ prometheus.yml /etc/prometheus/

sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus Time Series Database
After=network.target

[Service]
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries
User=nobody
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo mkdir -p /var/lib/prometheus
sudo systemctl daemon-reexec
sudo systemctl enable --now prometheus
