#!/bin/sh

if [ "$(ls /vagrant/config/etc/yum.repos.d/*.repo 2>/dev/null)" ]; then
  yum clean all

  if [ -d /etc/yum.repos.d/original ]; then
    rm -rf /etc/yum.repos.d/*.repo
  else
    mkdir -p /etc/yum.repos.d/original
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/original/.
  fi
  cp /vagrant/config/etc/yum.repos.d/*.repo /etc/yum.repos.d/.
fi
REPO_LISTS=`yum list`

if [ `echo "$REPO_LISTS" | egrep "^docker-ce\." | wc -l` -eq 0 ]; then
  # Add docker-ce repo
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
fi

yum install -y docker-ce
if [ $? -ne 0 ]; then
  cp /etc/yum.repos.d/original/*.repo /etc/yum.repos.d/.
  yum install -y docker-ce
fi

# HACK for docker-ce working with vagrant-proxyconf
# Enable TCP connection (NO TLS for easy testing...)
mkdir -p /etc/systemd/system/docker.service.d
cat <<-EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
EnvironmentFile=-/etc/sysconfig/docker
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
EOF

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
systemctl enable docker
systemctl restart docker