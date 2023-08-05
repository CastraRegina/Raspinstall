#!/bin/bash

# -------------------------------------------------------------------------------
# Update SW packages
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh


# -------------------------------------------------------------------------------
# Update software and firmware
# -------------------------------------------------------------------------------
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade
sudo apt -y full-upgrade

if is_pi ; then
  sudo rpi-eeprom-update    # checks if a firmware update is needed.
  # sudo apt -y install rpi-update
  # sudo rpi-update 
fi



echo 
echo "Script finished."
