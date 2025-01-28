#!/bin/sh

TZ="Asia/Shanghai"

# https://bugs.launchpad.net/ubuntu/+source/tzdata/+bug/1554806
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=813226#10

echo "$TZ" > /etc/timezone
rm -rf /etc/localtime

dpkg-reconfigure -f noninteractive tzdata

### Unattend preseeding way
# DEBIAN_FRONTEND=noninteractive
# DEBCONF_NONINTERACTIVE_SEEN=true
# echo "tzdata tzdata/Areas select Asia" > /tmp/preseeding.conf
# echo "tzdata tzdata/Zones/Asia select Shanghai" >> /tmp/preseeding.conf
# debconf-set-selections /tmp/preseeding.conf
# rm -rf /etc/timezone
# rm -rf /etc/localtime
# dpkg-reconfigure tzdata