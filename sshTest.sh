#!/bin/bash
GHT=$1
#Setup USB Access to printer:
#generate ssh key and export public key to term
if [ -z "$GHT" ]; then
    echo "Skipping the SSH Key add to Git Hub. Hope you already have one...."
else
    if stat /root/.ssh/id_rsa >/dev/null 2>&1; then
        echo "SSH Key already exists. Just export it to GitHub"
    else
        echo "No SSH Key exists on this machine. Generating..."
        ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa
    fi
    echo "Exporting SSH Key to GitHub"
    sshKey=$(cat /root/.ssh/id_rsa.pub)
    existingId=$(curl -s -X GET -H "Authorization: token $GHT" https://api.github.com/user/keys | jq -r '.[] | select(.title == "prusaLinkSSHKey") | .id')
    if [ ! -z"$existingId" ]; then
        echo "SSHKey with this name already exists. Deleting it."
        curl -s -X DELETE -H "Authorization: token $GHT" https://api.github.com/user/keys/$existingId
    fi
fi
curl -X POST -H "Authorization: token $GHT" https://api.github.com/user/keys -d "{\"title\":\"prusaLinkSSHKey\",\"key\":\"$sshKey\"}"
