#!/bin/bash

set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately

# -------------------------------------------------------------------------------
# check if we are root?
# -------------------------------------------------------------------------------
if [ $USER != root ] ; then
  echo "You must be root to execute this script!!!"
  exit 1
fi



# -------------------------------------------------------------------------------
# Set environment variables
# -------------------------------------------------------------------------------
# You must be root !!!
BOOTFSDIR=/media/fk/bootfs/
ROOTFSDIR=/media/fk/rootfs/
CMDLINE=${BOOTFSDIR}cmdline.txt
CONFIGTXT=${BOOTFSDIR}config.txt
USERCONFTXT=${BOOTFSDIR}userconf.txt
USERNAME=fk
RASPIIMAGE=/mnt/lanas01_test/iso_images/raspios/2023-05-03-raspios-bullseye-armhf-full.img
RASPIIMAGE=/data/nobackup/fk/isos/2023-12-05-raspios-bookworm-armhf-full.img
# RASPIIMAGE=/data/nobackup/fk/isos/2023-05-03-raspios-bullseye-armhf-full.img
SDCARDDEST=/dev/sda    # check carefully !!!



# -------------------------------------------------------------------------------
# check if dirs are mounted and umount them... 
# -------------------------------------------------------------------------------
while [ -e ${BOOTFSDIR} ] ; do
  echo "umount ${BOOTFSDIR}"
  umount ${BOOTFSDIR} || true
  sleep 1s
done
while [ -e ${ROOTFSDIR} ] ; do
  echo "umount ${ROOTFSDIR}"
  umount ${ROOTFSDIR} || true
  sleep 1s
done
if [ -e ${BOOTFSDIR} ] ; then
  rmdir ${BOOTFSDIR}
fi
if [ -e ${ROOTFSDIR} ] ; then
  rmdir ${ROOTFSDIR}
fi
if mount | grep ${SDCARDDEST} ; then
  echo "${SDCARDDEST} appears in mount!!!"
  exit 2
fi



# -------------------------------------------------------------------------------
# copy image to sdcard 
# -------------------------------------------------------------------------------
echo "copying image ${RASPIIMAGE} to ${SDCARDDEST} ..."
if [ -e "${RASPIIMAGE}" ] ; then
  echo "time dd bs=4M if=${RASPIIMAGE} of=${SDCARDDEST} conv=fsync"
  time dd bs=4M if="${RASPIIMAGE}" of="${SDCARDDEST}" conv=fsync
  sync
else
  echo "Image ${RASPIIMAGE} does not exist!!!"
  exit 4
fi



# -------------------------------------------------------------------------------
# mount .../bootfs and .../rootfs directory 
# -------------------------------------------------------------------------------
mount -o x-mount.mkdir ${SDCARDDEST}1 ${BOOTFSDIR}
mount -o x-mount.mkdir ${SDCARDDEST}2 ${ROOTFSDIR}

# -------------------------------------------------------------------------------
# check if .../bootfs and .../rootfs directory exists:
# -------------------------------------------------------------------------------
echo "is ${BOOTFSDIR} mounted / available?"
if [ ! -e ${BOOTFSDIR} ] ; then
  echo "mount ${BOOTFSDIR} first, e.g. :"
  echo "mount /dev/sdc1 ${BOOTFSDIR}" 
  exit 1
fi
echo "${BOOTFSDIR} is available."
echo

echo "is ${ROOTFSDIR} mounted / available?"
if [ ! -e ${ROOTFSDIR} ] ; then
  echo "mount ${ROOTFSDIR} first, e.g. :"
  echo "mount /dev/sdc2 ${ROOTFSDIR}" 
  exit 1
fi
echo "${ROOTFSDIR} is available."
echo



# -------------------------------------------------------------------------------
# create file ssh in /boot:
# -------------------------------------------------------------------------------
echo "touch ${BOOTFSDIR}ssh"
touch "${BOOTFSDIR}/ssh"
echo "touch ${BOOTFSDIR}ssh - done."
echo



# -------------------------------------------------------------------------------
# edit /boot/config.txt
# -------------------------------------------------------------------------------
echo "configuring ${CONFIGTXT} ..."
if [ ! -e ${CONFIGTXT} ] ; then
  echo "${CONFIGTXT} does not exist!!!"
  exit 5
fi
if ! grep -q "switch off onboard WLAN and bluetooth" ${CONFIGTXT} ; then
  echo ""                                             >> ${CONFIGTXT}
  echo "# switch off onboard WLAN and bluetooth"      >> ${CONFIGTXT}
  echo "dtoverlay=disable-wifi"                       >> ${CONFIGTXT}
  echo "dtoverlay=disable-bt"                         >> ${CONFIGTXT}
  echo ""                                             >> ${CONFIGTXT}
fi
if ! grep -q "hdmi configuration for 10inch touchscreen" ${CONFIGTXT} ; then
  echo ""                                             >> ${CONFIGTXT}
  echo "# hdmi configuration for 10inch touchscreen:" >> ${CONFIGTXT}
  echo "hdmi_force_hotplug=1"                         >> ${CONFIGTXT}
  echo "hdmi_group=2"                                 >> ${CONFIGTXT}
  echo "hdmi_mode=27"                                 >> ${CONFIGTXT}
  echo ""                                             >> ${CONFIGTXT}
  sed -i 's/^dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/g' ${CONFIGTXT}
fi
echo



# -------------------------------------------------------------------------------
# create / set default password for user 
# -------------------------------------------------------------------------------
encpasswd=$(echo '12345678' | openssl passwd -6 -stdin)
echo ${USERNAME}:${encpasswd} > ${USERCONFTXT}



# -------------------------------------------------------------------------------
# Disable vim automatic visual mode on mouse select
# -------------------------------------------------------------------------------
if [ ! -f "${ROOTFSDIR}etc/skel/.vimrc" ] || ! grep -q "set mouse-=a" ${ROOTFSDIR}etc/skel/.vimrc ; then
  echo 'set mouse-=a' >> ${ROOTFSDIR}etc/skel/.vimrc
fi



# -------------------------------------------------------------------------------
# Fix LOCALE-error-message when installing packages
# -------------------------------------------------------------------------------
# sed -i 's/^AcceptEnv LANG LC_\*/#AcceptEnv LANG LC_\*/g' ${ROOTFSDIR}etc/ssh/sshd_config



# -------------------------------------------------------------------------------
# umount .../bootfs and .../rootfs directory 
# -------------------------------------------------------------------------------
while mount | grep -q ${SDCARDDEST}  ; do
  echo "trying to umount ${BOOTFSDIR} and ${ROOTFSDIR}"
  umount "${BOOTFSDIR}" || echo "error unmount ${BOOTFSDIR}"
  umount "${ROOTFSDIR}" || echo "error unmount ${ROOTFSDIR}"
  sleep 1s
done
rmdir  "${BOOTFSDIR}" || echo "error rmdir ${BOOTFSDIR}"
rmdir  "${ROOTFSDIR}" || echo "error rmdir ${ROOTFSDIR}"
