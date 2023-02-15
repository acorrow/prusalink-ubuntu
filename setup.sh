#!/bin/bash
#Setup USB Access to printer:

#Flags for testing
devMode=false;
if [ "$devMode" = true ]; then
  echo "Test Mode"
else
  echo "Setting up Prusa Link For Ubuntu"
fi
GHT=$1
if [ -z "$GHT" ]; then
  echo "Warning! No GitHub Token supplied!"
    if [ "$devMode" = true ]; then
        echo "But... You are in TestMode so whatever..."
    else
        echo "Exiting..."
        exit;
    fi
else
  echo "This script will create (or use) your SSH key with GitHub"
fi

echo "Setting up etc/Prusa-Link/prusa-link.ini - This allows for USB access to the Printer"

DIRECTORY="/etc/Prusa-Link"
FILE="prusa-link.ini"
CONTENT="[printer]\nport=/dev/ttyACM0\nbaudrate=115200"
if [ ! -d "$DIRECTORY" ]; then
  mkdir -p "$DIRECTORY"
fi
if [ -f "$DIRECTORY/$FILE" ]; then
  rm "$DIRECTORY/$FILE"
fi
echo -e "$CONTENT" > "$DIRECTORY/$FILE"

#generate ssh key and export public key to term
if [ ! -f ~/.ssh/id_rsa ]; 
    echo "No SSH Key exists on this machine. Generating..."
    then ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa; 
fi
echo "Exporting SSH Key to GitHub"
sshKey=$(cat ~/.ssh/id_rsa.pub)
#Setup a GitHub SSH key so you can easily clone the repos...
if [ -z "$GHT" ]; then
    echo "Skipping the SSH Key add to Git Hub. Hope you already have one...."
else
    curl -X POST -H "Authorization: token $GHT" -d "{"title":"prusaLinkSSHKey","key":"$sshKey"}" https://api.github.com/user/keys
fi

##TODO Remove Welcome Message

git clone git@github.com:prusa3d/Prusa-Link.git
git clone https://github.com/prusa3d/Prusa-Connect-SDK-Printer

#Install some libraries that will be needed for prusaLink and connect
sudo apt-get install jp2a libturbojpeg0-dev libcap-dev
sudo apt install python3-pip
sudo apt install neofetch

#Prompt Color
#bashrc PS1 variable = prompt colors
#[38;5;208m\]
#That is the color we need to grep/replace in the PS1 for Ubuntu bash...


#Actually install Prusa-Link
sudo pip3 install Prusa-Connect-SDK-Printer/.
sudo pip3 install Prusa-Link/.


# Define the systemd service
cat > /etc/systemd/system/prusa-link.service << EOF
[Unit]
Description=Prusa Link Service
After=network.target

[Service]
ExecStart=/bin/bash -c "/usr/sbin/iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 8080; /usr/sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080; printf 'M117 Starting Prusa Link\n' > /dev/ttyAMA0; rm -f /home/pi/prusa-link.pid; export PYTHONOPTIMIZE=2; su pi -c '/home/pi/.local/bin/prusa-link -i start'"
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload the systemd daemon and start the service
systemctl daemon-reload
systemctl start prusa-link.service

# Enable the service to start at boot
systemctl enable prusa-link.service