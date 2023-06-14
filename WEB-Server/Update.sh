#!/bin/bash
#Create by EBP-Japan

# Setting you info
PASSWORD=""

# Update
echo ${PASSWORD} | sudo apt-get update
sudo apt -y full-upgrade
sudo apt -y autoremove
