#!/bin/bash

# -------------------------------------------------------------------------------
# Stop and disable services
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh



# -------------------------------------------------------------------------------
# Stop and disable services one by one
# -------------------------------------------------------------------------------
for service in ${_DISABLESERVICES} ; do
  sudo systemctl stop    "${service}"
  sudo systemctl disable "${service}"
done



# -------------------------------------------------------------------------------
# Take special care of some services...
# -------------------------------------------------------------------------------

# avahi
sudo systemctl stop avahi-daemon
sudo systemctl disable avahi-daemon
sudo systemctl stop avahi-daemon.socket
sudo systemctl disable avahi-daemon.socket
sudo systemctl stop avahi-daemon.service
sudo systemctl disable avahi-daemon.service
sudo systemctl mask avahi-daemon.service
sudo systemctl daemon-reload

#epmd
sudo systemctl stop    epmd
sudo systemctl disable epmd
sudo systemctl stop    epmd.socket
sudo systemctl disable epmd.socket
sudo apt remove -y     erlang-base erlang-crypto erlang-syntax-tools

#triggerhappy
sudo systemctl stop    triggerhappy 
sudo systemctl disable triggerhappy
sudo systemctl stop    triggerhappy.socket 
sudo systemctl disable triggerhappy.socket
sudo apt remove -y     triggerhappy


# -------------------------------------------------------------------------------
# Stop and disable automatic update services
# -------------------------------------------------------------------------------
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer
sudo systemctl disable apt-daily-upgrade.service
sudo systemctl disable apt-daily-upgrade.timer

sudo systemctl stop packagekit.service
sudo systemctl disable packagekit.service
sudo systemctl mask packagekit.service
sudo systemctl stop packagekit-offline-update.service
sudo systemctl disable packagekit-offline-update.service
sudo systemctl mask packgekit-offline-update.service



echo "Script finished."
echo "show currently running services:"
echo "  sudo systemctl --type=service --state=running"
