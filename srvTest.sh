systemctl stop prusa-link.service
systemctl stop wlan0-redirect.service
systemctl stop eth0-redirect.service

sudo rm /etc/systemd/system/prusa-link.service
sudo rm /etc/systemd/system/wlan0-redirect.service
sudo rm /etc/systemd/system/eth0-redirect.service

ServiceDir="/etc/systemd/system"

sudo tee "/etc/systemd/system/prusa-link.service" > /dev/null <<EOF
[Unit]
Description=Prusa Link Service
After=network.target

[Service]
ExecStart=/home/pi/.local/bin/prusa-link -i start
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo tee "/etc/systemd/system/wlan0-redirect.service" > /dev/null <<EOF
[Unit]
Description=IPTables Redirect Service
After=network.target

[Service]
ExecStart=/usr/sbin/iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 8080
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo tee "/etc/systemd/system/eth0-redirect.service" > /dev/null <<EOF
[Unit]
Description=IPTables Redirect Service
After=network.target

[Service]
ExecStart=/usr/sbin/iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF




# Reload the systemd daemon and start the service
systemctl daemon-reload
systemctl start wlan0-redirect.service
systemctl start eth0-redirect.service
systemctl start prusa-link.service

# Enable the service to start at boot
systemctl enable prusa-link.service
systemctl enable eth0-redirect.service
systemctl enable wlan0-redirect.service
