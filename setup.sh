#!/bin/bash
#Setup USB Access to printer:
GHT=$1
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
    then ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa; 
fi
sshKey=$(cat ~/.ssh/id_rsa.pub)
#Setup a GitHub SSH key so you can easily clone the repos...
GHT="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"
curl -X POST -H "Authorization: token $GHT" -d "{"title":"prusaLinkSSHKey","key":"$sshKey"}" https://api.github.com/user/keys
##TODO Remove Welcome Message
git clone git@github.com:prusa3d/Prusa-Link.git
git clone https://github.com/prusa3d/Prusa-Connect-SDK-Printer

#Install some libraries that will be needed for prusaLink and connect
sudo apt-get install jp2a libturbojpeg0-dev libcap-dev
sudo apt install python3-pip
sudo apt install neofetch
#git clone both repos



#theme items
#prompt color
#bashrc PS1 variable = prompt colors