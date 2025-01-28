#!/bin/sh

### https://metinsaylan.com/8991/how-to-change-screen-resolution-on-ubuntu-18-04-in-hyper-v/
# This change requires reboot machine to work
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash video=hyperv_fb:1280x720"/' /etc/default/grub
update-grub 2>/dev/null
