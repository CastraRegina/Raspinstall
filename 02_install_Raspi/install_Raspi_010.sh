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


_SW2INSTALL="pv xterm smartmontools geeqie xserver-xorg-input-evdev xinput-calibrator matchbox-keyboard git gcc build-essential cmake v4l-utils ffmpeg vlc vlc-bin autoconf-archive gnu-standards autoconf-doc dh-make gettext-doc libasprintf-dev libgettextpo-dev libtool-doc gfortran mplayer gnome-mplayer gecko-mediaplayer gphoto2 parted gparted iftop net-tools netstat-nat netcat fbi autocutsel epiphany-browser gpsd gpsd-clients python-gps python-gobject-2-dbg python-gtk2-doc devhelp python-gdbm-dbg python-tk-dbg iw wpasupplicant wireless-tools python-pil.imagetk libjpeg62-turbo libjpeg62-turbo-dev libavformat-dev python-pil-doc python-pil.imagetk-dbg python-doc python-examples python-pil.imagetk libjpeg62-turbo libjpeg62-turbo-dev libavcodec-dev libc6-dev zlib1g-dev libpq5 libpq-dev vim exuberant-ctags vim-doc vim-scripts libtemplate-perl libtemplate-perl-doc libtemplate-plugin-gd-perl libtemplate-plugin-xml-perl screen realvnc-vnc-server realvnc-vnc-viewer colord-sensor-argyll foomatic-db cups printer-driver-hpcups hplip printer-driver-cups-pdf antiword docx2txt gutenprint-locales ooo2dbk gutenprint-doc unpaper realvnc-vnc-server realvnc-vnc-viewer hdparm nfs-kernel-server nfs-common autofs fail2ban ntfs-3g hfsutils hfsprogs exfat-fuse iotop evince argyll-doc gir1.2-colordgtk-1.0 codeblocks ca-certificates-java openjdk-8-jre-headless openjdk-8-jre openjdk-8-jdk-headless openjdk-8-jdk icedtea-netx icedtea-8-plugin eclipse ninja-build xpp spf-tools-perl swaks monit openprinting-ppds foomatic-db-gutenprint gimp xpaint libjpeg-progs ufraw gfortran-6-doc libgfortran3-dbg libcoarrays-dev ghostscript-x xfsprogs reiserfsprogs reiser4progs jfsutils mtools yelp kpartx dmraid gpart gthumb pdftk gimp-gutenprint ijsgutenprint apmd hfsutils-tcltk hplip-doc hplip-gui python3-notify2 system-config-printer imagemagick-doc autotrace enscript gnuplot grads graphviz hp2xx html2ps libwmf-bin povray radiance texlive-binaries fig2dev libgtk2.0-doc libdigest-hmac-perl libgssapi-perl fonts-dustin libgda-5.0-bin libgda-5.0-mysql libgda-5.0-postgres libgmlib1-dbg libgmtk1-dbg gpgsm libdata-dump-perl libcrypt-ssleay-perl inkscape libparted-dev postgresql-doc sg3-utils snmp-mibs-downloader libauthen-ntlm-perl m4-doc mailutils-mh mailutils-doc docbook-xsl libmail-box-perl psutils hpijs-ppds magicfilter python-gpgme python-pexpect-doc python3-renderpm-dbg python-reportlab-doc bind9 bind9utils ctdb ldb-tools smbldap-tools winbind ufw byobu gsmartcontrol smart-notifier openssl-blacklist tcl-tclreadline xfonts-cyrillic vnstat tcpdump unzip pkg-config libjpeg-dev libpng-dev libtiff-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libgtk-3-dev libcanberra-gtk* libatlas-base-dev python3-dev libblas-doc liblapack-doc liblapack-dev liblapack-doc-man libcairo2-doc icu-doc liblzma-doc libxext-doc iperf aptitude firefox-esr samba samba-common-bin smbclient btrfs-progs btrfs-tools python-dev python-pip ffmpeg libffi-dev libxml2-dev libxslt-dev libcairo2 libgeos++-dev libgeos-dev libgeos-doc libjpeg-dev libtiff5-dev libpng-dev libfreetype6-dev libgif-dev libgtk-3-dev libxml2-dev libpango1.0-dev libcairo2-dev libspiro-dev python3-dev ninja-build cmake build-essential gettext keepassx"


# -------------------------------------------------------------------------------
# First action(s)...
# -------------------------------------------------------------------------------
mkdir -p "${_LOGPATH}"



#################################################################################
#################################################################################
#################################################################################



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



#################################################################################
#################################################################################
#################################################################################



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



#################################################################################
#################################################################################
#################################################################################



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



#################################################################################
#################################################################################
#################################################################################



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
# Set static IP address for "eth0" i.e. the en* network device
# -------------------------------------------------------------------------------
if is_pi ; then
  ### netdevice=$(ip -o link show | awk -F': ' '{print $2}' | grep "^en*")
  netdevice=$(udevadm test-builtin net_id /sys/class/net/enxdca632250905 2>/dev/null | grep 'ID_NET_NAME_MAC=' | cut -d= -f2-)
  if ! sed -e 's/#.*$//g' /etc/dhcpcd.conf | grep -q -P 'interface +'"${netdevice}" ; then
    echo ""                                            | sudo tee -a /etc/dhcpcd.conf
    echo "# static IP configuration"                   | sudo tee -a /etc/dhcpcd.conf
    echo "interface ${netdevice}"                      | sudo tee -a /etc/dhcpcd.conf
    echo "static ip_address=${_IPADDRESS}/24"          | sudo tee -a /etc/dhcpcd.conf
    echo "static routers=${_ROUTERS}"                  | sudo tee -a /etc/dhcpcd.conf
    echo "static domain_name_servers=${_NAMESERVERS}"  | sudo tee -a /etc/dhcpcd.conf
    echo ""                                            | sudo tee -a /etc/dhcpcd.conf
  fi
fi

