#!/bin/bash

cd /home/fk/bin/logWeatherData 
. venv/bin/activate

sleep 5s   # wait some seconds as data is saved every full minute
python3 logWeatherData.py copyToday     -l /dev/shm/logs/logWeatherData -n weatherdataWDE1.txt -d /home/fk/logs/logWeatherData -b /home/fk/logs/logWeatherData/bak


