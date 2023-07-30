#!/bin/bash

# add crontab entry (crontab -e)
#   @reboot /usr/bin/screen -d -m /bin/bash /home/fk/bin/logWeatherData.sh

cd /home/fk/bin

sleep 20s
python3 logWeatherData.py copyToday     -l /home/fk/logs -n weatherdataWDE1.txt -d /dev/shm/logs -b /home/fk/logs/bak 
sleep 5s
python3 logWeatherData.py logWeather    -l /dev/shm/logs -n weatherdataWDE1.txt -s /dev/ttyUSB0 -p 1

