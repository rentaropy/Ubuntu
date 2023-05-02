#!/bin/bash

sudo apt-get update
sudo apt install -y apache2
sudo ufw allow 'Apache Full'
sudo systemctl enable apache2
sudo systemctl status apache2

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
    ProxyPass / http://10.131.1.:8000/
    ProxyPassReverse / http://10.131.1.:8000/
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf"
sudo systemctl restart apache2
sudo systemctl status apache2
