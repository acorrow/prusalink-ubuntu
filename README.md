# prusalink-ubuntu
## Automated PrusaLink Ubuntu Setup

NOTE: You will need to generate a GitHub Access Token. This will allow the script here to make a call to add your SSH Key from the Ubuntu server to GitHub, so you can SSH Clone Repos.

### setup.sh

Simply run the following command to use this script (Replace `MY_GITHUB_ACCESS_TOKEN` with your actual token generated above):

`sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/acorrow/prusalink-ubuntu/main/setup.sh)" -- "$MY_GITHUB_ACCESS_TOKEN"`

### img2neo.sh

This script will take a PNG/JPG and rasterize it into ASCII art that is colorable via Neofetch. Specifically, normal ANSI art might have a series of escaped color sequences to display. Whereas Neofetch uses a custom format. This script uses image conversion to ANSI colors, and extracts them into the format Neofetch is using.

Usage:
`img2neo.sh [file.png] [numberOfLines] [colorDepth]`
Example:
`img2neo.sh somePng.png 20 4`

The numberOfLines simply limits the size of the file. 20 is generally good, but depending on your overall Neofetch setup, you might want to use something different.

This creates a file called `asciiLogo.txt` in the directory it was run in.