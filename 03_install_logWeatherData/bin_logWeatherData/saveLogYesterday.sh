#!/bin/bash

cd /home/fk/bin/logWeatherData 
. venv/bin/activate

python3 logWeatherData.py copyYesterday -l /dev/shm/logs/logWeatherData -n weatherdataWDE1.txt -d /home/fk/logs/logWeatherData -b /home/fk/logs/logWeatherData/bak

