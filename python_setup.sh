#!/bin/bash

#wget https://raw.githubusercontent.com/maeda-doctoral/ubuntu_setup/main/python_setup.sh && nano ./python_setup.sh && chmod u+x ./python_setup.sh && ./python_setup.sh

sudo apt-get update
sudo apt install -y software-properties-common
echo "" | sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install -y python3.9
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.9 0

sudo apt-get install libreadline-dev zlib1g-dev libncursesw5-dev libssl-dev libsqlite3-dev  libgdbm-dev libc6-dev libbz2-dev
sudo apt-get install build-essential libssl-dev libffi-dev  libexpat1-dev liblzma-dev

sudo apt-get install -y python3.9-dev python3-pip python3.9-distutils
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.9
python -m pip install --upgrade pip
