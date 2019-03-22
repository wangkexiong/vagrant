#!/bin/sh

if [ "$(ls /vagrant/config/etc/yum.repos.d/nokia*.repo 2>/dev/null)" ]; then
  cp /vagrant/config/etc/yum.repos.d/nokia*.repo /etc/yum.repos.d/.
  yumnok='yum --disablerepo=* --enablerepo=nokia*'
  $yumnok install -y docker-ce kubeadm kubelet kubectl
else
  # Add docker-ce repo
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  # Add Kubernetes repo
  cat <<-EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el\$releasever-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
  yum install -y docker-ce kubeadm kubelet kubectl
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

systemctl daemon-reload
systemctl enable docker
systemctl restart docker
systemctl enable kubelet
systemctl restart kubelet
