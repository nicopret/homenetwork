
sudo useradd --no-create-home --shell /usr/sbin/nologin node_exporter

cd /tmp
NODE_EXPORTER_VERSION="1.8.1"
wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-${NODE_EXPORTER_VERSION}.linux-armv7.tar.gz
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-armv7.tar.gz
sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-armv7/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
