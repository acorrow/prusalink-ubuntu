#!/bin/bash

#The Prusa-Link software looks for a user named `pi` since it's built on (by default)
#A raspberry pi. This script takes into account that you might not be running a pi.
#Perhaps you are running a potato... or a laptop... Who knows... Its Linux. You are
#Maybe running it in Minecraft for all I know...
if id "pi" >/dev/null 2>&1; then
  echo "User 'pi' exists"
else
  #Create the user pi, set its password to `password` and add it to the sudo group
  echo "User 'pi' does not exist. Creating them now..."
  sudo useradd -m -s /bin/bash pi
  sudo usermod --password $(echo "password" | openssl passwd -1 -stdin) pi
  sudo usermod -aG sudo pi
fi

#Here we read the GitHub Token from your input to this command. If you dont enter this
#We can't clone the repos and you might as well stop right here...
GHT=$1
echo "Starting System Updates"
sudo apt update -y && sudo apt upgrade -y
echo "Initial Updates DONE"
#Install some libraries that will be needed for prusaLink and connect
sudo apt install -y \
iptables \
libmagic1 \
libturbojpeg0-dev \
libcap-dev \
jq \
git \
python3-pip \
neofetch \
build-essential \
libsdl1.2-dev \
libsdl-image1.2-dev \
libsdl-ttf2.0-dev \
automake \
libtool

#This ini file tells prusalink to look at the USB port for a printer
#Otherwise the default setup is a PI Zero with the Einsey connected
#directly to the serial GPIO Pins on the pi.
echo "Setting up etc/Prusa-Link/prusa-link.ini - This allows for USB access to the Printer"

sudo tee "/etc/Prusa-Link/prusa-link.ini" >/dev/null <<EOF
[printer]
port=/dev/ttyACM0
baudrate=115200
EOF
#If we passed in the GitHub Token, we are going to use that to manage our SSH Keys
#On GitHub. Specifically the Prusa-Link repo(s) require SSH auth. So we quickly
#Check to see if there is already a key we can just upload, if not we create one
#And upload it. If you passed in nothing here, we abort as we can't get the code
#We are tryijng to build
if [ -z "$GHT" ]; then
  echo "Skipping the SSH Key add to Git Hub. Hope you already have one, if not this shit's about to FAIL!"
else
  ssh-keyscan -t ed25519 github.com >>/root/.ssh/known_hosts
  if stat /root/.ssh/id_rsa >/dev/null 2>&1; then
    echo "SSH Key already exists. Just export it to GitHub"
  else
    echo "No SSH Key exists on this machine. Generating..."
    ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa
  fi
  echo "Exporting SSH Key to GitHub"
  sshKey=$(cat /root/.ssh/id_rsa.pub)
  existingId=$(curl -s -X GET -H "Authorization: token $GHT" https://api.github.com/user/keys | jq -r '.[] | select(.title == "prusaLinkSSHKey") | .id')
  echo $existingId
  if [ ! -z "$existingId" ]; then
    echo "SSHKey with this name already exists. Deleting it."
    curl -s -X DELETE -H "Authorization: token $GHT" https://api.github.com/user/keys/$existingId
  fi
  curl -X POST -H "Authorization: token $GHT" https://api.github.com/user/keys -d "{\"title\":\"prusaLinkSSHKey\",\"key\":\"$sshKey\"}"
fi

##TODO Remove Welcome Message

git clone git@github.com:prusa3d/Prusa-Link.git
git clone git@github.com:prusa3d/Prusa-Connect-SDK-Printer.git


#Actually install Prusa-Link
sudo PIP_NO_WARN_SCRIPT_LOCATION=1 pip3 install Prusa-Connect-SDK-Printer/.
sudo PIP_NO_WARN_SCRIPT_LOCATION=1 pip3 install Prusa-Link/.

# Define the systemd service
echo "Removing .service files"
rm /etc/systemd/system/prusa-link.service
rm /etc/systemd/system/wlan0-redirect.service
rm /etc/systemd/system/eth0-redirect.service

echo "Making all the files..."
#We define a service to redirect port 80 to 8080, one service for each adapter
#Again we make no assumptions here, maybe you are using a Pi with POE here?
sudo tee "/etc/systemd/system/prusa-link.service" >/dev/null <<EOF
[Unit]
Description=Prusa Link Service
After=network.target

[Service]
ExecStart=prusalink -i start
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo tee "/etc/systemd/system/wlan0-redirect.service" >/dev/null <<EOF
[Unit]
Description=IPTables Redirect Service
After=network.target

[Service]
ExecStart=/usr/sbin/iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 8080
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo tee "/etc/systemd/system/eth0-redirect.service" >/dev/null <<EOF
[Unit]
Description=IPTables Redirect Service
After=network.target

[Service]
ExecStart=/usr/sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

echo "Starting services"
# Reload the systemd daemon and start the service
systemctl daemon-reload
systemctl start wlan0-redirect.service
systemctl start eth0-redirect.service
systemctl start prusa-link.service &

echo "Enabling!!"
# Enable the service to start at boot
systemctl enable prusa-link.service
systemctl enable eth0-redirect.service
systemctl enable wlan0-redirect.service

cd
git clone https://github.com/ImpulseAdventure/GUIslice


#cd GUIslice/examples/linux
#make test_sdl1

#Prompt Color
#bashrc PS1 variable = prompt colors
#[38;5;208m\]
#That is the color we need to grep/replace in the PS1 for Ubuntu bash...

#Do this last. It will reboot the device.
#tft and use http its public
git clone https://github.com/acorrow/LCD-show-ubuntu.git
cd LCD-show-ubuntu
sudo ./LCD35-show

