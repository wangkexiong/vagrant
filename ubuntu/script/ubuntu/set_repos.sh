#!/bin/sh

# ubuntu mirrors
if [ -f /vagrant/config/mirror/archive.ubuntu.com ]; then
  MIRROR_URL=`cat /vagrant/config/mirror/archive.ubuntu.com | grep -v "^ *#" | xargs -n1 | tail -1 | tr -d " \r\n"`
  if [ -n $MIRROR_URL ]; then
    sed "s@http[^ ]*@$MIRROR_URL@" -i /etc/apt/sources.list
  fi
fi

# docker-ce
DOCKER_URL="https://download.docker.com"

if [ -f /vagrant/config/mirror/download.docker.com ]; then
  MIRROR_URL=`cat /vagrant/config/mirror/download.docker.com | grep -v "^ *#" | xargs -n1 | tail -1 | tr -d " \r\n"`

  if [ -n $MIRROR_URL ]; then
    DOCKER_URL="$MIRROR_URL"
  fi
fi

curl -fsSL "$DOCKER_URL/linux/ubuntu/gpg" | sudo apt-key add -
echo "deb [arch=amd64] $DOCKER_URL/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update