#!/bin/bash

# install/upgrade snapd
if [ -f /vagrant/config/mirror/archive.ubuntu.com ]; then
  MIRROR_URL=`cat /vagrant/config/mirror/archive.ubuntu.com | grep -v "^ *#" | xargs -n1 | tail -1`
  if [ -n $MIRROR_URL ]; then
    sed "s@http[^ ]*@$MIRROR_URL@" -i /etc/apt/sources.list
  fi
fi

apt-get update && apt-get install -y snapd dos2unix
systemctl restart snapd

# snap install microk8s
CONFIG="FALSE"
QUERY=`snap list microk8s 2>&1`
if [ `echo $QUERY | grep -q "error"; echo $?` -eq 0 ]; then
  echo "Start installing microk8s ..."
  CORE_SNAP=`ls -1 /vagrant/offline/core*.snap 2>/dev/null| xargs -n1 | tail -1`
  MICROK8S_SNAP=`ls -1 /vagrant/offline/microk8s*.snap 2>/dev/null | xargs -n1 | tail -1`

  if [ "$CORE_SNAP" != "" ] && [ "$MICROK8S_SNAP" != "" ]; then
    CORE_ASSERT="${CORE_SNAP%.snap}.assert"
    if ls -1 "$CORE_ASSERT" 2>/dev/null >/dev/null; then
      snap ack "$CORE_ASSERT"
      snap install "$CORE_SNAP"
    else
      snap install "$CORE_SNAP" --dangerous
    fi

    MICROK8S_ASSERT="${MICROK8S_SNAP%.snap}.assert"
    if ls -1 "$MICROK8S_ASSERT" 2>/dev/null >/dev/null; then
      snap ack "$MICROK8S_ASSERT"
      snap install "$MICROK8S_SNAP" --classic
    else
      snap install "$MICROK8S_SNAP" --classic --dangerous
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
  ## https://github.com/ubuntu/microk8s/issues/382
  #  From release 1.14 containerd replaced dockerd
  MICROK8S_VER=`snap list microk8s | awk '{print $2}' | xargs -n1 | tail -1 | sed 's/[a-z]*//'`
  if [ `awk -v ver="$MICROK8S_VER" 'BEGIN {print (ver<1.14)?"YES":"NO"}'` = "YES" ]; then
    dos2unix /vagrant/postinstall_with_dockerd.sh
    source /vagrant/postinstall_with_dockerd.sh
    postinstall_with_dockerd
  else
    dos2unix /vagrant/postinstall_with_containerd.sh
    source /vagrant/postinstall_with_containerd.sh
    postinstall_with_containerd
  fi
fi
