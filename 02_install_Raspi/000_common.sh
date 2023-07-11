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
export _LOGPATH=$HOME/logs/install-logs/
export LOCALE="$(echo ${_LOCALELINE} | cut -f1 -d " ")"


if is_pi ; then
  if [ -e /proc/device-tree/chosen/os_prefix ]; then
    PREFIX="$(cat /proc/device-tree/chosen/os_prefix)"
  fi
  export _CMDLINE="/boot/${PREFIX}cmdline.txt"
else
  export _CMDLINE=/proc/cmdline
fi


export _SW2INSTALL="pv xterm smartmontools geeqie xserver-xorg-input-evdev xinput-calibrator matchbox-keyboard git gcc build-essential cmake v4l-utils ffmpeg vlc vlc-bin autoconf-archive gnu-standards autoconf-doc dh-make gettext-doc libasprintf-dev libgettextpo-dev libtool-doc gfortran mplayer gnome-mplayer gecko-mediaplayer gphoto2 parted gparted iftop net-tools netstat-nat netcat fbi autocutsel epiphany-browser gpsd gpsd-clients python-gps python-gobject-2-dbg python-gtk2-doc devhelp python-gdbm-dbg python-tk-dbg iw wpasupplicant wireless-tools python-pil.imagetk libjpeg62-turbo libjpeg62-turbo-dev libavformat-dev python-pil-doc python-pil.imagetk-dbg python-doc python-examples python-pil.imagetk libjpeg62-turbo libjpeg62-turbo-dev libavcodec-dev libc6-dev zlib1g-dev libpq5 libpq-dev vim exuberant-ctags vim-doc vim-scripts libtemplate-perl libtemplate-perl-doc libtemplate-plugin-gd-perl libtemplate-plugin-xml-perl screen realvnc-vnc-server realvnc-vnc-viewer colord-sensor-argyll foomatic-db cups printer-driver-hpcups hplip printer-driver-cups-pdf antiword docx2txt gutenprint-locales ooo2dbk gutenprint-doc unpaper realvnc-vnc-server realvnc-vnc-viewer hdparm nfs-kernel-server nfs-common autofs fail2ban ntfs-3g hfsutils hfsprogs exfat-fuse iotop evince argyll-doc gir1.2-colordgtk-1.0 codeblocks ca-certificates-java openjdk-8-jre-headless openjdk-8-jre openjdk-8-jdk-headless openjdk-8-jdk icedtea-netx icedtea-8-plugin eclipse ninja-build xpp spf-tools-perl swaks monit openprinting-ppds foomatic-db-gutenprint gimp xpaint libjpeg-progs ufraw gfortran-6-doc libgfortran3-dbg libcoarrays-dev ghostscript-x xfsprogs reiserfsprogs reiser4progs jfsutils mtools yelp kpartx dmraid gpart gthumb pdftk gimp-gutenprint ijsgutenprint apmd hfsutils-tcltk hplip-doc hplip-gui python3-notify2 system-config-printer imagemagick-doc autotrace enscript gnuplot grads graphviz hp2xx html2ps libwmf-bin povray radiance texlive-binaries fig2dev libgtk2.0-doc libdigest-hmac-perl libgssapi-perl fonts-dustin libgda-5.0-bin libgda-5.0-mysql libgda-5.0-postgres libgmlib1-dbg libgmtk1-dbg gpgsm libdata-dump-perl libcrypt-ssleay-perl inkscape libparted-dev postgresql-doc sg3-utils snmp-mibs-downloader libauthen-ntlm-perl m4-doc mailutils-mh mailutils-doc docbook-xsl libmail-box-perl psutils hpijs-ppds magicfilter python-gpgme python-pexpect-doc python3-renderpm-dbg python-reportlab-doc bind9 bind9utils ctdb ldb-tools smbldap-tools winbind ufw byobu gsmartcontrol smart-notifier openssl-blacklist tcl-tclreadline xfonts-cyrillic vnstat tcpdump unzip pkg-config libjpeg-dev libpng-dev libtiff-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libgtk-3-dev libcanberra-gtk* libatlas-base-dev python3-dev libblas-doc liblapack-doc liblapack-dev liblapack-doc-man libcairo2-doc icu-doc liblzma-doc libxext-doc iperf aptitude firefox-esr samba samba-common-bin smbclient btrfs-progs btrfs-tools python-dev python-pip ffmpeg libffi-dev libxml2-dev libxslt-dev libcairo2 libgeos++-dev libgeos-dev libgeos-doc libjpeg-dev libtiff5-dev libpng-dev libfreetype6-dev libgif-dev libgtk-3-dev libxml2-dev libpango1.0-dev libcairo2-dev libspiro-dev python3-dev ninja-build cmake build-essential gettext keepassx"


# -------------------------------------------------------------------------------
# Create path for log files, if path does not yet exist
# -------------------------------------------------------------------------------
[ -d "${_LOGPATH}" ] || mkdir -p "${_LOGPATH}"


