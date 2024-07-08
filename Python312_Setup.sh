#!/bin/bash

#wget https://raw.githubusercontent.com/maeda-doctoral/Ubuntu/main/Python312_Setup.sh && nano ./Python312_Setup.sh && chmod u+x ./Python312_Setup.sh && ./Python312_Setup.sh

sudo apt install -y software-properties-common
echo "" | sudo add-apt-repository ppa:deadsnakes/ppa
sudo update
sudo apt install -y python3.12
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.12 0

sudo apt-get install -y libreadline-dev zlib1g-dev libncursesw5-dev libssl-dev libsqlite3-dev  libgdbm-dev libc6-dev libbz2-dev
sudo apt-get install -y build-essential libssl-dev libffi-dev  libexpat1-dev liblzma-dev python3-testresources

sudo apt-get install -y python3.12-dev python3-pip python3.12-distutils
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12
pip install --upgrade pip

mv ~/.local/bin/pip ~/.local/bin/pip_ && mv ~/.local/bin/pip3.12 ~/.local/bin/pip
echo 'export PATH=$PATH:~/.local/bin' >> ~/.profile && source ~/.profile
exit
