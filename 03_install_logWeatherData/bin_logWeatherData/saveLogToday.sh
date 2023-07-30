#!/bin/bash

cd /home/fk/bin_logWeatherData 
. venv/bin/activate

sleep 5s   # wait some seconds as data is saved every full minute
python3 logWeatherData.py copyToday     -l /dev/shm/logs_logWeatherData -n weatherdataWDE1.txt -d /home/fk/logs_logWeatherData -b /home/fk/logs_logWeatherData/bak


