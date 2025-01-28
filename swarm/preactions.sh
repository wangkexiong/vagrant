#!/bin/sh

# Dump guest VM IPs before configuration
WORKING_DIR=/vagrant/exchange/hosts
mkdir -p $WORKING_DIR
HOST_FILE="$WORKING_DIR/$HOSTNAME"
ip addr | grep 'inet\b' | awk '{print $2}' | cut -d/ -f1 | sort > "$HOST_FILE"

# Enable SSH key authentication
mkdir -p  /root/.ssh /home/vagrant/.ssh
chmod 700 /root/.ssh /home/vagrant/.ssh

WORKING_DIR=/vagrant/exchange/ssh
if [ ! -d $WORKING_DIR ]; then
  mkdir -p $WORKING_DIR
  yes y | ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
  cp -p /root/.ssh/id_rsa* $WORKING_DIR/.
else
  cp -p $WORKING_DIR/id_rsa* /root/.ssh/.
  chown root:root /root/.ssh/id_rsa*
  chmod 600 /root/.ssh/id_rsa
  chmod 644 /root/.ssh/id_rsa.pub
fi

KEY=`cat /root/.ssh/id_rsa.pub`
touch /root/.ssh/authorized_keys
if ! grep -q "$KEY" /root/.ssh/authorized_keys; then
  echo $KEY >> /root/.ssh/authorized_keys
fi

cp -p /root/.ssh/id_rsa* /home/vagrant/.ssh/.
chown -R vagrant:vagrant /home/vagrant/.ssh/.

touch /home/vagrant/.ssh/authorized_keys
if ! grep -q "$KEY" /home/vagrant/.ssh/authorized_keys; then
  echo $KEY >> /home/vagrant/.ssh/authorized_keys
fi
