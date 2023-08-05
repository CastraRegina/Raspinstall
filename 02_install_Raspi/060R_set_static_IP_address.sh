#!/bin/bash

# -------------------------------------------------------------------------------
# Set static IP address
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh


# -------------------------------------------------------------------------------
# Set static IP address for "eth0" i.e. the en* network device
# -------------------------------------------------------------------------------
if is_pi ; then
  netdevice=$(ip -o link show | awk -F': ' '{print $2}' | grep "^en*")
  ### netdevice=$(udevadm test-builtin net_id /sys/class/net/enxdca632250905 2>/dev/null | grep 'ID_NET_NAME_MAC=' | cut -d= -f2-)
  connUUID=$(nmcli --fields UUID connection show --active | grep -v UUID | head -n 1 | sed 's/ *$//g')
  # dhcpcd.conf is obsolete as "network manager" is used:
  # if ! sed -e 's/#.*$//g' /etc/dhcpcd.conf | grep -q -P 'interface +'"${netdevice}" ; then
  #   echo ""                                            | sudo tee -a /etc/dhcpcd.conf
  #   echo "# static IP configuration"                   | sudo tee -a /etc/dhcpcd.conf
  #   echo "interface ${netdevice}"                      | sudo tee -a /etc/dhcpcd.conf
  #   echo "static ip_address=${_IPADDRESS}/24"          | sudo tee -a /etc/dhcpcd.conf
  #   echo "static routers=${_ROUTERS}"                  | sudo tee -a /etc/dhcpcd.conf
  #   echo "static domain_name_servers=${_NAMESERVERS}"  | sudo tee -a /etc/dhcpcd.conf
  #   echo ""                                            | sudo tee -a /etc/dhcpcd.conf
  # fi
  # modify connection using "network manager" nmcli: 
  sudo nmcli connection modify "${connUUID}" \
    ipv4.addresses "${_IPADDRESS}/24" \
    ipv4.gateway "${_ROUTERS}" \
    ipv4.dns "${_NAMESERVERS}" \
    ipv4.dns-search "${_DOMAIN}" \
    ipv4.method "manual"
  nmcli connection 
  sudo cat /etc/NetworkManager/system-connections/*
fi



echo
echo "Script finished."
echo "Now do a sudo reboot"
