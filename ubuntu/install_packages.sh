#!/bin/sh

### Unattended settings
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
>/tmp/preseeding.conf

# lightdm
cat <<-EOF >> /tmp/preseeding.conf
lightdm shared/default-x-display-manager        select  lightdm
EOF

# Apply preseeding configuration
debconf-set-selections /tmp/preseeding.conf

### Start the installation
PKG_LIST=

for dat in `ls -1 /vagrant/config/package/common/*.dat 2>/dev/null`; do
  PKG_LIST="`echo $(cat $dat | grep -v "^ *#") | tr -d '\r\n'` $PKG_LIST"
done

dat="/vagrant/config/package/`lsb_release -cs`.dat"
if [ -f "$dat" ]; then
  PKG_LIST="`echo $(cat $dat | grep -v "^ *#") | tr -d '\r\n'` $PKG_LIST"
fi

if [ -n "$PKG_LIST" ]; then
  echo "$PKG_LIST" | xargs -i sh -c "yes y | apt-get install {}"
fi

### Above unattend code is NOT always working...
for PKG in `echo $PKG_LIST | tr " " "\n"`; do
  if [ "x$PKG" = "xlightdm" ]; then
    echo "lightdm shared/default-x-display-manager select lightdm" > /tmp/preseeding.conf
    debconf-set-selections /tmp/preseeding.conf
    rm -rf /etc/X11/default-display-manager
    rm -rf /etc/systemd/system/display-manager
    dpkg-reconfigure lightdm

    break
  fi
done

### Offline downloaded deb installation packages
for PKG in `ls -1 /vagrant/offline/*.deb 2>/dev/null`; do
  PKG_NAME=`dpkg --info "$PKG" | grep Package: | awk '{print $2}'`

  if ! dpkg -s "$PKG_NAME" 2>/dev/null | grep "Status:.*installed.*" >/dev/null; then
    dpkg -i "$PKG"
  fi
done
