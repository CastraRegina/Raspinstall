# Raspinstall  
Personal guideline to installing and setting up a Raspberry Pi.  
Scripts should be [idempotent](https://en.wikipedia.org/wiki/Idempotence):
    Regardless of how many times the script is again executed with the same input, the output must always remain the same.

# Content
- [Steps to do on the local Linux-PC](#steps-to-do-on-the-local-linux-pc)
- [Steps to do on the remote Raspberry Pi](#steps-to-do-on-the-remote-raspberry-pi)
- [Manual Setups](#manual-setups)
- [Miscellaneous](#miscellaneous)


# Steps to do on the local Linux-PC
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
This will extract the 11GB image file `2023-05-03-raspios-bullseye-armhf-full.img`.

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
  sed -i 's/^dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/g' ${CONFIGTXT}
fi
echo
```

Setup a new user for the headless Raspberry Pi as explained in   
[http://rptl.io/newuser](http://rptl.io/newuser) or  
[https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/configuration/headless.adoc](https://github.com/raspberrypi/documentation/blob/develop/documentation/asciidoc/computers/configuration/headless.adoc) ...  

**Do not forget to set a new password later!!!**
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

Fix LOCALE-error-message when installing packages, see  
[https://stackoverflow.com/questions/2499794/how-to-fix-a-locale-setting-warning-from-perl](https://stackoverflow.com/questions/2499794/how-to-fix-a-locale-setting-warning-from-perl)
```
# -------------------------------------------------------------------------------
# Fix LOCALE-error-message when installing packages
# -------------------------------------------------------------------------------
# sed -i 's/^AcceptEnv LANG LC_\*/#AcceptEnv LANG LC_\*/g' ${ROOTFSDIR}etc/ssh/sshd_config
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


# Steps to do on the remote Raspberry Pi
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


## Download scripts
```
git clone https://github.com/CastraRegina/Raspinstall.git
```
Remark:  
All `sh`-scripts source [`000_common.sh`](02_install_Raspi/000_common.sh)


## Update settings
Modify variables in [`000_common.sh`](02_install_Raspi/000_common.sh) 


## Run 010_install_initial_packages.sh
[`010_install_initial_packages.sh`](02_install_Raspi/010_install_initial_packages.sh)  
Runs for approximately 2 minutes.


## Run 020_update_packages.sh
[`020_update_packages.sh`](02_install_Raspi/020_update_packages.sh)  
Runs for approximately 7 minutes.


## Run 030_first_settings.sh
[`030_first_settings.sh`](02_install_Raspi/030_first_settings.sh)  
- Background information how to reduce number of writes to SD-card:
  - Create certain folders as RAM-disk (=tmpfs).  
    See [https://www.dzombak.com/blog/2021/11/Reducing-SD-Card-Wear-on-a-Raspberry-Pi-or-Armbian-Device.html](https://www.dzombak.com/blog/2021/11/Reducing-SD-Card-Wear-on-a-Raspberry-Pi-or-Armbian-Device.html)  
    or [https://domoticproject.com/extending-life-raspberry-pi-sd-card/](https://domoticproject.com/extending-life-raspberry-pi-sd-card/)
  - Disable swap-file  
    Check swap status:
    ```
    free -m
    cat /proc/swaps
    swapon -s
    ```



## Run 040R_set_predictable_network_names.sh
[`040R_set_predictable_network_names.sh`](02_install_Raspi/040R_set_predictable_network_names.sh)  
- Background information regarding predictable network interface names:
  - [https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/](https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/)
  - [https://www.freedesktop.org/software/systemd/man/systemd.net-naming-scheme.html](https://www.freedesktop.org/software/systemd/man/systemd.net-naming-scheme.html)  

  The predictable name for eth0 can be found with:  
  `udevadm test-builtin net_id /sys/class/net/eth0 | grep '^ID_NET_NAME_'`

  With current `raspi-config` (2023-07-08) the predictable network names will not be enabled.  
  Therefore a workaround is mentioned in the
  [Raspberry Pi Forum](https://forums.raspberrypi.com/viewtopic.php?t=258195).  
  See also [https://wiki.debian.org/NetworkInterfaceNames#THE_.22PERSISTENT_NAMES.22_SCHEME](https://wiki.debian.org/NetworkInterfaceNames#THE_.22PERSISTENT_NAMES.22_SCHEME).


**Do a reboot afterwards.**


## Run 050R_switch_to_network_manager.sh
[`050R_switch_to_network_manager.sh`](02_install_Raspi/050R_switch_to_network_manager.sh)  
Check after execution:
```
ifconfig -a
sudo systemctl status networking
nmcli connection 
```

**Do a reboot afterwards.**


## Run 060R_set_static_IP_address.sh
[`060R_set_static_IP_address.sh`](02_install_Raspi/060R_set_static_IP_address.sh)  
How to setup a static IP address, see [https://linux.fernandocejas.com/docs/how-to/set-static-ip-address](https://linux.fernandocejas.com/docs/how-to/set-static-ip-address) .  
For further `nmcli` commands, see e.g. [https://opensource.com/article/20/7/nmcli](https://opensource.com/article/20/7/nmcli) ...
```
nmcli general
nmcli connection show
nmcli device status
nmcli device show
```

**Do a reboot afterwards.**


## Run 080_install_further_packages.sh
[`080_install_further_packages.sh`](02_install_Raspi/080_install_further_packages.sh)  
Runs for approximately 33 minutes.  
Check if LOCALE error occurrs.


## Run 100_setup_ntp.sh
[`100_setup_ntp.sh`](02_install_Raspi/100_setup_ntp.sh)  


## Run 110_setup_watchdog.sh
[`110_setup_watchdog.sh`](02_install_Raspi/110_setup_watchdog.sh)  


## Run 120_disable_services.sh
[120_disable_services.sh](02_install_Raspi/120_disable_services.sh) 
to stop / disable "superfluous" services
- What services are running?
  ```
  sudo systemctl --type=service --state=running
  ```
- Stop and disable services
  - `avahi-daemon.service` - Avahi mDNS/DNS-SD Stack
  - `colord.service` - Manage, Install and Generate Color Profiles
  - `cups-browsed.service` - Make remote CUPS printers available locally
  - `cups.service` - CUPS Scheduler
  - `epmd.service` - Erlang Port Mapper Daemon
  - `iscsid.service` - iSCSI initiator daemon (iscsid)
  - `ModemManager.service` - Modem Manager
  - `monit.service` - LSB: service and resource monitoring daemon
  - `nfs-blkmap.service` - pNFS block layout mapping daemon
  - `nfs-idmapd.service` - NFSv4 ID-name mapping service
  - `nfs-mountd.service` - NFS Mount Daemon
  - `triggerhappy.service` - triggerhappy global hotkey daemon
  - `unattended-upgrades.service` - Unattended Upgrades Shutdown
  - `winbind.service` - Samba Winbind Daemon
  - `wpa_supplicant.service` - WPA supplicant

  Remark: `iscsid` and `nfs-*` services reappear after reboot.

- Regular apt update jobs are stopped by commenting-out all entries of  
  `/etc/apt/apt.conf.d/20auto-upgrades` and adding following lines:
  ```
  APT::Periodic::Update-Package-Lists "0";
  APT::Periodic::Download-Upgradeable-Packages "0";
  APT::Periodic::AutocleanInterval "0";
  APT::Periodic::Unattended-Upgrade "0";
  ```

## Next steps
- Setup [Automatic nightly reboot at 2:30](#automatic-nightly-reboot-at-230)
- Install and [Setup "Log Weather Data"](#setup-log-weather-data)
  - Check setup of [Automatic nightly reboot at 2:30](#automatic-nightly-reboot-at-230)
  - Add crontab-entries to start "Log-Weather-Data" at boot-time
- [Setup ssh github access](#setup-ssh-github-access)


# TODO : GO ON HERE ...

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
 
## Include "multiverse" repository
TODO: following is not yet working:
```
sudo add-apt-repository multiverse
sudo apt update
sudo apt install ubuntu-restricted-extras
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






---
# Manual setups


## Automatic nightly reboot at 2:30
```
sudo crontab -e
   #   30 2 * * * /sbin/shutdown -r now
```


## Mount usbhdd permanently
Increase USB current limit
```
sudo vi /boot/config.txt
max_usb_current=1     # support in sum up to 1.2A on all USB ports
```
Setup steps
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
```
sudo smartctl -d sat --smart=on --offlineauto=on --saveauto=on /dev/sda
sudo smartctl -d sat -a /dev/sda
sudo hdparm -I /dev/sda
sudo smartctl -d sat -t short /dev/sda
```


## (Secure ssh using fail2ban)
UPDATE: Looks like the current default with `2023-05-03-raspios-bullseye-armhf-full.img` is already configured with reasonable settings (bantime=10m, maxretry=5).
```
# sudo vi /etc/ssh/sshd_config     # --> PermitRootLogin no
# sudo vi /etc/fail2ban/jail.conf  # --> bantime=10m   maxretry=5  (default)
#   [sshd]
#   enabled = true
#   port = ssh
#   filter = sshd
#   logpath = /var/log/auth.log
#   maxretry = 5
#   bantime = 10m
```



## (No cleanup of /dev/shm at ssh-logout)
UPDATE: Looks like the current default with `2023-05-03-raspios-bullseye-armhf-full.img` is set to not clean `/dev/shm` at logout of a user (like intended).  
See [https://superuser.com/questions/1117764/why-are-the-contents-of-dev-shm-is-being-removed-automatically](https://superuser.com/questions/1117764/why-are-the-contents-of-dev-shm-is-being-removed-automatically) .  
Check setting of `RemoveIPC` in `/etc/systemd/logind.conf`.  
It must be uncommented and set to `no`:
```
RemoveIPC=no
``` 


## (optional) Snap - how to install and use
- Installation of core system:  
  [https://snapcraft.io/docs/installing-snap-on-raspbian](https://snapcraft.io/docs/installing-snap-on-raspbian)
  ```
  sudo apt -y install snapd    
  # do a reboot afterwards: 
  # sudo reboot
  sudo snap install core
  ### sudo snap install snap-store 
  ```

- Installation of a snap-package(s):
  ```
  sudo snap install hello-world
  sudo snap install firefox
  sudo snap install chromium
  ```
  Execute `hello-world` to check the installation and execution.  
  In case an error occurs, check [https://stackoverflow.com/questions/42443273/raspberry-pi-libarmmem-so-cannot-open-shared-object-file-error/50958615#50958615](https://stackoverflow.com/questions/42443273/raspberry-pi-libarmmem-so-cannot-open-shared-object-file-error/50958615#50958615) .  
  ```
  cat /proc/cpuinfo | grep 'model name'
  ls -1 /usr/lib/arm-linux-gnueabihf/libarmmem*
  sudo vi /etc/ld.so.preload
  #   replace /usr/lib/arm-linux-gnueabihf/libarmmem-${PLATAFORM}.so  with correct library
  # OR:
  #   If this does not solve the error: Just comment out the first line of /etc/ld.so.preload
  ```

- Update of a snap-package (e.g. `core`):
  ```
  sudo snap refresh core
  ```

- Deinstall / remove a snap-package:
  ```
  sudo snap remove snap-store
  ```

- Installation of a snap-package provided as file:
  ```
  sudo snap install ./a_snap_package.snap --dangerous
  ```
- Start / execute are snap-package by calling its `/snap/bin/xyz`-link:
  ```
  ### sudo apt -y install dbus-user-session
  ### systemctl --user start dbus.service
  echo $DBUS_SESSION_BUS_ADDRESS
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
  /snap/bin/firefox
  ```



## (optional) Network print server
See also [https://www.tomshardware.com/how-to/raspberry-pi-print-server](https://www.tomshardware.com/how-to/raspberry-pi-print-server)  
or [https://medium.com/@anirudhgupta281998/setup-a-print-server-using-raspberry-pi-cups-part-2-2d6d48ccdc32](https://medium.com/@anirudhgupta281998/setup-a-print-server-using-raspberry-pi-cups-part-2-2d6d48ccdc32)  
or [https://opensource.com/article/18/3/print-server-raspberry-pi](https://opensource.com/article/18/3/print-server-raspberry-pi)
- Make sure cups is installed
  ```
  sudo apt -y install cups
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
  - Select local printer (HP LaserJet 1100)
  - Share this printer (checkbox)
  - Select model (first entry: HP LaserJet 1100, hpcups 3.21.2 (en))
  - Set default options (Check `Media Size: A4` and `Print Quality: Best`)
  - Goto `Printers`-Tab and print a test page
- TODO:
  - Check if SAMBA settings are needed to access the printer from Windows
  - Check if these settings are persistent



## (optional) Overlay Filesystem
See `sudo raspi-config` *-> Performance -> Overlay file system* and also...  
- [https://github.com/ghollingworth/overlayfs](https://github.com/ghollingworth/overlayfs)
- [https://yagrebu.net/unix/rpi-overlay.md](https://yagrebu.net/unix/rpi-overlay.md)



---
# Miscellaneous

## VNC - start and stop
- Start the `vncserver` (start of service is needed so that the window-manager works):
  ```
  sudo systemctl start vncserver-x11-serviced.service
  vncserver-virtual -geometry 1800x1000
  sudo systemctl stop vncserver-x11-serviced.service
  ```
- Stop / kill `vncserver`
  ```
  vncserver-virtual -kill :1
  ```
- Which vncservers are currently running (which vncserver sessions):
  ```
  cat ~/.vnc/*.pid
  ```
- Check which `vncserver` is installed:
  ```
  dpkg -l | grep vnc
  ```
- Info: `raspi-config` creates a symlink to start the `vncserver`:  
  `/etc/systemd/system/multi-user.target.wants/vncserver-x11-serviced.service --> /lib/systemd/system/vncserver-x11-serviced.service` .



## Retrieve informations
```
# Linux kernel version
uname -a

# OS release version
cat /etc/os-release

# Rasperry Pi model
cat /sys/firmware/devicetree/base/model 

# Hostname and further info
hostnamectl

# print Linux distribution specific information
lsb_release -a

# 32-bit or 64-bit?
getconf LONG_BIT

# CPU and hardware details
lscpu
cat /proc/cpuinfo

```


## SD-card speed test
```
# write speed:
dd if=/dev/zero of=./testFile bs=20M count=5 oflag=direct
# read speed:
dd if=./testFile of=/dev/null bs=20M count=5 oflag=dsync
```


## Scan for open ports
```
nmap -p- 192.168.2.163
nmap -sT -p 1-65535 192.168.2.163
```


## Scan network
Maybe use it with `sudo`
```
nmap -sn 192.168.2.0/24
nmap -sn 10.0.0.0/8
```


## Check network performance
```
iperf -s               # at server
iperf -c 192.168.x.y   # at client
```


## Clean apt cache
```
sudo du -sh /var/cache/apt/archives/
sudo apt clean
```


## Add a second IP address
See [https://www.garron.me/en/linux/add-secondary-ip-linux.html](https://www.garron.me/en/linux/add-secondary-ip-linux.html)
- Temporary
  ```
  # ifconfig -a    # old style
  ip address
  nmcli
  nmcli connection show
  nmcli connection show "Kabelgebundene Verbindung 1"
  sudo ip address add 10.1.2.3/8 dev enxb827eba924ae
  ```
- Permanent
  ```
  sudo nmcli connection modify a8a99795-2dbf-3220-964d-9a4b4ff53ac0 +ipv4.addresses "10.1.2.3/8"
  sudo cat /etc/NetworkManager/system-connections/*nmconnection
  # do a reboot to establish the ip address
  ```


## Setup "Log Weather Data"
- Execute script [`install_logWeatherData.sh`](03_install_logWeatherData/install_logWeatherData.sh) to
  - Copy folder `logWeatherData` to `$HOME/bin/logWeatherData`
  - Create virtual environment of python
  - Install python module(s)
  - Set shell-scripts executable
- Update root's `crontab`: Automatic nightly reboot at 2:30
  ```
  sudo crontab -e
    #   30 2 * * * /sbin/shutdown -r now
  ```
- Update fk's `crontab` by `crontab -e`:
  ```
  @reboot /usr/bin/screen -d -m /bin/bash /home/fk/bin/logWeatherData/logWeatherData.sh
  29 * * * * /home/fk/bin/logWeatherData/saveLogToday.sh
   2 0 * * * /home/fk/bin/logWeatherData/saveLogYesterday.sh
  ```


## Setup ssh github access
Using [github's guide to generating SSH keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- Check for existing ssh-keys first, then create a new ssh-key
  ```
  ls -al ~/.ssh
  ssh-keygen -t ed25519 -C "git@github.com"
  ```
- Login to [github.com](https://github.com)
- Goto [profile-->settings](https://github.com/settings/profile)
- Goto [SSH and GPG keys](https://github.com/settings/keys)
- Add ssh-key to `SSH keys`
  ```
  cat ~/.ssh/id_ed25519.pub
  ``` 
- check ssh connection, see [testing-your-ssh-connection](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)
  ```
  ssh -T git@github.com
  ```
  ... should show something like:
  ```
  Hi <UserName>! You've successfully authenticated, but GitHub does not provide shell access.
  ``` 
- Clone this project
  ```
  git clone git@github.com:CastraRegina/Raspinstall.git
  ```
- Specify your git global data
  ```
  git config --global user.email "git@github.com"
  git config --global user.name "fk"
  ```
- Enjoy the usual git workstyle
  ```
  git status
  git pull
  git add <file>
  git commit -m "message"
  git push
  ```


## Switch USB port power on / off
See [stackoverflow.com:how-to-turn-usb-port-power-on-and-off-in-raspberry-pi-4](https://stackoverflow.com/questions/59772765/how-to-turn-usb-port-power-on-and-off-in-raspberry-pi-4)  
Make sure sw package `uhubctl` is installed.
```
echo '1-1' | sudo tee /sys/bus/usb/drivers/usb/unbind    # shut off power
echo '1-1' | sudo tee /sys/bus/usb/drivers/usb/bind      # turn on power
```



# Check out...
## Set secondary network IP address and/or further interface 
TODO


## Minimal Image
Check [DietPi](https://dietpi.com/) .


## Raspi as reverse proxy
Check 

