#!/bin/bash
GHT=$1
#Setup USB Access to printer:
#generate ssh key and export public key to term
if [ ! -e ~/.ssh/id_rsa ]; 
    echo "No SSH Key exists on this machine. Generating..."
    then ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa; 
fi
echo "Exporting SSH Key to GitHub"
sshKey=$(cat ~/.ssh/id_rsa.pub)
#Setup a GitHub SSH key so you can easily clone the repos...
if [ -z "$GHT" ]; then
    echo "Skipping the SSH Key add to Git Hub. Hope you already have one...."
else
    echo $sshKey
    http --print BbHh --form POST https://api.github.com/user/keys \
        Authorization:"token $GHT" \
        title="prusaLinkSSHKey" \
        key="$sshKey"
    #curl -X POST -H "Authorization: token $GHT" -d "{"title":"prusaLinkSSHKey","key":"$sshKey"}" https://api.github.com/user/keys
fi
