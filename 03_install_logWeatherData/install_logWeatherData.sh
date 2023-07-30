#!/bin/bash

mkdir "${HOME}/logs_logWeatherData" 
cp -a bin_logWeatherData "${HOME}/"

chmod a+x "${HOME}/bin_logWeatherData/"*.sh

cd "${HOME}/bin_logWeatherData"
/usr/bin/python3 -m venv venv

