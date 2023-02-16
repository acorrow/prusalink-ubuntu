ServiceDir="/etc/systemd/system"
ServiceFile="prusa-link.service"

if [ ! -d "$ServiceDir" ]; then
  mkdir -p "$ServiceDir"
fi
if [ -f "$ServiceDir/$ServiceFile" ]; then
  rm "$ServiceDir/$ServiceFile"
fi
echo -e "$CONTENT" >"$ServiceDir/$ServiceFile"

file="$ServiceDir/$ServiceFile"
{ 
    echo "[Unit]";
    echo "Description=Prusa Link Service";
    echo "";
    echo "[Service]";
    echo "ExecStart=/bin/bash -c /usr/sbin/iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 8080; /usr/sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080; printf 'M117 Starting Prusa Link\n' > /dev/ttyAMA0; rm -f /home/pi/prusa-link.pid; export PYTHONOPTIMIZE=2; su pi -c '/home/pi/.local/bin/prusa-link -i start'";
    echo "Type=oneshot";
    echo "RemainAfterExit=yes";
    echo "[Install]";
    echo "WantedBy=multi-user.target";
  
} | sudo tee $file



# Reload the systemd daemon and start the service
systemctl daemon-reload
systemctl start prusa-link.service

# Enable the service to start at boot
systemctl enable prusa-link.service
