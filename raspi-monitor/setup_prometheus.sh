#!/bin/bash

# Installing prometheus
echo "⬇️ Downloading and Installing Prometheus..."

sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus
sudo mkdir -p /etc/prometheus /var/lib/prometheus

PROM_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep tag_name | cut -d '"' -f 4)

wget https://github.com/prometheus/prometheus/releases/download/${PROM_VERSION}/prometheus-${PROM_VERSION:1}.linux-armv7.tar.gz

tar -xvzf prometheus-*.linux-armv7.tar.gz
cd prometheus-*.linux-armv7

sudo cp prometheus promtool /usr/local/bin/
sudo cp prometheus.yml /etc/prometheus/

echo "⬇️ Set Prometheus Permissions..."

sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

echo "⬇️ Create a systemd Service..."

sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus

[Install]
WantedBy=multi-user.target
EOF

echo "⬇️ Start Prometheus..."

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

