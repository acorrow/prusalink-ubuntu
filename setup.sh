#!/bin/bash
cd /opt

#Install some libraries that will be needed for prusaLink and connect
sudo apt-get install -y --force-yes jp2a libturbojpeg0-dev libcap-dev
sudo apt install -y --force-yes python3-pip
sudo apt install -y neofetch

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
echo -e "$CONTENT" >"$DIRECTORY/$FILE"

if [ -z "$GHT" ]; then
  echo "Skipping the SSH Key add to Git Hub. Hope you already have one, if not this shit's about to FAIL!"
else
  ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
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
git clone https://github.com/prusa3d/Prusa-Connect-SDK-Printer


#Prompt Color
#bashrc PS1 variable = prompt colors
#[38;5;208m\]
#That is the color we need to grep/replace in the PS1 for Ubuntu bash...

#Actually install Prusa-Link
sudo PIP_NO_WARN_SCRIPT_LOCATION=1 pip3 install Prusa-Connect-SDK-Printer Prusa-Link

# Define the systemd service
