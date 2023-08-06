#!/bin/bash

# -------------------------------------------------------------------------------
# First simple settings
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh


# -------------------------------------------------------------------------------
# Expand rootfs on SD-card (probably already done at first boot)
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_expand_rootfs
fi


# -------------------------------------------------------------------------------
# Enable ssh permanently   (0=enable, 1=disable)
# -------------------------------------------------------------------------------
sudo systemctl enable ssh
if is_pi ; then
  sudo raspi-config nonint do_ssh 0
fi


# -------------------------------------------------------------------------------
# Set hostname
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo sed -i /etc/hostname -e "s/raspberrypi/${_HOSTNAME}/"
  sudo sed -i /etc/hosts    -e "s/raspberrypi/${_HOSTNAME}/"
  sudo raspi-config nonint do_hostname ${_HOSTNAME}
fi


# -------------------------------------------------------------------------------
# Set LOCALE
# -------------------------------------------------------------------------------
# find supported settings using following command:   
#     cat /usr/share/i18n/SUPPORTED | grep ^de_DE
if is_pi ; then
  sudo raspi-config nonint do_change_locale "${_LOCALELINE}"
  ### LOCALE="$(echo ${_LOCALELINE} | cut -f1 -d " ")"
  ### ENCODING="$(echo ${_LOCALELINE} | cut -f2 -d " ")"
  ### echo "$LOCALE $ENCODING"  | sudo tee    /etc/locale.gen
  ### echo "LANG=${LOCALE}"     | sudo tee    /etc/default/locale
  ### echo "LC_ALL=${LOCALE}"   | sudo tee -a /etc/default/locale
  ### echo "LANGUAGE=${LOCALE}" | sudo tee -a /etc/default/locale
  ### sudo locale-gen ${LOCALE}
  ### sudo update-locale ${LOCALE}
  ### sudo dpkg-reconfigure -f noninteractive locales
fi


# -------------------------------------------------------------------------------
# Set timezone
# -------------------------------------------------------------------------------
### sudo rm /etc/localtime
### sudo ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
### sudo rm /etc/timezone
### echo "Europe/Berlin" | sudo tee /etc/timezone
### sudo dpkg-reconfigure -f noninteractive tzdata
if is_pi ; then
  sudo timedatectl set-timezone Europe/Berlin
  sudo raspi-config nonint do_change_timezone Europe/Berlin
fi


# -------------------------------------------------------------------------------
# Boot into Text console, requiring user to login
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_boot_behaviour B1
fi


# -------------------------------------------------------------------------------
# Do not show graphical splash screen at boot
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_boot_splash 1
fi


# -------------------------------------------------------------------------------
# Set GPU memory split: _16_ / 32 / _64_ / 128 / 256
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_memory_split 64
fi


# -------------------------------------------------------------------------------
# Enable / disable vnc-server   (0=enable, 1=disable)
#   remark: looks like vnc-server needs to be enabled for window manager to work
#   or do: "sudo systemctl start vncserver-x11-serviced.service" 
# -------------------------------------------------------------------------------
if is_pi ; then
  ### sudo systemctl enable vncserver-x11-serviced.service
  sudo raspi-config nonint do_vnc 1
fi


# -------------------------------------------------------------------------------
# Set VNC resolution
# -------------------------------------------------------------------------------
# TODO: seems not to work correctly
if is_pi ; then
  sudo raspi-config nonint do_vnc_resolution "1600x1000"
fi


# -------------------------------------------------------------------------------
# Modify /etc/fstab to reduce SD-card access (reduce wear)
# -------------------------------------------------------------------------------
if is_pi ; then
  if ! grep -q "/var/tmp" /etc/fstab ; then
    echo "# ---- special settings -------------------------------------------------------------------" | sudo tee -a /etc/fstab
    echo "#/run, /var/run, /run/lock, /var/run/lock will be automatically created by default - tmpfs"  | sudo tee -a /etc/fstab
    echo "tmpfs /tmp              tmpfs defaults,noatime,nosuid,size=100m                         0 0" | sudo tee -a /etc/fstab
    echo "tmpfs /var/tmp          tmpfs defaults,noatime,nosuid,size=30m                          0 0" | sudo tee -a /etc/fstab
    echo "#tmpfs /var/log          tmpfs defaults,noatime,mode=0755,size=30m                       0 0" | sudo tee -a /etc/fstab
    echo "tmpfs /var/spool/mqueue tmpfs defaults,noatime,nosuid,mode=0700,gid=12,size=30m         0 0" | sudo tee -a /etc/fstab
    echo "tmpfs /var/cache/samba  tmpfs nodev,nosuid,noatime,size=50m                             0 0" | sudo tee -a /etc/fstab
    echo "#tmpfs /var/www/html     tmpfs defaults,noatime,nosuid,nodev,noexec,mode=0755,size=50m   0 0" | sudo tee -a /etc/fstab
    echo "#tmpfs /var/lib/upsd     tmpfs defaults,noatime,nosuid,nodev,noexec,mode=0755,size=4k    0 0" | sudo tee -a /etc/fstab
  fi
fi


# -------------------------------------------------------------------------------
# Switch of swap-file/swap-partition to reduce SD-card access (reduce wear)
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo dphys-swapfile swapoff
  sudo systemctl disable dphys-swapfile
fi


# -------------------------------------------------------------------------------
# Disable vim automatic visual mode on mouse select
# -------------------------------------------------------------------------------
if [ ! -f "${HOME}/.vimrc" ] || ! grep -q "set mouse-=a" ${HOME}/.vimrc ; then
  echo 'set mouse-=a' >> ${HOME}/.vimrc
fi


echo 
echo "Script finished."
