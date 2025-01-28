#!/bin/bash

## https://github.com/ubuntu/microk8s/pull/441
#  If without above work, kubectl need to use with --insecure-skip-tls-verify
CSR_CONF=/var/snap/microk8s/current/certs/csr.conf.template
if [ -f "$CSR_CONF" ]; then
  if [ -n "$1" ]; then
    SANS_IP=`cat "$CSR_CONF" | grep IP\.10`
    if [ "$SANS_IP" == "" ]; then
      sed -i "s,#MOREIPS,#MOREIPS\nIP\.10 = $1," "$CSR_CONF"
    else
      sed -i "s,IP\.10.*,IP\.10 = $1," "$CSR_CONF"
    fi
  fi
fi

## https://gist.github.com/borkmann/84812fcac624fb659f66f0d514faa1c8#problems-deploying-cilium-daemon-set
#  To make Daemonset configuration working with microk8s...
APISERVER_CONF=/var/snap/microk8s/current/args/kube-apiserver
if ! `grep -q "^\-\-allow-privileged$" "$APISERVER_CONF"`; then
  echo "--allow-privileged" >> "$APISERVER_CONF"
  systemctl restart snap.microk8s.daemon-apiserver.service
fi