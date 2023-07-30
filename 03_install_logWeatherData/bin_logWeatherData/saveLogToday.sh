#!/bin/bash

# add crontab entry (crontab -e)
#    29 * * * * /home/fk/bin/saveLogToday.sh


cd /home/fk/bin

sleep 5s   # wait some seconds as data is saved every full minute
python3 logWeatherData.py copyToday     -l /dev/shm/logs -n weatherdataWDE1.txt -d /home/fk/logs -b /home/fk/logs/bak


### python3 logWeatherData.py copyYesterday -l /dev/shm/logs -n weatherdataWDE1.txt -d /home/fk/logs -b /home/fk/logs/bak


