#!/bin/bash

cd /home/fk/bin_logWeatherData 
. venv/bin/activate

sleep 20s
python3 logWeatherData.py copyToday     -l /home/fk/logs_logWeatherData -n weatherdataWDE1.txt -d /dev/shm/logs_logWeatherData -b /home/fk/logs_logWeatherData/bak 
sleep 5s
python3 logWeatherData.py logWeather    -l /dev/shm/logs_logWeatherData -n weatherdataWDE1.txt -s /dev/ttyUSB0 -p 1

