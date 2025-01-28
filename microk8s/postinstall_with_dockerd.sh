#!/bin/bash

extract_mirror () {
  MIRROR_URL=
  if [ -f "$1" ]; then
    MIRROR_URL=`cat "$1" | grep -v "^ *#" | xargs -n1 | tail -1`
    if [ "$MIRROR_URL" != "" ]; then
      if [ ${MIRROR_URL:0:7} != http:// ] && [ ${MIRROR_URL:0:8} != https:// ]; then
        MIRROR_URL=https://$MIRROR_URL
      fi
    fi
  fi
  echo "$MIRROR_URL" | tr -d '\r\n'
}

postinstall_with_dockerd () {
  snap alias microk8s.kubectl kubectl
  snap alias microk8s.docker docker

  # HACK: rename docker service for vagrant-proxyconf
  systemctl disable snap.microk8s.daemon-docker
  systemctl stop snap.microk8s.daemon-docker
  mv /etc/systemd/system/snap.microk8s.daemon-docker.service /lib/systemd/system/docker.service

  # Change MAX fd for containers
  # HACK: POD inter-connecting... https://github.com/ubuntu/microk8s/issues/72
  mkdir -p /etc/systemd/system/docker.service.d
  cat <<-EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
LimitNOFILE=65536
ExecStartPost=/sbin/iptables -P FORWARD ACCEPT -w
EOF

  # Enable TCP connection (NO TLS for easy testing...)
  if [ -f /var/snap/microk8s/current/args/dockerd ]; then
    if [ `grep "tcp://0.0.0.0:2375" /var/snap/microk8s/current/args/dockerd > /dev/null; echo $?` -ne 0 ]; then
      echo "-H tcp://0.0.0.0:2375" >> /var/snap/microk8s/current/args/dockerd
    fi
  fi

  # docker.io MIRROR
  if [ -f /var/snap/microk8s/current/args/docker-daemon.json ]; then
    if [ -f /vagrant/config/mirror/docker.io ]; then
      DOCKERIO_MIRROR=$(extract_mirror /vagrant/config/mirror/docker.io)
      if [ "$DOCKERIO_MIRROR" != "" ]; then
        REGISTRY_CONF="  \"registry-mirrors\": [\"$DOCKERIO_MIRROR\"]"
        sed -i 's/]/],/' /var/snap/microk8s/current/args/docker-daemon.json
        sed -i "s,},$REGISTRY_CONF\n}," /var/snap/microk8s/current/args/docker-daemon.json
      fi
    fi
  fi

  systemctl enable docker
  ln -s /etc/systemd/system/docker.service /etc/systemd/system/snap.microk8s.daemon-docker.service
  systemctl daemon-reload
  systemctl restart docker
}