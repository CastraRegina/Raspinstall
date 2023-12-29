#!/bin/bash

# -------------------------------------------------------------------------------
# This file is sourced by every other script.
#   It mainly sets variables and defines general functions.
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Define helper function(s)
# -------------------------------------------------------------------------------
is_pi () { # returns 0=true if this machine is a Rasperry Pi, i.e. an "arm"
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
export _HOSTNAME="lasrv04"
export _IPADDRESS="192.168.2.4"
export _DOMAIN="ladomain"
export _ROUTERS="192.168.2.1"
export _NAMESERVERS="192.168.2.1"
export _NTPSERVER="192.168.2.1"
export _LOCALELINE="de_DE.UTF-8 UTF-8"
            # de_DE ISO-8859-1
            # de_DE@euro ISO-8859-15
export _LOGPATH=$HOME/logs/install/
export _BINPATH=$HOME/bin
export LOCALE="$(echo ${_LOCALELINE} | cut -f1 -d " ")"


if is_pi ; then
  if [ -e /proc/device-tree/chosen/os_prefix ]; then
    PREFIX="$(tr -d '\0' </proc/device-tree/chosen/os_prefix)"
  fi
  export _CMDLINE="/boot/${PREFIX}cmdline.txt"
else
  export _CMDLINE=/proc/cmdline
fi
export -f is_pi


export _SW2INSTALL="pv xterm nmap smartmontools geeqie xserver-xorg-input-evdev xinput-calibrator matchbox-keyboard git"
export _SW2INSTALL="$_SW2INSTALL gcc build-essential cmake v4l-utils ffmpeg vlc vlc-bin autoconf-archive gnu-standards"
export _SW2INSTALL="$_SW2INSTALL autoconf-doc dh-make gettext-doc libasprintf-dev libgettextpo-dev libtool-doc gfortran"
export _SW2INSTALL="$_SW2INSTALL mplayer gnome-mplayer gecko-mediaplayer gphoto2 parted gparted rdiff-backup sysstat"
export _SW2INSTALL="$_SW2INSTALL iftop net-tools netstat-nat netcat fbi autocutsel epiphany-browser gpsd gpsd-clients"
export _SW2INSTALL="$_SW2INSTALL python-gps python-gobject-2-dbg python-gtk2-doc devhelp python-gdbm-dbg python-tk-dbg"
export _SW2INSTALL="$_SW2INSTALL iw wpasupplicant wireless-tools python-pil.imagetk libjpeg62-turbo libjpeg62-turbo-dev"
export _SW2INSTALL="$_SW2INSTALL libavformat-dev python-pil-doc python-pil.imagetk-dbg python-doc python-examples"
export _SW2INSTALL="$_SW2INSTALL python-pil.imagetk libjpeg62-turbo libjpeg62-turbo-dev libavcodec-dev libc6-dev"
export _SW2INSTALL="$_SW2INSTALL zlib1g-dev libpq5 libpq-dev vim exuberant-ctags vim-doc vim-scripts libtemplate-perl"
export _SW2INSTALL="$_SW2INSTALL libtemplate-perl-doc libtemplate-plugin-gd-perl libtemplate-plugin-xml-perl screen"
export _SW2INSTALL="$_SW2INSTALL realvnc-vnc-server realvnc-vnc-viewer colord-sensor-argyll foomatic-db cups"
export _SW2INSTALL="$_SW2INSTALL printer-driver-hpcups hplip printer-driver-cups-pdf hp-ppd antiword docx2txt"
export _SW2INSTALL="$_SW2INSTALL gutenprint-locales ooo2dbk gutenprint-doc unpaper"
export _SW2INSTALL="$_SW2INSTALL hdparm nfs-kernel-server nfs-common autofs fail2ban ntfs-3g"
export _SW2INSTALL="$_SW2INSTALL hfsutils hfsprogs exfat-fuse iotop evince argyll-doc gir1.2-colordgtk-1.0 codeblocks"
export _SW2INSTALL="$_SW2INSTALL ca-certificates-java openjdk-8-jre-headless openjdk-8-jre openjdk-8-jdk-headless"
export _SW2INSTALL="$_SW2INSTALL openjdk-8-jdk icedtea-netx icedtea-8-plugin eclipse ninja-build xpp spf-tools-perl"
export _SW2INSTALL="$_SW2INSTALL swaks monit openprinting-ppds gimp xpaint libjpeg-progs ufraw"
export _SW2INSTALL="$_SW2INSTALL gfortran-6-doc libgfortran3-dbg libcoarrays-dev ghostscript-x xfsprogs reiserfsprogs"
export _SW2INSTALL="$_SW2INSTALL reiser4progs jfsutils mtools yelp kpartx dmraid gpart gthumb pdftk gimp-gutenprint"
export _SW2INSTALL="$_SW2INSTALL ijsgutenprint apmd hfsutils-tcltk hplip-doc hplip-gui python3-notify2"
export _SW2INSTALL="$_SW2INSTALL system-config-printer imagemagick-doc autotrace enscript gnuplot grads graphviz"
export _SW2INSTALL="$_SW2INSTALL hp2xx html2ps libwmf-bin povray radiance texlive-binaries fig2dev libgtk2.0-doc"
export _SW2INSTALL="$_SW2INSTALL libdigest-hmac-perl libgssapi-perl fonts-dustin libgda-5.0-bin libgda-5.0-mysql"
export _SW2INSTALL="$_SW2INSTALL libgda-5.0-postgres libgmlib1-dbg libgmtk1-dbg gpgsm libdata-dump-perl"
export _SW2INSTALL="$_SW2INSTALL libcrypt-ssleay-perl inkscape libparted-dev postgresql-doc sg3-utils"
export _SW2INSTALL="$_SW2INSTALL snmp-mibs-downloader libauthen-ntlm-perl m4-doc mailutils-mh mailutils-doc"
export _SW2INSTALL="$_SW2INSTALL docbook-xsl libmail-box-perl psutils hpijs-ppds magicfilter python-gpgme"
export _SW2INSTALL="$_SW2INSTALL python-pexpect-doc python3-renderpm-dbg python-reportlab-doc bind9 bind9utils ctdb"
export _SW2INSTALL="$_SW2INSTALL ldb-tools smbldap-tools winbind ufw byobu gsmartcontrol smart-notifier"
export _SW2INSTALL="$_SW2INSTALL openssl-blacklist tcl-tclreadline xfonts-cyrillic vnstat tcpdump unzip pkg-config"
export _SW2INSTALL="$_SW2INSTALL libjpeg-dev libpng-dev libtiff-dev libswscale-dev libv4l-dev libxvidcore-dev"
export _SW2INSTALL="$_SW2INSTALL libx264-dev libgtk-3-dev libcanberra-gtk* libatlas-base-dev python3-dev libblas-doc"
export _SW2INSTALL="$_SW2INSTALL liblapack-doc liblapack-dev liblapack-doc-man libcairo2-doc icu-doc liblzma-doc"
export _SW2INSTALL="$_SW2INSTALL libxext-doc iperf aptitude firefox-esr samba samba-common-bin smbclient"
export _SW2INSTALL="$_SW2INSTALL btrfs-progs btrfs-tools python-dev python-pip ffmpeg libffi-dev libxml2-dev"
export _SW2INSTALL="$_SW2INSTALL libxslt-dev libcairo2 libgeos++-dev libgeos-dev libgeos-doc libjpeg-dev"
export _SW2INSTALL="$_SW2INSTALL libtiff5-dev libjpeg-turbo8-dev libopenjp2-7-dev liblcms2-dev libwebp-dev"
export _SW2INSTALL="$_SW2INSTALL tcl8.6-dev tk8.6-dev python3-tk libharfbuzz-dev libfribidi-dev libxcb1-dev"
export _SW2INSTALL="$_SW2INSTALL libpng-dev libfreetype6-dev libgif-dev libgtk-3-dev libxml2-dev libpango1.0-dev"
export _SW2INSTALL="$_SW2INSTALL libcairo2-dev libspiro-dev python3-dev ninja-build cmake build-essential gettext"
export _SW2INSTALL="$_SW2INSTALL chromium uhubctl watchdog ecryptfs-utils rsync lsof cryptsetup open-iscsi"
export _SW2INSTALL="$_SW2INSTALL usb-creator-gtk software-properties-common apt-transport-https wget libpam-mount"
export _SW2INSTALL="$_SW2INSTALL baobab gdebi-core retext dosfstools ssvnc krdc keepassxc oathtool wakeonlan"
export _SW2INSTALL="$_SW2INSTALL openssh-server fdupes"
export _SW2INSTALL="$_SW2INSTALL python3-pip-whl python3-setuptools-whl python3.10-venv"
export _SW2INSTALL="$_SW2INSTALL fontforge fontforge-common  libfontforge4 fontforge-doc fontforge-extras"
export _SW2INSTALL="$_SW2INSTALL python3-fontforge fonts-cantarell fonts-inconsolata libuninameslist1 potrace"

### use libjpeg-turbo8-dev instead of libjpeg8-dev

export _DISABLESERVICES="colord cups-browsed cups iscsid ModemManager monit nfs-blkmap nfs-idmapd nfs-mountd unattended-upgrades winbind wpa_supplicant"



# -------------------------------------------------------------------------------
# Create log & bin path, if path does not yet exist
# -------------------------------------------------------------------------------
[ -d "${_LOGPATH}" ] || mkdir -p "${_LOGPATH}"
[ -d "${_BINPATH}" ] || mkdir -p "${_BINPATH}"




# -------------------------------------------------------------------------------
# Helper function to copy/update a single file
#     copy a file specified by <$1=fullSrcFilepath> to <$2=fullDstDir>
#     if a destination-file already exists a backup is stored
# -------------------------------------------------------------------------------
function updateFile () {
  fullSrcFilepath="$1"
  fullDstDir="$2"
  
  datetime=$(date +"%Y%m%d-%H%M%S")
  file=$(basename "${fullSrcFilepath}")
  fullDstFilepath="${fullDstDir}"/"${file}"
  fullBckFilepath="${fullDstFilepath}"_"${datetime}"

  # create destination directory if it does not exist:
  [ ! -d "${fullDstDir}" ] && mkdir -p "${fullDstDir}"
  
  if [ -f "${fullDstFilepath}" ] ; then
    # file already exists in destination -> save a backup if it is different:
    if ! cmp -s "${fullSrcFilepath}" "${fullDstFilepath}" ; then
      # src file differs from destination file so create backup and then copy:
      mv "${fullDstFilepath}" "${fullBckFilepath}" 
      cp "${fullSrcFilepath}" "${fullDstDir}" 
    fi
  else
    # destination file does not exist yet --> just copy it to destination:
    cp "${fullSrcFilepath}" "${fullDstDir}" 
  fi
 
}
export -f updateFile



# -------------------------------------------------------------------------------
# Helper function to copy/update all files from <srcdir> to <dstdir>
#     copy all files from sourcefolder <$1=srcdir> to <$2=dstdir>
#     if a destination-file already exists a backup is stored
# -------------------------------------------------------------------------------
function updateDir () {
  export srcDir="$1"
  export dstDir="$2"
  oldDir="${PWD}"

  if [ "${srcDir}" == "${srcDir#/}" ] ; then
    # make it an absolute path:
    export srcDir="${oldDir}"/"${srcDir}" 
  fi
  if [ "${dstDir}" == "${dstDir#/}" ] ; then
    # make it an absolute path:
    export dstDir="${oldDir}"/"${dstDir}" 
  fi

  # remove / slash at end of srcDir and dstDir:
  export srcDir=$(echo "${srcDir}" | sed 's!/$!!')  
  export dstDir=$(echo "${dstDir}" | sed 's!/$!!')  

  cd "${srcDir}"
    # create destination folders (even if empty):
    find . -type d -exec bash -c '
      for filepath do
        relPath=$(echo "${filepath}" | sed "s!^\./!!" )
        [ -z "${relPath}" ] && fullDstDir="${dstDir}" || fullDstDir="${dstDir}"/"${relPath}"
        #echo "fullDstDir      ${fullDstDir}"
        mkdir -p "${fullDstDir}"
      done
    ' exec-sh {} +
   
    # copy the files into the destination folders:
    find . -type f -exec bash -c '
      for filepath do
        fullSrcFilepath="${srcDir}"/$(echo "${filepath}" | sed "s!^\./!!" )
        relPath=$(dirname "${filepath}" | sed "s!^\./!!" )
        [ -z "${relPath}" ] && fullDstDir="${dstDir}" || fullDstDir="${dstDir}"/"${relPath}"

        #echo "filepath        ${filepath}"
        #echo "relPath         ${relPath}"
        #echo "fullSrcFilepath ${fullSrcFilepath}" 
        #echo "fullDstDir      ${fullDstDir}"
        #echo "-------------------------------------"

        updateFile "${fullSrcFilepath}" "${fullDstDir}" 
      done
    ' exec-sh {} +
  cd "${oldDir}"
}
export -f updateDir
