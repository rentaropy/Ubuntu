#!/bin/bash
#Create by EBP-Japan

# Setting you info
PASSWORD=""

# Update
echo $PASSWORD | sudo apt-get update
sudo apt full-upgrade -y
sudo apt autoremove -y
