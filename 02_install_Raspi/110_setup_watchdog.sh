#!/bin/bash

# -------------------------------------------------------------------------------
# Setup watchdog
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh


if ! grep -q "bcm2835_wdt" /etc/modules ; then
  sudo modprobe bcm2835_wdt
  echo "bcm2835_wdt" | sudo tee -a /etc/modules

  sudo sed -i /etc/watchdog.conf -e "s/^#max-load-1 /max-load-1 /"
  sudo sed -i /etc/watchdog.conf -e "s/^#watchdog-device/watchdog-device/"
  echo ""                             | sudo tee -a /etc/watchdog.conf
  echo ""                             | sudo tee -a /etc/watchdog.conf
  echo "watchdog-timeout        = 14" | sudo tee -a /etc/watchdog.conf
  echo "retry-timeout           = 14" | sudo tee -a /etc/watchdog.conf
  echo ""                             | sudo tee -a /etc/watchdog.conf

  sudo sed -i /lib/systemd/system/watchdog.service -e "s/^WantedBy=/#WantedBy=/"
  sudo sed -i /lib/systemd/system/watchdog.service -e '/^#WantedBy=/a\' -e 'WantedBy=multi-user.target'
  
  sudo systemctl enable watchdog.service
  sudo systemctl start watchdog.service
fi
sudo systemctl status watchdog 