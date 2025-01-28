#!/bin/sh

USERS="vagrant"

if [ -f /vagrant/config/system/accounts ]; then
  USERS="`echo $(cat /vagrant/config/system/accounts | grep -v "^ *#" | awk -F: '{print $1}') | tr -d '\r\n'` $USERS"
fi

GROUP=
PASSWORD=
for USER in `echo $USERS | tr ' ' '\n'`; do
  if id $USER>/dev/null 2>/dev/null; then
    GROUP=`id -gn $USER`

    # Prepare the vncserver configuration files
    mkdir -p /home/$USER/.vnc

    touch /home/$USER/.vnc/config
    touch /home/$USER/.vnc/xstartup
    PASSWORD="123456"
    if [ -f /vagrant/config/system/vnc_passwd ]; then
      PASSWORD=`cat /vagrant/config/system/vnc_passwd`
    fi
    echo $PASSWORD | vncpasswd -f > /home/$USER/.vnc/passwd

    chown -R $USER:$GROUP /home/$USER/.vnc
    chmod 700 /home/$USER/.vnc
    chmod 600 /home/$USER/.vnc/passwd
    chmod 755 /home/$USER/.vnc/xstartup

    cat <<-EOF > /home/$USER/.vnc/xstartup
#!/bin/sh

# Uncomment the following two lines for normal desktop:
# unset SESSION_MANAGER
# exec /etc/X11/xinit/xinitrc

[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r \$HOME/.Xresources ] && xrdb \$HOME/.Xresources

# vncconfig -iconic &
xsetroot -solid grey &
autocutsel -fork &
x-terminal-emulator -geometry 80x24+10+10 &
startxfce4 &
EOF

    cat <<-EOF > /home/$USER/.vnc/config
#PARAM="-geometry 1680x1050"
EOF

  fi
done

# Manage vncserver by systemd
# https://gist.github.com/spinxz/1692ff042a7cfd17583b

cat <<-EOF > /lib/systemd/system/vncserver.service
[Unit]
Description=VNC Server

[Service]
# Don't run as a deamon (because we've got nothing to do directly)
Type=oneshot

# Just print something, because ExecStart is required
ExecStart=/bin/echo "App Service exists only to collectively start and stop App instances"

# Keep running after Exit start finished, because we want the instances that depend on this to keep running
RemainAfterExit=yes
StandardOutput=journal
EOF

cat <<-EOF > /lib/systemd/system/vncserver@.service
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target
PartOf=vncserver.service

[Service]
Type=forking
User=%i
Environment="DISPLAY=\$(/bin/ps f -u %i | /bin/grep -v grep | /bin/grep Xtightvnc | /usr/bin/awk '{print \$6}')"
EnvironmentFile=-/home/%i/.vnc/config

ExecStartPre=/bin/bash -c 'if [ -n "\${DISPLAY}" ]; then /usr/bin/vncserver -kill \${DISPLAY}; fi'
ExecStart=/usr/bin/vncserver -geometry 1280x720 -depth 24 -alwaysshared \$PARAM
ExecStop=/bin/bash -c 'if [ -n "\${DISPLAY}" ]; then /usr/bin/vncserver -kill \${DISPLAY}; fi'

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
