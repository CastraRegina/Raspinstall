#!/bin/bash

# -------------------------------------------------------------------------------
# Install further SW packages
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh


# -------------------------------------------------------------------------------
# Update software and firmware before installing further SW
# -------------------------------------------------------------------------------
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade
sudo apt -y full-upgrade


# -------------------------------------------------------------------------------
# Check if software packages are available...
# -------------------------------------------------------------------------------
export SW2INSTALL_AVAILABLE=""
echo "" >> ${_LOGPATH}sw_packages_not_available.txt
echo "" >> ${_LOGPATH}sw_packages_not_available.txt
for i in ${_SW2INSTALL} ; do
  echo -n "Checking package ${i} ... "
  if apt-cache show "${i}" 2> /dev/null | grep -q "^Filename:" ; then
    export SW2INSTALL_AVAILABLE="${SW2INSTALL_AVAILABLE} ${i}"
    echo "ok."
  else
    echo "${i}" >> ${_LOGPATH}sw_packages_not_available.txt
    echo "NOT AVAILABLE. ----------------------------------- CHECK"
  fi
done
echo


# -------------------------------------------------------------------------------
# Check which software packages really are not yet installed...
# -------------------------------------------------------------------------------
export SW2INSTALL=""
for i in ${SW2INSTALL_AVAILABLE} ; do
  echo -n "${i} "
  if [ $(dpkg-query -W -f='${Status}' "${i}" 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
    export SW2INSTALL="${SW2INSTALL} ${i}"
  fi
done
echo


# -------------------------------------------------------------------------------
# Download the software packages...
# -------------------------------------------------------------------------------
sudo apt-get -y install --download-only ${SW2INSTALL}


# -------------------------------------------------------------------------------
# Install the software packages (one by one)...
# -------------------------------------------------------------------------------
for i in ${SW2INSTALL} ; do
  echo "##########################################################################"
  echo "###### Installing ${i} ######"
  echo "${i} " >> ${_LOGPATH}sw_packages_install_triggered.txt
  sudo apt-get -y --install-recommends install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ${i}
  if [ $? -eq 0 ] ; then
    echo "${i} " >> ${_LOGPATH}sw_packages_install_ok.txt
  else
    echo "${i} " >> ${_LOGPATH}sw_packages_install_error.txt
  fi
done



# -------------------------------------------------------------------------------
# Clean the package cache...
# -------------------------------------------------------------------------------
sudo du -sh /var/cache/apt/archives/
sudo apt clean
sudo du -sh /var/cache/apt/archives/


