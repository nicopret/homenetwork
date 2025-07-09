# Raspberry Pi Monitoring Server Setup

This project sets up a **Raspberry Pi** as a central monitoring server using **Prometheus** and **Grafana**. The server will collect system metrics from other Raspberry Pis and visualize them on Grafana dashboards.

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
sudo apt install git
git clone https://github.com/nicopret/homenetwork.git
cd homenetwork/raspi-monitor

## Run the Installer

```bash
chmod +x setup_main_server.sh
./setup_main_server.sh
```

## Access Grafana

- Open: http://<YOUR_PI_IP>:3000
- Login: admin / admin (you’ll be prompted to change it)

## Add Prometheus as a Data Source

- Go to: Settings → Data Sources
- Choose: Prometheus
- URL: http://localhost:9090

## Import a Dashboard

You can import [Node Exporter Full Dashboard (ID: 1860)](https://grafana.com/grafana/dashboards/1860-node-exporter-full/) from Grafana's community dashboards.


# Use DuckDNS for a Free Subdomain

## Set up DuckDNS:

- Go to https://www.duckdns.org
- Sign in with GitHub, Google, etc.
- Pick a subdomain (e.g., mygrafana)
- It gives you a domain like: `mygrafana.duckdns.org`
- Copy your DuckDNS token and paste it in `setup_duckdns.sh`

