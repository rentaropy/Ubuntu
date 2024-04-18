#!/bin/bash

#wget https://raw.githubusercontent.com/maeda-doctoral/Ubuntu/main/WEB-Server/Nginx_Setup.sh && nano ./Nginx_Setup.sh && chmod u+x ./Nginx_Setup.sh && ./Nginx_Setup.sh

sudo apt -y install nginx
sudo ufw allow 'Nginx Full'
sudo systemctl enable nginx

IPADDRESS=$(hostname -I | awk '{print $1}')

sudo sh -c "echo 'upstream edogawa {
    server ${IPADDRESS}:8000;
    # You can add more servers here if you want to load balance across multiple instances.
}

server {
    listen 80;
    server_name ${IPADDRESS};
    client_max_body_size 10M;
    location / {
        proxy_pass http://edogawa;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # Add timeout settings here
        proxy_connect_timeout 1000s;  # Adjust the timeout value as needed
        proxy_send_timeout 1000s;    # Adjust the timeout value as needed
        proxy_read_timeout 1000s;    # Adjust the timeout value as needed

    }

    location /static {
        autoindex on;
        alias /home/ubuntu/Child-Guidance/accounts/static/;
    }

}' > /etc/nginx/sites-available/edogawa"
sudo ln -s /etc/nginx/sites-available/edogawa /etc/nginx/sites-enabled/edogawa
sudo systemctl restart nginx
sudo systemctl status nginx
