#!/bin/bash

#wget https://raw.githubusercontent.com/maeda-doctoral/ubuntu_setup/main/lsyncd_setup.sh && nano ./lsyncd_setup.sh && chmod u+x ./lsyncd_setup.sh && ./lsyncd_setup.sh

sudo apt install lsyncd -y
sudo mkdir /var/log/lsyncd
sudo touch /var/log/lsyncd/lsyncd.{log,status}
sudo touch /var/log/lsyncd/lsyncd.log

sudo mkdir -p /etc/lsyncd/
sudo sh -c 'echo "settings{
        logfile = "/var/log/lsyncd/lsyncd.log",
        statusFile = "/var/log/lsyncd/lsyncd.stat",
    nodaemon=false,
    statusInterval = 1,
    insist         = 1
}
sync{
    default.rsync,
    delay = 0,
    source = "/home/ubuntu/",
    target = "ubuntu@10.131.1.201:/home/ubuntu/AP",
    delete = "running",
    init = false,
    rsync = {
        archive = true,
        rsh = "/usr/bin/ssh -i /home/ubuntu/.ssh/id_ed25519 -o StrictHostKeyChecking=no"
    }
}
sync{
    default.rsync,
    delay = 0,
    source = "/home/ubuntu/",
    target = "ubuntu@10.131.1.101:/home/ubuntu",
    delete = "running",
    init = false,
    rsync = {
        archive = true,
        rsh = "/usr/bin/ssh -i /home/ubuntu/.ssh/id_ed25519 -o StrictHostKeyChecking=no"
    }
}" > /etc/lsyncd/lsyncd.conf.lua'

sudo systemctl restart lsyncd
sudo systemctl enable lsyncd
