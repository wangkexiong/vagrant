#!/bin/sh

# Avoid provision trigger again
if [ -f /root/.kubeadm_init ]; then
  if [ -n "$1" ]; then
    rm -rf /etc/kubernetes/pki/apiserver.*
    kubeadm init phase certs all --apiserver-cert-extra-sans="$1"
    DOCKER_CONTAINER=`docker ps -q -f 'name=k8s_kube-apiserver*'`
    if [ ${#DOCKER_CONTAINER} -ne 0 ]; then
      docker rm -f $DOCKER_CONTAINER
      systemctl restart kubelet
    fi
  fi
else
  # Disable mail and rpcbind
  systemctl stop postfix
  systemctl disable postfix
  systemctl stop rpcbind
  systemctl disable rpcbind

  # Disable SELinux
  setenforce 0
  sed -i --follow-symlinks 's/^SELINUX=[a-z]*/SELINUX=disabled/g' /etc/sysconfig/selinux

  # Disable swap
  swapoff -a
  sed -i -E 's/(^[^#].*swap.*swap.*)/#\1/g' /etc/fstab

  # Enable br_netfilter
  modprobe br_netfilter
  echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
  echo '1' > /proc/sys/net/bridge/bridge-nf-call-ip6tables

  # Will use flannel as network, define pod-network-cidr
  KUBEADM_CMD="kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=0.0.0.0"

  # See if we have gcr.io mirror site
  if [ -f /vagrant/config/mirror/k8s.gcr.io ]; then
    MIRROR_URL=`cat /vagrant/config/mirror/k8s.gcr.io | grep -v "^ *#" | xargs -n1 | tail -1`
    if [ "$MIRROR_URL" != "" ]; then
      MIRROR_URL=`echo $MIRROR_URL | sed 's/http[s]*:\/\///' | sed 's/\/$//'`
      KUBEADM_CMD="$KUBEADM_CMD --image-repository $MIRROR_URL"
    fi
  fi

  # Extra Subject Alternative Names (SANs) to use for the API Server serving certificate.
  SANS_IP=`ip addr | grep inet | grep -v inet6 | awk '{print $2}' | awk -F/ '{print $1}' | paste -s -d,`
  if [ -n "$1" ]; then
    SANS_IP="$SANS_IP,$1"
  fi
  KUBEADM_CMD="$KUBEADM_CMD --apiserver-cert-extra-sans=$SANS_IP"

  # Invoke the kubeadm init command
  $KUBEADM_CMD

  # Cluster configuration for kubectl
  mkdir -p /root/.kube
  mkdir -p /home/vagrant/.kube
  cp /etc/kubernetes/admin.conf /root/.kube/config
  sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  chown root:root /root/.kube/config
  sudo chown vagrant:vagrant /home/vagrant/.kube/config

  # If want to use private registry, download the yml first and replace images with private registry ones
  if [ -f /vagrant/config/kubeadm/kube-flannel.yml ]; then
    kubectl apply -f /vagrant/config/kubeadm/kube-flannel.yml
  else
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  fi

  # Remove master isolation
  kubectl taint nodes --all node-role.kubernetes.io/master-

  # Touch finished flag
  touch /root/.kubeadm_init
fi
