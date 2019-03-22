#!/bin/bash

if [ -f /vagrant/config/mirror/archive.ubuntu.com ]; then
  MIRROR_URL=`cat /vagrant/config/mirror/archive.ubuntu.com`
  sed "s@http[^ ]*@$MIRROR_URL@" -i /etc/apt/sources.list
fi

apt-get update && apt-get install -y snapd
systemctl restart snapd

CONFIG="FALSE"
QUERY=`snap list microk8s 2>&1`
if [ `echo $QUERY | grep -q "error"; echo $?` -eq 0 ]; then
  echo "Start installing microk8s ..."
  if [ `ls -1 /vagrant/offline/*.snap | grep -E "core || microk8s" | wc -l` -eq 2 ]; then
    if ls -1 /vagrant/offline/core*.assert 2>/dev/null > /dev/null; then
      snap ack /vagrant/offline/core*.assert
      snap install /vagrant/offline/core*.snap
    else
      snap install /vagrant/offline/core*.snap --dangerous
    fi

    if ls -1 /vagrant/offline/microk8s*.assert 2>/dev/null > /dev/null; then
      snap ack /vagrant/offline/microk8s*.assert
      snap install /vagrant/offline/microk8s*.snap --classic
    else
      snap install /vagrant/offline/microk8s*.snap --classic --dangerous
    fi
  else
    snap install microk8s --classic
  fi

  CONFIG="TRUE"
fi

if [ `echo $QUERY | grep -q "disabled"; echo $?` -eq 0 ]; then
  echo "Enable microk8s ..."
  snap enable microk8s
  CONFIG="TRUE"
fi

if [ "$CONFIG" = "TRUE" ]; then
  snap alias microk8s.docker docker
  snap alias microk8s.kubectl kubectl

  # HACK: rename docker service for vagrant-proxyconf
  systemctl disable snap.microk8s.daemon-docker
  systemctl stop snap.microk8s.daemon-docker
  mv /etc/systemd/system/snap.microk8s.daemon-docker.service /lib/systemd/system/docker.service

  # Change MAX fd for containers
  mkdir -p /etc/systemd/system/docker.service.d
  cat <<-EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
LimitNOFILE=65536
EOF

  # Enable TCP connection (NO TLS for easy testing...)
  if [ -f /var/snap/microk8s/current/args/dockerd ]; then
    if [ `grep "tcp://0.0.0.0:2375" /var/snap/microk8s/current/args/dockerd > /dev/null; echo $?` -ne 0 ]; then
      echo "-H tcp://0.0.0.0:2375" >> /var/snap/microk8s/current/args/dockerd
    fi
  fi

  systemctl enable docker
  ln -s /etc/systemd/system/docker.service /etc/systemd/system/snap.microk8s.daemon-docker.service
  systemctl daemon-reload
  systemctl restart docker
fi
