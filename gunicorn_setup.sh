#!/bin/bash

cd ~/Django_project/
mkdir -p gunicorn/log gunicorn/run

echo '# -*- coding: utf-8 -*-
import multiprocessing
from socket import gethostbyname, gethostname

raw_env = ["DJANGO_SETTINGS_MODULE=edogawachildabuse.settings"]

ip = gethostbyname(gethostname())
bind = ip + ":8000"
workers = multiprocessing.cpu_count() * 2 + 1
threatds = 2

pidfile = "/home/ubuntu/Child-Guidance/gunicorn/run/gunicorn.pid"

accesslog = "gunicorn/log/access.log"
access_log_format = "%(t)s %(h)s %(H)s %(m)s %(U)s %(q)s %(s)s %(a)s"
disable_redirect_access_to_syslog = True
errorlog = "gunicorn/log/error.log"
loglevel = "info"' > gunicorn/gunicorn.conf.py

python -m pip install gunicorn
sudo mkdir -p /usr/lib/systemd/system/
sudo sh -c "echo '[Unit]
Description=Python WSGI application
After=network.target
[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/Child-Guidance
ExecStart=/home/ubuntu/.local/bin/gunicorn edogawachildabuse.wsgi -c gunicorn/gunicorn.conf.py
[Install]
WantedBy=multi-user.target' > /usr/lib/systemd/system/gunicorn.service"

sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn
sudo systemctl status gunicorn
