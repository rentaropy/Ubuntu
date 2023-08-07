#!/bin/bash
#Create by EBP-Japan
#wget https://raw.githubusercontent.com/maeda-doctoral/Ubuntu/main/WEB-Server/Update.sh && nano ./Update.sh && chmod u+x ./Update.sh && ./Update.sh

# Setting you info
#PASSWORD=""
PASSWORD=${PASSWORD}
# Update
echo ${PASSWORD} | sudo apt-get update
sudo apt -y full-upgrade
sudo apt -y autoremove
