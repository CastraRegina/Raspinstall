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
for service in _DISABLESERVICES ; do
  sudo systemctl stop    "${service}"
  sudo systemctl disable "${service}"
done

# show currently running services:
sudo systemctl --type=service --state=running




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