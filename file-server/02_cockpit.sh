#!/bin/bash
set -e

echo "[+] Installing Cockpit..."
sudo apt install -y cockpit

echo "[+] Enabling Cockpit..."
sudo systemctl enable --now cockpit.socket

echo "[+] Cockpit is available at https://<your-pi-ip>:9090"
