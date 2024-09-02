#!/bin/bash
#Create by EBP-Japan
#wget https://raw.githubusercontent.com/maeda-doctoral/Ubuntu/main/Update.sh && nano ./Update.sh && chmod u+x ./Update.sh && ./Update.sh

# Setting you info
#PASSWORD=""
# Update
sudo apt-get update
sudo apt -y full-upgrade
sudo apt -y autoremove
sudo apt -y clean
