#!/bin/bash

sudo apt-get update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install -y python3.10
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.10 0
sudo apt-get install -y python3.10-dev python3-pip python3.10-distutils
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10
python -m pip install --upgrade pip
sudo apt install -y mysql-server mysql-client libmysqlclient-dev libpango-1.0-0 libpangoft2-1.0-0
python -m pip install -r requirements.txt
