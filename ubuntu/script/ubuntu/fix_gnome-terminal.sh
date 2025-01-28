#!/bin/sh

# https://bugs.launchpad.net/ubuntu/+source/gnome-terminal/+bug/1474927
locale-gen --purge >/dev/null
localectl set-locale LANG=en_US.utf8