🧾 What This Script Does

- Updates the system
- Installs required dependencies (Python, system libs)
- Creates a Python virtual environment
- Installs Home Assistant Core
- Sets it to run manually (or optionally with systemd)

Steps:

- Install git with the following:

``` bash
sudo apt update && sudo apt install git
```

Then do a `git --version` to ensure the installation was successful.

- Clone the repo and setup the install script

Clone the repo with: 
```
git clone https://github.com/nicopret/homenetwork.git
cd homenetwork
sudo chmod +x install_homeassistant.sh
```

- Run the setup script:

```
./install_homeassistant.sh
```
