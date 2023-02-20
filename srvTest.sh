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