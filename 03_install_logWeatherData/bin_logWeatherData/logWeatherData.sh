#!/bin/bash

cd /home/fk/bin/logWeatherData 
. venv/bin/activate

sleep 20s
python3 logWeatherData.py copyToday     -l /home/fk/logs/logWeatherData -n weatherdataWDE1.txt -d /dev/shm/logs/logWeatherData -b /home/fk/logs/logWeatherData/bak 
sleep 5s
python3 logWeatherData.py logWeather    -l /dev/shm/logs/logWeatherData -n weatherdataWDE1.txt -s /dev/ttyUSB0 -p 1

