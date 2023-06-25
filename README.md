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
set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately

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
- Access the Raspberry Pi remotely by using ssh:  
  `ssh fk@<remote-PC-ip-address>`  
  User name "fk" and password "12345678".
- Info: To call `/usr/bin/raspi-config` script in non-interactive mode, see
[https://forums.raspberrypi.com/viewtopic.php?t=21632](https://forums.raspberrypi.com/viewtopic.php?t=21632)
## Change standard password of user
```
passwd
```

## Intial settings: Define helper functions and environmental variables 
```
set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately

# -------------------------------------------------------------------------------
# Define helper function(s)
# -------------------------------------------------------------------------------
is_pi () {
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "armhf" ] || [ "$ARCH" = "arm64" ] ; then
    return 0
  else
    return 1
  fi
}


# -------------------------------------------------------------------------------
# Set environment variables
# -------------------------------------------------------------------------------
_HOSTNAME="lasrv04"
_IPADDRESS="192.168.2.4"
_ROUTERS="192.168.2.1"
_NAMESERVERS="192.168.2.1"
_NTPSERVER="192.168.2.1"
_LOCALELINE="de_DE.UTF-8 UTF-8"
            # de_DE ISO-8859-1
            # de_DE@euro ISO-8859-15
_LOGPATH=/home/fk/logs/install-logs/


if is_pi ; then
  if [ -e /proc/device-tree/chosen/os_prefix ]; then
    PREFIX="$(cat /proc/device-tree/chosen/os_prefix)"
  fi
  _CMDLINE="/boot/${PREFIX}cmdline.txt"
else
  _CMDLINE=/proc/cmdline
fi


_SW2INSTALL="pv xterm smartmontools geeqie xserver-xorg-input-evdev xinput-calibrator matchbox-keyboard git gcc build-essential cmake v4l-utils ffmpeg vlc vlc-bin autoconf-archive gnu-standards autoconf-doc dh-make gettext-doc libasprintf-dev libgettextpo-dev libtool-doc gfortran mplayer gnome-mplayer gecko-mediaplayer gphoto2 parted gparted iftop net-tools netstat-nat netcat fbi autocutsel epiphany-browser gpsd gpsd-clients python-gps python-gobject-2-dbg python-gtk2-doc devhelp python-gdbm-dbg python-tk-dbg iw wpasupplicant wireless-tools python-pil.imagetk libjpeg62-turbo libjpeg62-turbo-dev libavformat-dev python-pil-doc python-pil.imagetk-dbg python-doc python-examples python-pil.imagetk libjpeg62-turbo libjpeg62-turbo-dev libavcodec-dev libc6-dev zlib1g-dev libpq5 libpq-dev vim exuberant-ctags vim-doc vim-scripts libtemplate-perl libtemplate-perl-doc libtemplate-plugin-gd-perl libtemplate-plugin-xml-perl screen realvnc-vnc-server realvnc-vnc-viewer colord-sensor-argyll foomatic-db printer-driver-hpcups hplip printer-driver-cups-pdf antiword docx2txt gutenprint-locales ooo2dbk gutenprint-doc unpaper realvnc-vnc-server realvnc-vnc-viewer hdparm nfs-kernel-server nfs-common autofs fail2ban ntfs-3g hfsutils hfsprogs exfat-fuse iotop evince argyll-doc gir1.2-colordgtk-1.0 codeblocks ca-certificates-java openjdk-8-jre-headless openjdk-8-jre openjdk-8-jdk-headless openjdk-8-jdk icedtea-netx icedtea-8-plugin eclipse ninja-build xpp spf-tools-perl swaks monit openprinting-ppds foomatic-db-gutenprint gimp xpaint libjpeg-progs ufraw gfortran-6-doc libgfortran3-dbg libcoarrays-dev ghostscript-x xfsprogs reiserfsprogs reiser4progs jfsutils mtools yelp kpartx dmraid gpart gthumb pdftk gimp-gutenprint ijsgutenprint apmd hfsutils-tcltk hplip-doc hplip-gui python3-notify2 system-config-printer imagemagick-doc autotrace enscript gnuplot grads graphviz hp2xx html2ps libwmf-bin povray radiance texlive-binaries fig2dev libgtk2.0-doc libdigest-hmac-perl libgssapi-perl fonts-dustin libgda-5.0-bin libgda-5.0-mysql libgda-5.0-postgres libgmlib1-dbg libgmtk1-dbg gpgsm libdata-dump-perl libcrypt-ssleay-perl inkscape libparted-dev postgresql-doc sg3-utils snmp-mibs-downloader libauthen-ntlm-perl m4-doc mailutils-mh mailutils-doc docbook-xsl libmail-box-perl psutils hpijs-ppds magicfilter python-gpgme python-pexpect-doc python3-renderpm-dbg python-reportlab-doc bind9 bind9utils ctdb ldb-tools smbldap-tools winbind ufw byobu gsmartcontrol smart-notifier openssl-blacklist tcl-tclreadline xfonts-cyrillic vnstat tcpdump unzip pkg-config libjpeg-dev libpng-dev libtiff-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libgtk-3-dev libcanberra-gtk* libatlas-base-dev python3-dev libblas-doc liblapack-doc liblapack-dev liblapack-doc-man libcairo2-doc icu-doc liblzma-doc libxext-doc iperf aptitude firefox-esr samba samba-common-bin smbclient btrfs-progs btrfs-tools python-dev python-pip ffmpeg libffi-dev libxml2-dev libxslt-dev libcairo2 libgeos++-dev libgeos-dev libgeos-doc libjpeg-dev libtiff5-dev libpng-dev libfreetype6-dev libgif-dev libgtk-3-dev libxml2-dev libpango1.0-dev libcairo2-dev libspiro-dev python3-dev ninja-build cmake build-essential gettext"


# -------------------------------------------------------------------------------
# First action(s)...
# -------------------------------------------------------------------------------
mkdir -p "${_LOGPATH}"
```

## Update software, firmware and install first initial packages
```
# -------------------------------------------------------------------------------
# Update software and firmware
# -------------------------------------------------------------------------------
sudo apt update
sudo apt -y upgrade
sudo apt -y dist-upgrade
sudo apt -y full-upgrade
if is_pi ; then
  sudo rpi-eeprom-update    # checks if a firmware update is needed.
  # sudo apt install rpi-update
  # sudo rpi-update 
fi


# -------------------------------------------------------------------------------
# Install first initial packages
# -------------------------------------------------------------------------------
sudo apt -y install vim
sudo apt -y install screen
sudo apt -y install ntp
sudo apt -y install git

sudo apt -y install openssh-server
sudo apt -y install aptitude  
sudo apt -y install net-tools 
sudo apt -y install pv 
sudo apt -y install xterm 
sudo apt -y install cifs-utils 
sudo apt -y install nfs-common 
 
sudo apt -y install open-iscsi
sudo apt -y install sg3-utils
sudo apt -y install cryptsetup-bin 
sudo apt -y install btrfs-progs
sudo apt -y install parted
sudo apt -y install gparted

sudo apt -y install software-properties-common

if is_pi ; then
  sudo apt -y install watchdog

  # Generic Linux input driver, e.g. mouse
  sudo apt -y install xserver-xorg-input-evdev  

  # on-screen keyboard, e.g. for touch screens
  sudo apt -y install matchbox-keyboard
fi
```

## Do several settings
```
# -------------------------------------------------------------------------------
# Expand rootfs on SD-card
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_expand_rootfs
fi


# -------------------------------------------------------------------------------
# Enable ssh permanently
# -------------------------------------------------------------------------------
sudo systemctl enable ssh
if is_pi ; then
  sudo raspi-config nonint do_ssh 0
fi


# -------------------------------------------------------------------------------
# Set hostname
# -------------------------------------------------------------------------------
sudo sed -i /etc/hostname -e "s/raspberrypi/${_HOSTNAME}/"
sudo sed -i /etc/hosts    -e "s/raspberrypi/${_HOSTNAME}/"
if is_pi ; then
  sudo raspi-config nonint do_hostname ${_HOSTNAME}
fi


# -------------------------------------------------------------------------------
# Set LOCALE
# -------------------------------------------------------------------------------
# find supported settings using following command:   
#     cat /usr/share/i18n/SUPPORTED | grep ^de_DE
### LOCALE="$(echo ${_LOCALELINE} | cut -f1 -d " ")"
### ENCODING="$(echo ${_LOCALELINE} | cut -f2 -d " ")"
### echo "$LOCALE $ENCODING"  | sudo tee    /etc/locale.gen
### echo "LANG=${LOCALE}"     | sudo tee    /etc/default/locale
### echo "LC_ALL=${LOCALE}"   | sudo tee -a /etc/default/locale
### echo "LANGUAGE=${LOCALE}" | sudo tee -a /etc/default/locale
### sudo locale-gen ${LOCALE}
### sudo update-locale ${LOCALE}
### sudo dpkg-reconfigure -f noninteractive locales
if is_pi ; then
  sudo raspi-config nonint do_change_locale "${_LOCALELINE}"
fi


# -------------------------------------------------------------------------------
# Set timezone
# -------------------------------------------------------------------------------
### sudo rm /etc/localtime
### sudo ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
### sudo rm /etc/timezone
### echo "Europe/Berlin" | sudo tee /etc/timezone
### sudo dpkg-reconfigure -f noninteractive tzdata
if is_pi ; then
  sudo timedatectl set-timezone Europe/Berlin
  sudo raspi-config nonint do_change_timezone Europe/Berlin
fi


# -------------------------------------------------------------------------------
# Boot into Text console, requiring user to login
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_boot_behaviour B1
fi


# -------------------------------------------------------------------------------
# Do not show graphical splash screen at boot
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_boot_splash 1
fi


# -------------------------------------------------------------------------------
# Set GPU memory split
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_memory_split 64
fi


# -------------------------------------------------------------------------------
# Enable / disable vnc-server   (0=enable, 1=disable)
#   remark: looks vnc-server needs to be enabled for window manager to work
#   or do: "sudo systemctl start vncserver-x11-serviced.service" 
# -------------------------------------------------------------------------------
if is_pi ; then
  ### sudo systemctl enable vncserver-x11-serviced.service
  sudo raspi-config nonint do_vnc 1
fi


# -------------------------------------------------------------------------------
# Set VNC resolution
# -------------------------------------------------------------------------------
# TODO: seems not to work correctly
if is_pi ; then
  sudo raspi-config nonint do_vnc_resolution "1600x1000"
fi
```


## Install further packages
```
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
```


## Setup network
TODO: Check if this is still up-to-date (I do not think so)
TODO: Also set network inteface to fixed address
```
# -------------------------------------------------------------------------------
# Use predictable network interface names
# -------------------------------------------------------------------------------
### sudo sed -i ${_CMDLINE} -e "s/net.ifnames=0 *//"
### if [ -e /etc/systemd/network/99-default.link ] ; then
###   sudo rm -f /etc/systemd/network/99-default.link || { echo "rm -f /etc/systemd/network/99-default.link   failed" ; exit 1; }
### fi
if is_pi ; then
  sudo raspi-config nonint do_net_names 0
fi


# -------------------------------------------------------------------------------
# Removing ip-info from $_CMDLINE
# -------------------------------------------------------------------------------
### sudo sed -i $_{CMDLINE} -e "s/ip=[0-9]*.[0-9]*.[0-9]*.[0-9]* *//"
```

## Set secondary network IP address and/or further interface 

## Reduce number of writes to SD-card

## No cleanup of /dev/shm at ssh-logout
TODO: Check if this is still the case!!!

## VNC setup
Check setup...
```
sudo systemctl start vncserver-x11-serviced.service
vncserver -geometry 1800x1000
sudo systemctl stop vncserver-x11-serviced.service
```

## Automatic nightly reboot

## Samba setup

## Scan open ports and close them
TODO: check also regarding VNC-server
```
nmap -p- 192.168.2.163
```
 
## Collect and save weather-data

## Include "multiverse" repository
TODO: following is not yet working:
```
sudo add-apt-repository multiverse
sudo apt update
sudo apt install ubuntu-restricted-extras
```





# Further interesting topics
## Overlay Filesystem
See `sudo raspi-config` *-> Performance -> Overlay file system* and also...  
- [https://github.com/ghollingworth/overlayfs](https://github.com/ghollingworth/overlayfs)
- [https://yagrebu.net/unix/rpi-overlay.md](https://yagrebu.net/unix/rpi-overlay.md)

## Network print server 