#!/bin/bash

# -------------------------------------------------------------------------------
# Setup ntp - Network Time Protocol
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh


if ! grep -q "server ${_NTPSERVER}" /etc/ntp.conf ; then
  sudo sed -i /etc/ntp.conf -e "s/^pool /#pool /"
  echo ""                                                      | sudo tee -a /etc/ntp.conf
  echo ""                                                      | sudo tee -a /etc/ntp.conf
  echo "# set an internal NTP server (min ca. 1h=68min=2^12)"  | sudo tee -a /etc/ntp.conf
  echo "server ${_NTPSERVER} iburst minpoll 12 maxpoll 17"     | sudo tee -a /etc/ntp.conf
  echo "#server 0.de.pool.ntp.org  minpoll 12 maxpoll 17"      | sudo tee -a /etc/ntp.conf
  echo "#server 1.de.pool.ntp.org  minpoll 12 maxpoll 17"      | sudo tee -a /etc/ntp.conf
  echo "#server 2.de.pool.ntp.org  minpoll 12 maxpoll 17"      | sudo tee -a /etc/ntp.conf
  echo "#server 3.de.pool.ntp.org  minpoll 12 maxpoll 17"      | sudo tee -a /etc/ntp.conf
  echo "#server ptbtime1.ptb.de    minpoll 12 maxpoll 17"      | sudo tee -a /etc/ntp.conf
  echo "# update by hand (in case of trouble):"                | sudo tee -a /etc/ntp.conf
  echo "#   sudo systemctl stop ntp"                           | sudo tee -a /etc/ntp.conf
  echo "#   sudo ntpd -qg"                                     | sudo tee -a /etc/ntp.conf
  echo "#   sudo systemctl start ntp"                          | sudo tee -a /etc/ntp.conf
  echo "#   ntpq -p"                                           | sudo tee -a /etc/ntp.conf
  echo ""                                                      | sudo tee -a /etc/ntp.conf
  echo ""                                                      | sudo tee -a /etc/ntp.conf
  sudo systemctl restart ntp
fi
sudo systemctl status ntp
ntpq -p



echo
echo "Script finished."