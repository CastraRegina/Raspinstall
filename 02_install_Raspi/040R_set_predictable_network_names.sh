#!/bin/bash

# -------------------------------------------------------------------------------
# Set predictable network interface names (eth0 --> enxxxxxxxx)
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh


# -------------------------------------------------------------------------------
# Use predictable network interface names   (0=enable, 1=disable)
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_net_names 0
  if [ -e /etc/systemd/network/99-default.link ] ; then
    sudo rm -f /etc/systemd/network/99-default.link
  fi
  # workaround in order to enable predictable network interfaces:
  echo "[Match]"                     | sudo tee -a /etc/systemd/network/99-default.link
  echo "OriginalName=*"              | sudo tee -a /etc/systemd/network/99-default.link
  echo ""                            | sudo tee -a /etc/systemd/network/99-default.link
  echo "[Link]"                      | sudo tee -a /etc/systemd/network/99-default.link
  echo "NamePolicy=mac"              | sudo tee -a /etc/systemd/network/99-default.link
  echo "MACAddressPolicy=persistent" | sudo tee -a /etc/systemd/network/99-default.link
fi


echo
echo "Now do a sudo reboot"

