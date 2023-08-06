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
echo
echo "disabling avahi ..."
sudo systemctl stop avahi-daemon
sudo systemctl disable avahi-daemon
sudo systemctl stop avahi-daemon.socket
sudo systemctl disable avahi-daemon.socket
sudo systemctl stop avahi-daemon.service
sudo systemctl disable avahi-daemon.service
sudo systemctl mask avahi-daemon.service
sudo systemctl daemon-reload

#epmd
echo
echo "disabling epmd / erlang ..."
sudo systemctl stop    epmd
sudo systemctl disable epmd
sudo systemctl stop    epmd.socket
sudo systemctl disable epmd.socket
sudo apt remove -y     erlang-base erlang-crypto erlang-syntax-tools

#triggerhappy
echo
echo "disabling triggerhappy ..."
sudo systemctl stop    triggerhappy 
sudo systemctl disable triggerhappy
sudo systemctl stop    triggerhappy.socket 
sudo systemctl disable triggerhappy.socket
sudo apt remove -y     triggerhappy


# -------------------------------------------------------------------------------
# Stop and disable automatic update services
# -------------------------------------------------------------------------------
echo
echo "disabling automatic apt updates ..."
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer
sudo systemctl disable apt-daily-upgrade.service
sudo systemctl disable apt-daily-upgrade.timer

echo
echo "disabling packagekit ..."
# sudo systemctl stop packagekit.service
# sudo systemctl disable packagekit.service
# sudo systemctl mask packagekit.service
sudo systemctl stop packagekit-offline-update.service
sudo systemctl disable packagekit-offline-update.service
sudo systemctl mask packgekit-offline-update.service


# -------------------------------------------------------------------------------
# Disable automatic apt-updates by assigning "0" in the config-file
# -------------------------------------------------------------------------------
echo
FILE_APT20AUTOUPGRADES=/etc/apt/apt.conf.d/20auto-upgrades

# comment out the enabled ("1") services:
sudo sed -i 's/^\s*APT::Periodic::Update-Package-Lists.*1.*$/# &/'           ${FILE_APT20AUTOUPGRADES} 
sudo sed -i 's/^\s*APT::Periodic::Download-Upgradeable-Packages.*1.*$/# &/'  ${FILE_APT20AUTOUPGRADES} 
sudo sed -i 's/^\s*APT::Periodic::AutocleanInterval.*1.*$/# &/'              ${FILE_APT20AUTOUPGRADES}
sudo sed -i 's/^\s*APT::Periodic::Unattended-Upgrade.*1.*$/# &/'             ${FILE_APT20AUTOUPGRADES}

# disable the services by assigning "0" if not already done:
if [ ! -f "${FILE_APT20AUTOUPGRADES}" ] || ! grep -q '^APT::Periodic::Update-Package-Lists "0";\s*$' ${FILE_APT20AUTOUPGRADES} ; then
  echo 'APT::Periodic::Update-Package-Lists "0";' | sudo tee -a ${FILE_APT20AUTOUPGRADES}
fi

if [ ! -f "${FILE_APT20AUTOUPGRADES}" ] || ! grep -q '^APT::Periodic::Download-Upgradeable-Packages "0";\s*$' ${FILE_APT20AUTOUPGRADES} ; then
  echo 'APT::Periodic::Download-Upgradeable-Packages "0";' | sudo tee -a ${FILE_APT20AUTOUPGRADES}
fi

if [ ! -f "${FILE_APT20AUTOUPGRADES}" ] || ! grep -q '^APT::Periodic::AutocleanInterval "0";\s*$' ${FILE_APT20AUTOUPGRADES} ; then
  echo 'APT::Periodic::AutocleanInterval "0";' | sudo tee -a ${FILE_APT20AUTOUPGRADES}
fi

if [ ! -f "${FILE_APT20AUTOUPGRADES}" ] || ! grep -q '^APT::Periodic::Unattended-Upgrade "0";\s*$' ${FILE_APT20AUTOUPGRADES} ; then
  echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a ${FILE_APT20AUTOUPGRADES}
fi



echo
echo "show currently running services:"
echo "  sudo systemctl --type=service --state=running"



echo 
echo "Script finished."
