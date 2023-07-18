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
  echo "Ok all set, run this script again when you are ready. As pi... so either log out and back in as user: pi, or...idk.."
  exit 1
fi

# Check if the script is running as the pi user
if [[ $EUID -ne 1000 ]]; then
  echo "This script must be run as the pi user"
  exit 1
fi

echo "Starting System Updates"
sudo apt update -y && sudo apt upgrade -y
echo "Initial Updates DONE"
#Install some libraries that will be needed for prusaLink and connect
sudo apt install -y \
evtest \
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

# Clone all our necessary repos...
cd /home/pi
git clone https://github.com/prusa3d/Prusa-Link.git
git clone https://github.com/prusa3d/Prusa-Connect-SDK-Printer.git
git clone https://github.com/libts/tslib.git
git clone https://github.com/ImpulseAdventure/GUIslice
git clone https://github.com/acorrow/LCD-show-ubuntu.git

#Fix 1: GUIslice needs a config selected, thats fine do it by uncommenting the generic SDL Linux setup file. It works perfectly.
#Enable tslib sdl1.2 mode for Linux.
sed -i 's|//\(#include "../configs/rpi-sdl1-default-tslib.h"\)|\1|' ~/GUIslice/src/GUIslice_config.h

#Except for one thing, the touchscreen event will be hard coded in the config to dev/input/touchscreen
#This may not be the case for you, and in any event, its always an eventId where i've seen, so replace
#touchscreen with event0 in this case. You can see how to modify this script to change it to whatever.
#TODO Automatically grab the connected/identified touchscreen via evtest and use that here.
#Modify the Touchscreen to be event0...
sed -i 's/\(#define GSLC_DEV_TOUCH *\).*$/\1"\/dev\/input\/event0"/' ~/GUIslice/configs/rpi-sdl1-default-tslib.h

#This ini file tells prusalink to look at the USB port for a printer
#Otherwise the default setup is a PI Zero with the Einsey connected
#directly to the serial GPIO Pins on the pi.
echo "Setting up etc/Prusa-Link/prusa-link.ini - This allows for USB access to the Printer"

sudo mkdir -p /etc/Prusa-Link/
sudo tee "/etc/Prusa-Link/prusa-link.ini" >/dev/null <<EOF
[printer]
port=/dev/ttyACM0
baudrate=115200
EOF

##TODO Remove Welcome Message

#Actually install Prusa-Link
sudo pip3 install git+https://github.com/prusa3d/gcode-metadata.git@master#egg=gcode_metadata
sudo PIP_NO_WARN_SCRIPT_LOCATION=1 pip3 install /home/pi/Prusa-Connect-SDK-Printer/.
sudo PIP_NO_WARN_SCRIPT_LOCATION=1 pip3 install /home/pi/Prusa-Link/.

# Define the systemd service
echo "Removing .service files"
sudo rm /etc/systemd/system/prusa-link.service
sudo rm /etc/systemd/system/wlan0-redirect.service
sudo rm /etc/systemd/system/eth0-redirect.service

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
sudo systemctl daemon-reload
sudo systemctl start wlan0-redirect.service
sudo systemctl start eth0-redirect.service
sudo systemctl start prusa-link.service &

echo "Enabling!!"
# Enable the service to start at boot
sudo systemctl enable prusa-link.service
sudo systemctl enable eth0-redirect.service
sudo systemctl enable wlan0-redirect.service

cd /home/pi/tslib
./autogen.sh
./configure
make
sudo make install

# Set the desired values of the environment variables
TSLIB_FBDEVICE="/dev/fb1"
TSLIB_TSDEVICE="/dev/input/event0"
TSLIB_CALIBFILE="/usr/local/etc/pointercal"
TSLIB_CONFFILE="/usr/local/etc/ts.conf"


# Check if each environment variable is defined in the file
if ! grep -q "^TSLIB_FBDEVICE=" /etc/environment; then
  sudo sh -c 'echo "TSLIB_FBDEVICE=\"'$TSLIB_FBDEVICE'\"" >> /etc/environment'
fi

if ! grep -q "^TSLIB_TSDEVICE=" /etc/environment; then
  sudo sh -c 'echo "TSLIB_TSDEVICE=\"'$TSLIB_TSDEVICE'\"" >> /etc/environment'
fi

if ! grep -q "^TSLIB_CALIBFILE=" /etc/environment; then
  sudo sh -c 'echo "TSLIB_CALIBFILE=\"'$TSLIB_CALIBFILE'\"" >> /etc/environment'
fi

if ! grep -q "^TSLIB_CONFFILE=" /etc/environment; then
  sudo sh -c 'echo "TSLIB_CONFFILE=\"'$TSLIB_CONFFILE'\"" >> /etc/environment'
fi

# Load the updated environment variables
source /etc/environment

# Print a message indicating that the script has finished
echo "Environment variables updated"
#GUIslice doesn't respect the locations you chose, so you need a 
#symbolic link to the files to be in the etc folder. Dumb. Should raise a bug.
sudo ln -sf /usr/local/etc/pointercal /etc/pointercal
sudo ln -sf /usr/local/etc/ts.conf /etc/ts.conf

#cd GUIslice/examples/linux
#make test_sdl1

#Prompt Color
#bashrc PS1 variable = prompt colors
#[38;5;208m\]
#That is the color we need to grep/replace in the PS1 for Ubuntu bash...

#Add a cronjob that will check to be sure pointercal exists on every boot, and if not, run tf_calibrate to create it
echo "@reboot if [ ! -f \"/usr/local/etc/pointercal\" ]; then sudo tf_calibrate; fi" | sudo crontab -

#Do this last. It will reboot the device.
#tft and use http its public
cd /home/pi/LCD-show-ubuntu
sudo ./LCD35-show

