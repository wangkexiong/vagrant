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

postinstall_with_containerd () {
  snap alias microk8s.kubectl kubectl

  # DOCKER registry mirrors
  DOCKERIO_MIRROR=$(extract_mirror /vagrant/config/mirror/docker.io)
  GCRIO_MIRROR=$(extract_mirror /vagrant/config/mirror/gcr.io)
  K8SGCR_MIRROR=$(extract_mirror /vagrant/config/mirror/k8s.gcr.io)
  QUAYIO_MIRROR=$(extract_mirror /vagrant/config/mirror/quay.io)

  # containerd configuration for microk8s
  CONFIG_FILE="/var/snap/microk8s/current/args/containerd-template.toml"

  if [ "$GCRIO_MIRROR" != "" ] && [ "$K8SGCR_MIRROR" == "" ]; then
    sed -i 's/k8s\.gcr\.io/gcr\.io\/google_containers/' "$CONFIG_FILE"
  fi

  CONFIG_TEMPLATE=`cat $CONFIG_FILE | grep -A1 "plugins.cri.registry.mirrors.\"docker.io\""`
  MIRROR_CONFIG=
  if [ "$DOCKERIO_MIRROR" != "" ]; then
    MIRROR_CONFIG=`echo "$CONFIG_TEMPLATE" | sed "s,endpoint.*,endpoint = [\"$DOCKERIO_MIRROR\"]",`
  fi
  if [ "$GCRIO_MIRROR" != "" ]; then
    MIRROR_CONFIG="$MIRROR_CONFIG"`echo -e "\n$CONFIG_TEMPLATE" | sed 's/docker\.io/gcr\.io/' | sed "s,endpoint.*,endpoint = [\"$GCRIO_MIRROR\"]",`
  fi
  if [ "$K8SGCR_MIRROR" != "" ]; then
    MIRROR_CONFIG="$MIRROR_CONFIG"`echo -e "\n$CONFIG_TEMPLATE" | sed 's/docker\.io/k8s\.gcr\.io/' | sed "s,endpoint.*,endpoint = [\"$K8SGCR_MIRROR\"]",`
  fi
  if [ "$QUAYIO_MIRROR" != "" ]; then
    MIRROR_CONFIG="$MIRROR_CONFIG"`echo -e "\n$CONFIG_TEMPLATE" | sed 's/docker\.io/quay\.io/' | sed "s,endpoint.*,endpoint = [\"$QUAYIO_MIRROR\"]",`
  fi

  cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
  MIRROR_CONFIG=`echo "$MIRROR_CONFIG" | tr '\n' '\r'`
  cat "$CONFIG_FILE.bak" | tr '\n' '\r' | sed -e "s,[ ]*\[plugins.cri.registry.mirrors.\"docker.io\"\]\r[ ]*endpoint = \[[^]]*\]\r,$MIRROR_CONFIG," | tr '\r' '\n' > "$CONFIG_FILE"
  rm -rf "$CONFIG_FILE.bak"

  systemctl daemon-reload
  systemctl restart snap.microk8s.daemon-containerd
}