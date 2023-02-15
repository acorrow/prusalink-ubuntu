# prusalink-ubuntu
Automated setup of a PrusaLink system on Ubuntu Server

NOTE: You will need to generate a GitHub Access Token. This will allow the script here to make a call to add your SSH Key from the Ubuntu server to GitHub, so you can SSH Clone Repos.

Simply run the following command to use this script (Replace `MY_GITHUB_ACCESS_TOKEN` with your actual token generated above):

`sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/acorrow/prusalink-ubuntu/main/setup.sh)" -- "$MY_GITHUB_ACCESS_TOKEN"`

