# Raspinstall  
Personal guideline to installing and setting up a Raspberry Pi.  
Scripts should be [idempotent](https://en.wikipedia.org/wiki/Idempotence):
    Regardless of how many times the script is again executed with the same input, the output must always remain the same.

# Content
- [Steps to do on your local Linux-PC](#steps-to-do-on-your-local-linux-pc)
- [Steps to do on your remote Raspberry Pi](#steps-to-do-on-your-remote-raspberry-pi)


# Steps to do on your local Linux-PC
## Clone this repository
```
git clone git@github.com:CastraRegina/Raspinstall.git
git clone https://github.com/CastraRegina/Raspinstall.git
```

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
**Check carefully the destination (SD-card) `$SDCARDDEST`** e.g. by looking at the output of `dmesg`!!!
```
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
and do also some settings for the 10inch touchscreen:  
```
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
  sed -i 's/^dtoverlay=vc4-kms-v3d*$/#dtoverlay=vc4-kms-v3d/g' ${CONFIGTXT}
fi
echo
```

Setup a new user for the headless Raspberry Pi as explained in   
[http://rptl.io/newuser](http://rptl.io/newuser)  
or [https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/configuration/headless.adoc](https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/configuration/headless.adoc) ...  
Do not forget to set a better password later!!!
```
# -------------------------------------------------------------------------------
# create / set default password for user 
# -------------------------------------------------------------------------------
encpasswd=$(echo '12345678' | openssl passwd -6 -stdin)
echo ${USERNAME}:${encpasswd} > ${USERCONFTXT}
```

Disable vim automatic visual mode on mouse select
```
# -------------------------------------------------------------------------------
# Disable vim automatic visual mode on mouse select
# -------------------------------------------------------------------------------
if ! grep -q "set mouse-=a" ${ROOTFSDIR}etc/skel/.vimrc ; then
  echo 'set mouse-=a' >> ${ROOTFSDIR}etc/skel/.vimrc
fi
```

### Umount SD-card
```
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
```


---
---
---


# Steps to do on your remote Raspberry Pi
- Insert SD-card and boot.
- Find the Raspberry Pi in the network:  
  `nmap -sn 192.168.2.0/24` (maybe use it with `sudo`)
- Access the Raspberry Pi remotely by using ssh:  
  `ssh fk@<remote-PC-ip-address>`  
  User name "fk" and password "12345678".
- Info: To call `/usr/bin/raspi-config` script in non-interactive mode,  
see
[https://forums.raspberrypi.com/viewtopic.php?t=21632](https://forums.raspberrypi.com/viewtopic.php?t=21632)
## Change standard password of user
```
passwd
```

## Intial settings: Define helper functions and environmental variables 
```
#!/bin/bash

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
_DOMAIN="ladomain"
_ROUTERS="192.168.2.1"
_NAMESERVERS="192.168.2.1"
_NTPSERVER="192.168.2.1"
_LOCALELINE="de_DE.UTF-8 UTF-8"
            # de_DE ISO-8859-1
            # de_DE@euro ISO-8859-15
_LOGPATH=/home/fk/logs/install-logs/
export LOCALE="$(echo ${_LOCALELINE} | cut -f1 -d " ")"


if is_pi ; then
  if [ -e /proc/device-tree/chosen/os_prefix ]; then
    PREFIX="$(cat /proc/device-tree/chosen/os_prefix)"
  fi
  _CMDLINE="/boot/${PREFIX}cmdline.txt"
else
  _CMDLINE=/proc/cmdline
fi


_SW2INSTALL="pv xterm smartmontools geeqie xserver-xorg-input-evdev xinput-calibrator matchbox-keyboard git gcc build-essential cmake v4l-utils ffmpeg vlc vlc-bin autoconf-archive gnu-standards autoconf-doc dh-make gettext-doc libasprintf-dev libgettextpo-dev libtool-doc gfortran mplayer gnome-mplayer gecko-mediaplayer gphoto2 parted gparted iftop net-tools netstat-nat netcat fbi autocutsel epiphany-browser gpsd gpsd-clients python-gps python-gobject-2-dbg python-gtk2-doc devhelp python-gdbm-dbg python-tk-dbg iw wpasupplicant wireless-tools python-pil.imagetk libjpeg62-turbo libjpeg62-turbo-dev libavformat-dev python-pil-doc python-pil.imagetk-dbg python-doc python-examples python-pil.imagetk libjpeg62-turbo libjpeg62-turbo-dev libavcodec-dev libc6-dev zlib1g-dev libpq5 libpq-dev vim exuberant-ctags vim-doc vim-scripts libtemplate-perl libtemplate-perl-doc libtemplate-plugin-gd-perl libtemplate-plugin-xml-perl screen realvnc-vnc-server realvnc-vnc-viewer colord-sensor-argyll foomatic-db cups printer-driver-hpcups hplip printer-driver-cups-pdf antiword docx2txt gutenprint-locales ooo2dbk gutenprint-doc unpaper realvnc-vnc-server realvnc-vnc-viewer hdparm nfs-kernel-server nfs-common autofs fail2ban ntfs-3g hfsutils hfsprogs exfat-fuse iotop evince argyll-doc gir1.2-colordgtk-1.0 codeblocks ca-certificates-java openjdk-8-jre-headless openjdk-8-jre openjdk-8-jdk-headless openjdk-8-jdk icedtea-netx icedtea-8-plugin eclipse ninja-build xpp spf-tools-perl swaks monit openprinting-ppds foomatic-db-gutenprint gimp xpaint libjpeg-progs ufraw gfortran-6-doc libgfortran3-dbg libcoarrays-dev ghostscript-x xfsprogs reiserfsprogs reiser4progs jfsutils mtools yelp kpartx dmraid gpart gthumb pdftk gimp-gutenprint ijsgutenprint apmd hfsutils-tcltk hplip-doc hplip-gui python3-notify2 system-config-printer imagemagick-doc autotrace enscript gnuplot grads graphviz hp2xx html2ps libwmf-bin povray radiance texlive-binaries fig2dev libgtk2.0-doc libdigest-hmac-perl libgssapi-perl fonts-dustin libgda-5.0-bin libgda-5.0-mysql libgda-5.0-postgres libgmlib1-dbg libgmtk1-dbg gpgsm libdata-dump-perl libcrypt-ssleay-perl inkscape libparted-dev postgresql-doc sg3-utils snmp-mibs-downloader libauthen-ntlm-perl m4-doc mailutils-mh mailutils-doc docbook-xsl libmail-box-perl psutils hpijs-ppds magicfilter python-gpgme python-pexpect-doc python3-renderpm-dbg python-reportlab-doc bind9 bind9utils ctdb ldb-tools smbldap-tools winbind ufw byobu gsmartcontrol smart-notifier openssl-blacklist tcl-tclreadline xfonts-cyrillic vnstat tcpdump unzip pkg-config libjpeg-dev libpng-dev libtiff-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libgtk-3-dev libcanberra-gtk* libatlas-base-dev python3-dev libblas-doc liblapack-doc liblapack-dev liblapack-doc-man libcairo2-doc icu-doc liblzma-doc libxext-doc iperf aptitude firefox-esr samba samba-common-bin smbclient btrfs-progs btrfs-tools python-dev python-pip ffmpeg libffi-dev libxml2-dev libxslt-dev libcairo2 libgeos++-dev libgeos-dev libgeos-doc libjpeg-dev libtiff5-dev libpng-dev libfreetype6-dev libgif-dev libgtk-3-dev libxml2-dev libpango1.0-dev libcairo2-dev libspiro-dev python3-dev ninja-build cmake build-essential gettext keepassx"


# -------------------------------------------------------------------------------
# First action(s)...
# -------------------------------------------------------------------------------
mkdir -p "${_LOGPATH}"


# -------------------------------------------------------------------------------
# Set LOCALE
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_change_locale "${LOCALE}"
fi
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

  # use network manager instead of dhcpcd
  sudo apt -y install network-manager network-manager-gnome
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
# Enable ssh permanently   (0=enable, 1=disable)
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
Background information regarding predictable network interface names:
- [https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/](https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/)
- [https://www.freedesktop.org/software/systemd/man/systemd.net-naming-scheme.html](https://www.freedesktop.org/software/systemd/man/systemd.net-naming-scheme.html)

The predictable name for eth0 can be found with:  
`udevadm test-builtin net_id /sys/class/net/eth0 | grep '^ID_NET_NAME_'`

With current `raspi-config` (2023-07-08) the predictable network names will not be enabled.  
Therefore a workaround is mentioned here in the
[Raspberry Pi Forum](https://forums.raspberrypi.com/viewtopic.php?t=258195).  
See also [https://wiki.debian.org/NetworkInterfaceNames#THE_.22PERSISTENT_NAMES.22_SCHEME](https://wiki.debian.org/NetworkInterfaceNames#THE_.22PERSISTENT_NAMES.22_SCHEME).
```
# -------------------------------------------------------------------------------
# Use predictable network interface names   (0=enable, 1=disable)
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_net_names 0
  if [ -e /etc/systemd/network/99-default.link ] ; then
    sudo rm -f /etc/systemd/network/99-default.link
  fi
  # workaround in order to enable predictable network interfaces:
  echo "[Match]"                     | sudo tee -a /etc/systemd/network/99-default.link
  echo "OriginalName=*"              | sudo tee -a /etc/systemd/network/99-default.link
  echo ""                            | sudo tee -a /etc/systemd/network/99-default.link
  echo "[Link]"                      | sudo tee -a /etc/systemd/network/99-default.link
  echo "NamePolicy=mac"              | sudo tee -a /etc/systemd/network/99-default.link
  echo "MACAddressPolicy=persistent" | sudo tee -a /etc/systemd/network/99-default.link
fi


# -------------------------------------------------------------------------------
# Removing ip-info from $_CMDLINE
# -------------------------------------------------------------------------------
if is_pi ; then
  echo ""
  ### sudo sed -i ${_CMDLINE} -e "s/ip=[0-9]*.[0-9]*.[0-9]*.[0-9]* *//"
fi


# -------------------------------------------------------------------------------
# Use "network manager" (2) instead of "dhcpcd" (1) 
# -------------------------------------------------------------------------------
if is_pi ; then
  sudo raspi-config nonint do_netconf 2
  sudo systemctl stop dhcpcd.service
  sudo systemctl disable dhcpcd.service
  sudo systemctl enable networking
  sudo systemctl restart networking
  sudo systemctl status networking
fi


# -------------------------------------------------------------------------------
# Set static IP address for "eth0" i.e. the en* network device
# -------------------------------------------------------------------------------
if is_pi ; then
  ### netdevice=$(ip -o link show | awk -F': ' '{print $2}' | grep "^en*")
  netdevice=$(udevadm test-builtin net_id /sys/class/net/enxdca632250905 2>/dev/null | grep 'ID_NET_NAME_MAC=' | cut -d= -f2-)
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
echo "Now do a sudo reboot"
```

Howto set a static IP address, see [https://linux.fernandocejas.com/docs/how-to/set-static-ip-address](https://linux.fernandocejas.com/docs/how-to/set-static-ip-address) .  
For further `nmcli` commands, see e.g. [https://opensource.com/article/20/7/nmcli](https://opensource.com/article/20/7/nmcli) ...
```
nmcli general
nmcli connection show
nmcli device status
nmcli device show
nmcli device show 
```

nmcli device show enxdca632250905






# TODO : GO ON HERE ...
## Set secondary network IP address and/or further interface 

## Reduce number of writes to SD-card
### Create certain folders as RAM-disk (=tmpfs)
TODO: check
```
if ! grep -q "/var/tmp" /etc/fstab ; then
  echo "# ---- special settings ----------------------------------------------------------------- " | sudo tee -a /etc/fstab
  echo "#/run, /var/run, /run/lock, /var/run/lock will be automatically created by default - tmpfs" | sudo tee -a /etc/fstab
  echo "tmpfs /tmp              tmpfs defaults,noatime,nosuid,size=100m                 0 0"        | sudo tee -a /etc/fstab
  echo "tmpfs /var/tmp          tmpfs defaults,noatime,nosuid,size=30m                  0 0"        | sudo tee -a /etc/fstab
  echo "#tmpfs /var/log          tmpfs defaults,noatime,mode=0755,size=30m               0 0"        | sudo tee -a /etc/fstab
  echo "tmpfs /var/spool/mqueue tmpfs defaults,noatime,nosuid,mode=0700,gid=12,size=30m 0 0"        | sudo tee -a /etc/fstab
  echo "tmpfs /var/cache/samba  tmpfs nodev,nosuid,noatime,size=50m                     0 0"        | sudo tee -a /etc/fstab
fi
```
### Disable swap-file
TODO: check
```
sudo dphys-swapfile swapoff
sudo systemctl disable dphys-swapfile
```

## Secure ssh
TODO: check
```
# sudo vi /etc/ssh/sshd_config     # --> PermitRootLogin no
# sudo vi /etc/fail2ban/jail.conf  # --> bantime=10m   maxretry=5  (default)
#   [sshd]
#   enabled = true
#   port = ssh
#   filter = sshd
#   logpath = /var/log/auth.log
#   maxretry = 3
#   bantime = 10m
```

## No cleanup of /dev/shm at ssh-logout
TODO: Check if this is still the case!!!

## VNC setup
Check the setup if it works and if also the window-manager does work...
```
sudo systemctl start vncserver-x11-serviced.service
vncserver -geometry 1800x1000
sudo systemctl stop vncserver-x11-serviced.service
```

## Automatic nightly reboot at 2:30
```
sudo crontab -e
   #   30 2 * * * /sbin/shutdown -r now
```

## Setup of ntp time server
TODO: Check settings for what they are good for???
```
if ! grep -q "server ${_NTPSERVER}" /etc/ntp.conf ; then
  sudo sed -i /etc/ntp.conf -e "s/^pool /#pool /"
  echo ""                                                      | sudo tee -a /etc/ntp.conf
  echo ""                                                      | sudo tee -a /etc/ntp.conf
  echo "# set an internal NTP server (min ca. 1h=68min=2^12)"  | sudo tee -a /etc/ntp.conf
  echo "server ${_NTPSERVER} iburst minpoll 12 maxpoll 17"     | sudo tee -a /etc/ntp.conf
  echo "#server 0.de.pool.ntp.org  minpoll 12 maxpoll 17"      | sudo tee -a /etc/ntp.conf
  echo "#server 1.de.pool.ntp.org  minpoll 12 maxpoll 17"      | sudo tee -a /etc/ntp.conf
  echo "#server 2.de.pool.ntp.org  minpoll 12 maxpoll 17"      | sudo tee -a /etc/ntp.conf
  echo "#server 3.de.pool.ntp.org  minpoll 12 maxpoll 17"      | sudo tee -a /etc/ntp.conf
  echo "#server ptbtime1.ptb.de    minpoll 12 maxpoll 17"      | sudo tee -a /etc/ntp.conf
  echo "# update by hand (in case of trouble):"                | sudo tee -a /etc/ntp.conf
  echo "#   sudo systemctl stop ntp"                           | sudo tee -a /etc/ntp.conf
  echo "#   sudo ntpd -qg"                                     | sudo tee -a /etc/ntp.conf
  echo "#   sudo systemctl start ntp"                          | sudo tee -a /etc/ntp.conf
  echo "#   ntpq -p"                                           | sudo tee -a /etc/ntp.conf
  echo ""                                                      | sudo tee -a /etc/ntp.conf
  echo ""                                                      | sudo tee -a /etc/ntp.conf
  sudo systemctl restart ntp | tee -a ${LOGFILE}
fi
sudo systemctl status ntp
ntpq -p
```

## Samba setup
TODO: Check settings for what they are good for???
```
echo "samba-common    samba-common/do_debconf boolean true"  | sudo debconf-set-selections
echo "samba-common    samba-common/dhcp       boolean false" | sudo debconf-set-selections
```

## Scan open ports and close them
TODO: check also regarding VNC-server
```
nmap -p- 192.168.2.163
nmap -sT -p 1-65535 192.168.2.163
```
 
## Collect and save weather-data

## Include "multiverse" repository
TODO: following is not yet working:
```
sudo add-apt-repository multiverse
sudo apt update
sudo apt install ubuntu-restricted-extras
```

## Mount usbhdd
Check if still needed:
```
sudo vi /boot/config.txt
  # max_usb_current=1
```
```
# Create mount-point:
_USBHDDMNTPT=/mnt/usbhdd01
if [ ! -e "${_USBHDDMNTPT}" ] ; then
  sudo mkdir -p "${_USBHDDMNTPT}"
fi

# Check available disks:
sudo fdisk -l

# Create partition table of USBHDD:
sudo fdisk /dev/sda
  # --> n p 1    t 83    p    w

# Format USBHDD:
sudo mkfs.ext3 -m 1 -L USBHDD01 /dev/sda1

# Get blkid of USBHDD:
sudo blkid /dev/sda1
  # --> /dev/sda1: LABEL="USBHDD01" UUID="c6824e93-4e82-4086-b977-f4dd2bf1837b" SEC_TYPE="ext2" BLOCK_SIZE="4096" TYPE="ext3" PARTUUID="7306d5d2-01"

# Edit /etc/fstab:
# TODO: check the actual settings of the old Raspi
# UUID=[UUID] /mnt/usbhdd01 [TYPE] defaults,auto,users,rw,nofail,noatime 0 3

```

Check USBHDD using SMART
TODO: check
```
sudo smartctl -d sat --smart=on --offlineauto=on --saveauto=on /dev/sda
sudo smartctl -d sat -a /dev/sda
sudo hdparm -I /dev/sda
sudo smartctl -d sat -t short /dev/sda
```

## Configure 10inch touchscreen
TODO: check
```
sudo cp /usr/share/X11/xorg.conf.d/10-evdev.conf /usr/share/X11/xorg.conf.d/45-evdev.conf
echo ''                                                  | sudo tee    /usr/share/X11/xorg.conf.d/99-calibration.conf
echo 'Section "InputClass"'                              | sudo tee -a /usr/share/X11/xorg.conf.d/99-calibration.conf
echo '  Identifier "calibration"'                        | sudo tee -a /usr/share/X11/xorg.conf.d/99-calibration.conf
echo '  MatchProduct "eGalax Inc. USB TouchController"'  | sudo tee -a /usr/share/X11/xorg.conf.d/99-calibration.conf
echo '  Option "Calibration" "4066 -42 4046 15"'         | sudo tee -a /usr/share/X11/xorg.conf.d/99-calibration.conf
echo '  Option "SwapAxes" "1"'                           | sudo tee -a /usr/share/X11/xorg.conf.d/99-calibration.conf
echo '  Driver "evdev"'                                  | sudo tee -a /usr/share/X11/xorg.conf.d/99-calibration.conf
echo 'EndSection'                                        | sudo tee -a /usr/share/X11/xorg.conf.d/99-calibration.conf
echo ''                                                  | sudo tee -a /usr/share/X11/xorg.conf.d/99-calibration.conf
```
TODO: check
```
if ! grep -q "hdmi configuration for 10inch touchscreen" /boot/config.txt ; then
  echo ""                                              | sudo tee -a /boot/config.txt
  echo "# hdmi configuration for 10inch touchscreen:"  | sudo tee -a /boot/config.txt
  echo "hdmi_force_hotplug=1"                          | sudo tee -a /boot/config.txt
  echo "hdmi_group=2"                                  | sudo tee -a /boot/config.txt
  echo "hdmi_mode=27"                                  | sudo tee -a /boot/config.txt
  echo ""                                              | sudo tee -a /boot/config.txt
fi
```

## Setup watchdog
TODO: check
```
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

```

## Stop / disable superfluous services
TODO

### Services

### Regular update jobs


# Optional setups
## Network print server
See also [https://www.tomshardware.com/how-to/raspberry-pi-print-server](https://www.tomshardware.com/how-to/raspberry-pi-print-server)  
or [https://medium.com/@anirudhgupta281998/setup-a-print-server-using-raspberry-pi-cups-part-2-2d6d48ccdc32](https://medium.com/@anirudhgupta281998/setup-a-print-server-using-raspberry-pi-cups-part-2-2d6d48ccdc32)  
or [https://opensource.com/article/18/3/print-server-raspberry-pi](https://opensource.com/article/18/3/print-server-raspberry-pi)
- Make sure cups is installed
  ```
  sudo apt install cups
  ```
- Check if the standard user is already member of group `lpadmin` by: `id $USER`.  
  If not, do a
  ```
  sudo usermod -a -G lpadmin $USER`
  ```
- Does the Raspi already have a static IP-address? Check `/etc/dhcpcd.conf`. 
- Make CUPS accessible across the network
  ```
  sudo cupsctl --remote-any
  ```
- Connect with port `631` of the Raspi using a webbrowser.  
  Configure the printer:
  - `Administration` -> `Add Printer`
  - Select local printer
  - Share this printer (checkbox)
  - Select model (first entry: HP LaserJet 1100, hpcups 3.21.2 (en))
  - Set default options (Check `Media Size: A4` and `Print Quality: Best`)
  - Goto `Printers`-Tab and print a test page
- TODO:
  - Check if SAMBA settings are needed to access the printer from Windows
  - Check if these settings are persistent





# Further interesting topics


## Retrieve informations
```
# Linux kernel version
uname -a

# OS release version
cat /etc/os-release

# Rasperry Pi model
cat /sys/firmware/devicetree/base/model 
```

## Check network performance
```
iperf -s               # at server
iperf -c 192.168.x.y   # at client
```

## Overlay Filesystem
See `sudo raspi-config` *-> Performance -> Overlay file system* and also...  
- [https://github.com/ghollingworth/overlayfs](https://github.com/ghollingworth/overlayfs)
- [https://yagrebu.net/unix/rpi-overlay.md](https://yagrebu.net/unix/rpi-overlay.md)

## Network print server 