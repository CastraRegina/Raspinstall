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
BOOTFSDIR=/media/fk/bootfs/
ROOTFSDIR=/media/fk/rootfs/
CMDLINE=${BOOTFSDIR}cmdline.txt
CONFIGTXT=${BOOTFSDIR}config.txt
USERCONFTXT=${BOOTFSDIR}userconf.txt
USERNAME=fk
RASPIIMAGE=/mnt/lanas01_test/iso_images/raspios/2023-05-03-raspios-bullseye-armhf-full.img
SDCARDDEST=/dev/sdc    # check carefully !!!
```
Umount SD-card if needed...
```
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
```

### Do modifications on SD-card
Enable `ssh`:
```
# -------------------------------------------------------------------------------
# create file ssh in /boot:
# -------------------------------------------------------------------------------
echo "touch ${BOOTFSDIR}ssh"
touch "${BOOTFSDIR}/ssh"
echo "touch ${BOOTFSDIR}ssh - done."
echo
```
Switch off WLAN and bluetooth like explained by 
[https://raspberrytips.com/disable-wifi-raspberry-pi/](https://raspberrytips.com/disable-wifi-raspberry-pi/)
and do also some settings for my small screen:
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

Disable vim automatic visual mode on mouse select
```
echo 'set mouse-=a' >> ${ROOTFSDIR}etc/skel/.vimrc
```

### Umount SD-card
```
# -------------------------------------------------------------------------------
# umount .../bootfs and .../rootfs directory 
# -------------------------------------------------------------------------------
while mount | grep -q ${SDCARDDEST}  ; do
  echo "trying to umount ${BOOTFSDIR} and ${ROOTFSDIR}"
  umount "${BOOTFSDIR}"   || echo "error unmount ${BOOTFSDIR}"
  umount "${ROOTFSDIR}" || echo "error unmount ${ROOTFSDIR}"
  sleep 1s
done
rmdir  "${BOOTFSDIR}"   || echo "error rmdir ${BOOTFSDIR}"
rmdir  "${ROOTFSDIR}" || echo "error rmdir ${ROOTFSDIR}"
```

# Steps to do on your remote Raspberry Pi
- Insert SD-card and boot.
- You can access the remote Raspberry Pi using ssh:  
  `ssh fk@<remote-PC-ip-address>`  
  User name "fk" and password "12345678".

## Change standard password of user

## Update software and firmware
```
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade
sudo apt -y full-upgrade
sudo rpi-eeprom-update    # checks if a firmware update is needed.
# sudo apt install rpi-update
# sudo rpi-update 
```
## Define helper functions
```
is_pi () {
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "armhf" ] ; then
    return 0
  else
    return 1
  fi
}
```

## Set environment variables
```
TODO
```

## Install first packages
TODO : check NAS for further "first" packages and add them here:
```
sudo apt -y install vim
sudo apt -y install screen
sudo apt -y install ntp
sudo apt -y install git
sudo apt -y install watchdog

# Generic Linux input driver, e.g. mouse
sudo apt -y install xserver-xorg-input-evdev  

# on-screen keyboard, e.g. for touch screens
sudo apt -y install matchbox-keyboard
```

## Install all further packages
```
  TODO: set variable(s), use logging and modify following:

  echo "step-${CHAPTER}-02" >> $LOGFILE
  echo "" | tee -a ${LOGFILE}
  echo "###### check if software packages are available... ############################################################" | tee -a ${LOGFILE}
  export SW2INSTALL_AVAILABLE=""
  echo "" >> ${LOGPATH}packages_not-available.txt
  echo "" >> ${LOGPATH}packages_not-available.txt
  for i in ${SW2INSTALL} ; do
     #if sudo dpkg -l "${i}" > /dev/null 2> /dev/null ; then
     #if apt-cache show "${i}" > /dev/null 2> /dev/null ; then
     if apt-cache show "${i}" 2> /dev/null | grep -q "^Filename:" ; then
       export SW2INSTALL_AVAILABLE="${SW2INSTALL_AVAILABLE} ${i}"
     else
       echo "${i}" >> ${LOGPATH}packages_not-available.txt
     fi
  done
  echo "###### check which software packages need to be installed ... #################################################" | tee -a ${LOGFILE}
  export SW2INSTALL=""
  for i in ${SW2INSTALL_AVAILABLE} ; do
    if [ $(dpkg-query -W -f='${Status}' "${i}" 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
      export SW2INSTALL="${SW2INSTALL} ${i}"
    fi
  done
  echo "----------------------------------------------------------------------------" >> $LOGFILE
  date >> $LOGFILE
  echo "----------------------------------------------------------------------------" >> $LOGFILE

  echo "step-${CHAPTER}-03" >> $LOGFILE
  echo "###### download software packages (start)... ###################################################################" | tee -a ${LOGFILE}
  echo "" | tee -a ${LOGFILE}
  sudo apt-get -y install --download-only ${SW2INSTALL}
  echo "###### ... download software packages (done) ###################################################################" | tee -a ${LOGFILE}
  echo "----------------------------------------------------------------------------" >> $LOGFILE
  date >> $LOGFILE
  echo "----------------------------------------------------------------------------" >> $LOGFILE

  echo "step-${CHAPTER}-04" >> $LOGFILE
  echo "###### install software packages (start)... ###################################################################" | tee -a ${LOGFILE}
  echo "" | tee -a ${LOGFILE}
  for i in ${SW2INSTALL} ; do
    echo "###############################################################################################################"
    echo "###### Installing ${i} ######" | tee -a ${LOGFILE}
    echo -n "${i} " >> ${LOGPATH}installed-sw-1-pre.txt
    #sudo apt-get -y --force-yes --install-recommends install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ${i}
    sudo apt-get -y --install-recommends install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ${i}
    if [ $? -eq 0 ] ; then
      echo -n "${i} " >> ${LOGPATH}installed-sw-2-ok.txt
    else
      echo "${i}" >> ${LOGPATH}installed-sw-2-error.txt
    fi
  done
  echo "###### ... install software packages (done) ###################################################################" | tee -a ${LOGFILE}

```


## Reduce number of writes to SD-card

## Runlevel 3 - no graphic output

## No cleanup of /dev/shm at ssh-logout

## VNC setup

## Nightly reboot

## Samba setup




# Further interesting topics
## Overlay Filesystem
See `sudo raspi-config` *-> Performance -> Overlay file system* and also...  
- [https://github.com/ghollingworth/overlayfs](https://github.com/ghollingworth/overlayfs)
- [https://yagrebu.net/unix/rpi-overlay.md](https://yagrebu.net/unix/rpi-overlay.md)

## Network print server 