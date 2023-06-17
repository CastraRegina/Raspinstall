# Raspinstall  
Personal guide to installing and setting up my Raspberry Pi.  
Scripts should be [idempotent](https://en.wikipedia.org/wiki/Idempotence):
    Regardless of how many times the script is again executed with the same input, the output must always remain the same.
# Steps to do on your local Linux-PC
## Clone this repository
`git clone git@github.com:CastraRegina/Raspinstall.git`
## Download image(s)
Download [Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/):  
For example `2023-05-03-raspios-bullseye-armhf-full.img.xz`:  
[Raspberry Pi OS with desktop and recommended software](https://downloads.raspberrypi.org/raspios_full_armhf/images/raspios_full_armhf-2023-05-03/2023-05-03-raspios-bullseye-armhf-full.img.xz)

## Extract image
Extract the image file at its place:  
`xz -v -d 2023-05-03-raspios-bullseye-armhf-full.img.xz`  
This will create the 11GB image file `2023-05-03-raspios-bullseye-armhf-full.img`.

## Setting environment variables
Do a `sudo su -` to be `root`...  
```
set -e
set -u

# -------------------------------------------------------------------------------
# check if we are root?
# -------------------------------------------------------------------------------
if [ $USER != root ] ; then
  echo "You must be root to execute this script!!!"
  exit 1
fi
```
```
# -------------------------------------------------------------------------------
# Set environment variables
# -------------------------------------------------------------------------------
# You must be root !!!
BOOTDIR=/media/fk/bootfs/
ROOTFSDIR=/media/fk/rootfs/
CMDLINE=${BOOTDIR}cmdline.txt
CONFIGTXT=${BOOTDIR}config.txt
USERCONFTXT=${BOOTDIR}userconf.txt
USERNAME=fk
RASPIIMAGE=/mnt/lanas01_test/iso_images/raspios/2023-05-03-raspios-bullseye-armhf-full.img
SDCARDDEST=/dev/sdc    # check carefully !!!
```
Umount SD-card if needed...
```
# -------------------------------------------------------------------------------
# check if dirs are mounted and umount them... 
# -------------------------------------------------------------------------------
while [ -e ${BOOTDIR} ] ; do
  echo "umount ${BOOTDIR}"
  umount ${BOOTDIR} || true
  sleep 1s
done
while [ -e ${ROOTFSDIR} ] ; do
  echo "umount ${ROOTFSDIR}"
  umount ${ROOTFSDIR} || true
  sleep 1s
done
if [ -e ${BOOTDIR} ] ; then
  rmdir ${BOOTDIR}
fi
if [ -e ${ROOTFSDIR} ] ; then
  rmdir ${ROOTFSDIR}
fi
if mount | grep ${SDCARDDEST} ; then
  echo "${SDCARDDEST} appears in mount!!!"
  exit 2
fi
```

## Copy image onto SD-card
```
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
```
It took roughly 13mins to copy the image to the SD-card.

## Modify configuration on SD-card
To support a headless Raspberry Pi, the remote computer should be accessible via `ssh` directly after installation.

### Mount SD-card
Mount and check if `mount` was successful:
```
# -------------------------------------------------------------------------------
# mount .../bootfs and .../rootfs directory 
# -------------------------------------------------------------------------------
mount -o x-mount.mkdir ${SDCARDDEST}1 ${BOOTDIR}
mount -o x-mount.mkdir ${SDCARDDEST}2 ${ROOTFSDIR}

# -------------------------------------------------------------------------------
# check if .../bootfs and .../rootfs directory exists:
# -------------------------------------------------------------------------------
echo "is ${BOOTDIR} mounted / available?"
if [ ! -e ${BOOTDIR} ] ; then
  echo "mount ${BOOTDIR} first, e.g. :"
  echo "mount /dev/sdc1 ${BOOTDIR}" 
  exit 1
fi
echo "${BOOTDIR} is available."
echo

echo "is ${ROOTFSDIR} mounted / available?"
if [ ! -e ${ROOTFSDIR} ] ; then
  echo "mount ${ROOTFSDIR} first, e.g. :"
  echo "mount /dev/sdc2 ${ROOTFSDIR}" 
  exit 1
fi
echo "${ROOTFSDIR} is available."
echo
```

### Do modifications on SD-card
Enable `ssh`:
```
# -------------------------------------------------------------------------------
# create file ssh in /boot:
# -------------------------------------------------------------------------------
echo "touch ${BOOTDIR}ssh"
touch "${BOOTDIR}/ssh"
echo "touch ${BOOTDIR}ssh - done."
echo
```
Switch off WLAN and bluetooth like explained by 
[https://raspberrytips.com/disable-wifi-raspberry-pi/](https://raspberrytips.com/disable-wifi-raspberry-pi/)
and do some settings for my small screen:
```
# -------------------------------------------------------------------------------
# edit /boot/config.txt
# -------------------------------------------------------------------------------
echo "configuring ${CONFIGTXT} ..."
if [ ! -e ${CONFIGTXT} ] ; then
  echo "${CONFIGTXT} does not exist!!!"
  exit 5
fi
if ! grep -q "dtoverlay=disable-wifi" ${CONFIGTXT} ; then
  echo ""                                             >> ${CONFIGTXT}
  echo "# switch off onboard WLAN and bluetooth"      >> ${CONFIGTXT}
  echo "dtoverlay=disable-wifi"                   >> ${CONFIGTXT}
  echo "dtoverlay=disable-bt"                     >> ${CONFIGTXT}
  echo ""                                             >> ${CONFIGTXT}
  echo "# hdmi configuration for 10inch touchscreen:" >> ${CONFIGTXT}
  echo "hdmi_force_hotplug=1"                         >> ${CONFIGTXT}
  echo "hdmi_group=2"                                 >> ${CONFIGTXT}
  echo "hdmi_mode=27"                                 >> ${CONFIGTXT}
  echo ""                                             >> ${CONFIGTXT}
  echo "  ${CONFIGTXT} modified." 

  sed -i 's/^dtoverlay=vc4-kms-v3d*$/#dtoverlay=vc4-kms-v3d/g' ${CONFIGTXT}
  echo "  ${CONFIGTXT} modified --> comment out (for 10inch-touchscreen): dtoverlay=vc4-kms-v3d" 
else
  echo "  ${CONFIGTXT} already configured (no changes done)."
fi
echo "configuring ${CONFIGTXT} done."
echo
```
Setup a new user for the headless Raspberry Pi as explained in 
[http://rptl.io/newuser](http://rptl.io/newuser)...  
Do not forget to set a better password later!!!
```
encpasswd=$(echo '12345678' | openssl passwd -6 -stdin)
echo ${USERNAME}:${encpasswd} > ${USERCONFTXT}
```

### Umount SD-card
```
# -------------------------------------------------------------------------------
# umount .../bootfs and .../rootfs directory 
# -------------------------------------------------------------------------------
while mount | grep -q ${SDCARDDEST}  ; do
  echo "trying to umount ${BOOTDIR} and ${ROOTFSDIR}"
  umount "${BOOTDIR}"   || echo "error unmount ${BOOTDIR}"
  umount "${ROOTFSDIR}" || echo "error unmount ${ROOTFSDIR}"
  sleep 1s
done
rmdir  "${BOOTDIR}"   || echo "error rmdir ${BOOTDIR}"
rmdir  "${ROOTFSDIR}" || echo "error rmdir ${ROOTFSDIR}"
```

# Steps to do on your remote Raspberry Pi
- Insert SD-card and boot.
- You can access the remote Raspberry Pi using ssh:  
  `ssh fk@<remote-PC-ip-address>`  
  User name "fk" and password "12345678".

## Update software and firmware
```
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo apt full-upgrade
sudo rpi-eeprom-update    # checks if a firmware update is needed.
# sudo apt install rpi-update
# sudo rpi-update 
```
