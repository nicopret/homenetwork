#!/bin/bash
set -e

echo "[+] Updating system..."
sudo apt update && sudo apt upgrade -y

echo "[+] Installing common packages..."
sudo apt install -y curl gnupg2 wget software-properties-common git
