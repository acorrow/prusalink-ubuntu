#!/bin/bash
cd
git clone https://github.com/libts/tslib.git
cd tslib
./autogen.sh
./configure
make
sudo make install
cd
git clone https://github.com/ImpulseAdventure/GUIslice
#Enable tslib sdl1.2 mode for Linux.
sed -i 's|//\(#include "../configs/rpi-sdl1-default-tslib.h"\)|\1|' /home/pi/GUIslice/src/GUIslice_config.h
#Modify the Touchscreen to be event0...
sed -i 's/\(#define GSLC_DEV_TOUCH *\).*$/\1"\/dev\/input\/event0"/' /home/pi/GUIslice/configs/rpi-sdl1-default-tslib.h

# Set the desired values of the environment variables
TSLIB_FBDEVICE="/dev/fb1"
TSLIB_TSDEVICE="/dev/input/event0"
TSLIB_CALIBFILE="/usr/local/etc/pointercal"
TSLIB_CONFFILE="/usr/local/etc/ts.conf"

# Check if each environment variable is defined in the file
if ! grep -q "^TSLIB_FBDEVICE=" /etc/environment; then
  echo "TSLIB_FBDEVICE=\"$TSLIB_FBDEVICE\"" >> /etc/environment
fi

if ! grep -q "^TSLIB_TSDEVICE=" /etc/environment; then
  echo "TSLIB_TSDEVICE=\"$TSLIB_TSDEVICE\"" >> /etc/environment
fi

if ! grep -q "^TSLIB_CALIBFILE=" /etc/environment; then
  echo "TSLIB_CALIBFILE=\"$TSLIB_CALIBFILE\"" >> /etc/environment
fi

if ! grep -q "^TSLIB_CONFFILE=" /etc/environment; then
  echo "TSLIB_CONFFILE=\"$TSLIB_CONFFILE\"" >> /etc/environment
fi

# Load the updated environment variables
source /etc/environment

# Print a message indicating that the script has finished
echo "Environment variables updated"

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