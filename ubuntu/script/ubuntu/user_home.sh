#!/bin/sh

mkdir -p /mnt
mkdir -p /working

if ! grep /dev/sdb1 /etc/fstab >/dev/null; then
  if [ -b /dev/sdb1 ]; then
    FS_TYPE=`blkid -o value -s TYPE /dev/sdb1`
    cat <<-EOF >> /etc/fstab
/dev/sdb1               /mnt                    $FS_TYPE     defaults        0 0
EOF
  fi
fi

if ! grep /dev/sdc1 /etc/fstab >/dev/null; then
  if [ -b /dev/sdc1 ]; then
    FS_TYPE=`blkid -o value -s TYPE /dev/sdc1`
    cat <<-EOF >> /etc/fstab
/dev/sdc1               /working                $FS_TYPE     defaults        0 0
EOF
  elif [ -b /dev/sdc ]; then
    yes y | parted /dev/sdc mklabel msdos 2>/dev/null
    parted --align optimal /dev/sdc mkpart primary ext4 0% 100% 2>/dev/null
    mkfs.ext4 /dev/sdc1
    cat <<-EOF >> /etc/fstab
/dev/sdc1               /working                ext4         defaults        0 0
EOF
  fi
fi

mount -a

# Add group
GROUP=
GROUP_ID=
if [ -f /vagrant/config/system/groups ]; then
  for CONF in `cat /vagrant/config/system/groups | grep -v "^ *#" | sed -r '/^\s*$/d'`; do
    CONF=`echo $CONF | tr -d '\r\n'`
    GROUP=`echo $CONF | awk -F: '{print $1}'`
    GROUP_ID=`echo $CONF | awk -F: '{print $2}'`

    if ! grep -q ^$GROUP: /etc/group; then
      groupadd -g $GROUP_ID $GROUP
    fi
  done
fi

USER=
USER_ID=
PASSWORD=
if [ -f /vagrant/config/system/accounts ]; then
  for CONF in `cat /vagrant/config/system/accounts | grep -v "^ *#" | sed -r '/^\s*$/d'`; do
    CONF=`echo $CONF | tr -d '\r\n'`
    USER=`echo $CONF | awk -F: '{print $1}'`
    SUDO_PRIVILEDGE=`echo $CONF | awk -F: '{print $2}'`
    USER_ID=`echo $CONF | awk -F: '{print $3}'`
    GROUP=`echo $CONF | awk -F: '{print $4}'`
    PASSWORD=`echo $CONF | awk -F: '{print $5}'`

    if ! grep -q ^$GROUP: /etc/group; then
      echo "***********************************************************"
      echo "Group $GROUP is NOT configured, SKIP User $USER creating..."
      echo "***********************************************************"
      continue
    fi

    if ! id $USER>/dev/null 2>/dev/null; then
      useradd -p "$PASSWORD" -s /bin/bash -u $USER_ID -g $GROUP $USER
    fi

    if [ "$SUDO_PRIVILEDGE" = "Y" ] || [ "$SUDO_PRIVILEDGE" = "y" ]; then
      echo "$USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/99_$USER"
    fi

    if mountpoint -q -- /mnt; then
      mkdir -p /mnt/home

      if mount | grep -q /home/$USER/.gvfs; then
        umount /home/$USER/.gvfs
      fi

      if [ -L /home/$USER ]; then
        rm -rf /home/$USER
      fi

      if [ -d /mnt/home/$USER ]; then
        rm -rf /home/$USER
      else
        if [ -d /home/$USER ]; then
          mv /home/$USER /mnt/home/$USER
        else
          cp -r /etc/skel /mnt/home/$USER
        fi
      fi

      chown $USER:$GROUP /mnt/home/$USER -R
      ln -fs /mnt/home/$USER /home/$USER
    else
      if [ ! -d /home/$USER ]; then
        cp -r /etc/skel /home/$USER
        chown $USER:$GROUP /home/$USER -R
      fi
    fi
  done
fi
