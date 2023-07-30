#!/bin/bash

cd /home/fk/bin_logWeatherData 
. venv/bin/activate

python3 logWeatherData.py copyYesterday -l /dev/shm/logs_logWeatherData -n weatherdataWDE1.txt -d /home/fk/logs_logWeatherData -b /home/fk/logs_logWeatherData/bak

