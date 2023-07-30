#!/bin/bash

# add crontab entry (crontab -e)
#    2 0 * * * /home/fk/bin/saveLogYesterday.sh


cd /home/fk/bin

python3 logWeatherData.py copyYesterday -l /dev/shm/logs -n weatherdataWDE1.txt -d /home/fk/logs -b /home/fk/logs/bak

