#!/bin/bash

mkdir -p "${HOME}/logs/logWeatherData" 
mkdir -p "${HOME}/bin"

cp -a logWeatherData "${HOME}/bin/"

chmod a+x "${HOME}/bin/logWeatherData/"*.sh

cd "${HOME}/bin/logWeatherData"
pwd

echo "Creating python virtual environment..."
/usr/bin/python3 -m venv venv

. venv/bin/activate

which python3
python3 --version

if [[ $(which python3) == *"/venv/"* ]]; then
  echo "Updating pip, setuptools, wheels..."
  python3 -m pip install --upgrade pip setuptools wheel

  echo "Installing python modules..."
  python3 -m pip install pyserial
else 
  echo "ERROR: No venv - check the creation of the virtual python environment!"
fi



