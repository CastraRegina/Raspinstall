#!/bin/bash

# -------------------------------------------------------------------------------
# Install initial packages
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh


# -------------------------------------------------------------------------------
# Install first initial packages
# -------------------------------------------------------------------------------
sudo apt update
sudo apt -y install vim screen xterm pv openssh-server aptitude parted gparted btrfs-progs git
sudo apt -y install ntp net-tools cifs-utils nfs-common nmap
sudo apt -y install open-iscsi sg3-utils cryptsetup-bin 
sudo apt -y install software-properties-common

if is_pi ; then
  sudo apt -y install watchdog

  # Generic Linux input driver, e.g. mouse
  sudo apt -y install xserver-xorg-input-evdev  

  # on-screen keyboard, e.g. for touch screens
  sudo apt -y install matchbox-keyboard

  # use network manager instead of dhcpcd
  sudo apt -y install network-manager network-manager-gnome
fi



echo 
echo "Script finished."