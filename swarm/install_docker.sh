#!/bin/sh

if [ "$(ls /vagrant/config/etc/yum.repos.d/nokia*.repo 2>/dev/null)" ]; then
  cp /vagrant/config/etc/yum.repos.d/nokia*.repo /etc/yum.repos.d/.
  yumnok='yum --disablerepo=* --enablerepo=nokia*'
  $yumnok install -y docker-ce
else
  # Add docker-ce repo
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install -y docker-ce
fi

# HACK for docker-ce proxyconf
# Enable TCP connection (NO TLS for easy testing...)
mkdir -p /etc/systemd/system/docker.service.d
cat <<-EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
EnvironmentFile=-/etc/sysconfig/docker
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
EOF

# Docker registry mirror
if [ -f /vagrant/config/mirror/docker/docker.io ]; then
  MIRROR_URL=`cat /vagrant/config/mirror/docker/docker.io`
  mkdir -p /etc/docker
  cat <<-EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["$MIRROR_URL"]
}
EOF
else
  rm -rf /etc/docker/daemon.json
fi

# Enable Docker service
systemctl daemon-reload
systemctl enable docker
systemctl restart docker