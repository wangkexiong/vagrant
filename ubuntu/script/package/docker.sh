#!/bin/sh

# Setting docker.io registry mirror
if [ -f /vagrant/config/mirror/docker.io ]; then
  MIRROR_URL=`cat /vagrant/config/mirror/docker.io | grep -v "^ *#" | xargs -n1 | tail -1 | tr -d '\r\n' | sed 's/\/$//'`
  if [ "$MIRROR_URL" != "" ]; then
    mkdir -p /etc/docker
    cat <<-EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["$MIRROR_URL"]
}
EOF
  else
    rm -rf /etc/docker/daemon.json
  fi
else
  rm -rf /etc/docker/daemon.json
fi

systemctl daemon-reload
systemctl restart docker