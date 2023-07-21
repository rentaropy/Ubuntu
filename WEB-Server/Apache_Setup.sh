#!/bin/bash

#wget https://raw.githubusercontent.com/maeda-doctoral/Ubuntu/main/WEB-Server/Apache_Setup.sh && nano ./Apache_Setup.sh && chmod u+x ./Apache_Setup.sh && ./Apache_Setup.sh

sudo apt install -y apache2
sudo ufw allow 'Apache Full'
sudo systemctl enable apache2

IPADDRESS=$(hostname -I | awk '{print $1}')

cd /etc/apache2/mods-available
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_http

cd
sudo sh -c "echo 'ServerTokens ProductOnly
ServerSignature Off

Alias /static/ /home/ubuntu/Child-Guidance/accounts/static/
<Directory /home/ubuntu/Child-Guidance/accounts/static/>
        Require all granted
</Directory>' >> /etc/apache2/apache2.conf"

sudo cp -p /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.org
sudo sh -c "echo '<VirtualHost *:80>
    ServerName localhost
    ProxyPassMatch ^/static !
    ProxyPass / http://${IPADDRESS}:8000/
    ProxyPassReverse / http://${IPADDRESS}:8000/
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf"
sudo systemctl restart apache2
sudo systemctl status apache2
