#!/bin/sh

### Use `systemd-analyze critical-chain x11vnc.service` to check starting order of x11vnc

### If unattended installation failed for display-manager settings
# https://bugs.launchpad.net/ubuntu/+source/gdm3/+bug/1616905
# Use the following tricky code
: <<'TRICKY_CODE'
cat <<-EOF > /etc/X11/default-display-manager
/usr/sbin/lightdm
EOF

ln -fs /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service
TRICKY_CODE
# !!!!! Above are all comments and will NOT executed...

### There some warning during the service up that would not impact the service running...
# https://bugs.launchpad.net/ubuntu/+source/lightdm/+bug/1309535
systemctl daemon-reload
systemctl start display-manager

#### Prepare the password file for vnc connection
PASSWORD="123456"
if [ -f /vagrant/config/system/vnc_passwd ]; then
  PASSWORD=`cat /vagrant/config/system/vnc_passwd`
fi
x11vnc -storepasswd $PASSWORD /etc/x11vnc.passwd

if ! `lsof -i :5900 >/dev/null`; then
  ### Enable x11vnc service
  cat <<-EOF > /lib/systemd/system/x11vnc.service
[Unit]
Description=Start x11vnc at startup.
Requires=display-manager.service
After=display-manager.service

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth /etc/x11vnc.passwd -rfbport 5900 -shared
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable x11vnc
  systemctl start x11vnc
fi
