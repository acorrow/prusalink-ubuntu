#!/bin/bash
GHT=$1
#Setup USB Access to printer:
#generate ssh key and export public key to term

if stat /root/.ssh/id_rsa >/dev/null 2>&1; then
    echo "The file exists"
else
    echo "No SSH Key exists on this machine. Generating..."
    ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa
fi

# if [ ! -f /root/.ssh/id_rsa ]; then
#     echo "No SSH Key exists on this machine. Generating..."
#     ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa
# fi
echo "Exporting SSH Key to GitHub"
sshKey=$(cat ~/.ssh/id_rsa.pub)
#Setup a GitHub SSH key so you can easily clone the repos...
if [ -z "$GHT" ]; then
    echo "Skipping the SSH Key add to Git Hub. Hope you already have one...."
else
    http --form POST https://api.github.com/user/keys \
        Authorization:"token $GHT" \
        title="prusaLinkSSHKey" \
        key="$sshKey"
    #curl -X POST -H "Authorization: token $GHT" -d "{"title":"prusaLinkSSHKey","key":"$sshKey"}" https://api.github.com/user/keys
fi
