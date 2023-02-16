DIRECTORY="/etc/systemd/system"
FILE="prusa-link.service"
CONTENT="[Unit]
Description=Prusa Link Service
After=network.target

[Service]
ExecStart=/bin/bash -c \"/usr/sbin/iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 8080; /usr/sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080; printf 'M117 Starting Prusa Link\n' > /dev/ttyAMA0; rm -f /home/pi/prusa-link.pid; export PYTHONOPTIMIZE=2; su pi -c '/home/pi/.local/bin/prusa-link -i start'\"
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target"
if [ ! -d "$DIRECTORY" ]; then
  mkdir -p "$DIRECTORY"
fi
if [ -f "$DIRECTORY/$FILE" ]; then
  rm "$DIRECTORY/$FILE"
fi
echo -e "$CONTENT" >"$DIRECTORY/$FILE"

# Reload the systemd daemon and start the service
systemctl daemon-reload
systemctl start prusa-link.service

# Enable the service to start at boot
systemctl enable prusa-link.service
