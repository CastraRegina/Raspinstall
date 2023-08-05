#!/bin/bash

# -------------------------------------------------------------------------------
# Use "network manager" instead of "dhcpcd"
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh


# -------------------------------------------------------------------------------
# Use "network manager" (2) instead of "dhcpcd" (1) 
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_netconf 2
  #sudo systemctl stop dhcpcd.service
  #sudo systemctl disable dhcpcd.service
  #sudo systemctl enable networking
  #sudo systemctl restart networking
  sudo systemctl status networking
fi



echo
echo "Script finished."
echo "Now do a sudo reboot"
