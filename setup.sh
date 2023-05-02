#!/bin/bash

# Update
apt-get update
apt full-upgrade -y
apt autoremove -y

apt install curl -y

mkdir ~/.ssh
rm ~/.ssh/authorized_keys
curl https://github.com/maeda-doctoral.keys >> ~/.ssh/authorized_keys
chmod 700 .ssh/authorized_keys

# Timezone Setup
timedatectl set-timezone Asia/Tokyo

# noPasswd ubuntu
echo 'ubuntu ALL=NOPASSWD: ALL' | EDITOR='tee -a' visudo

# Firewall Allow
ufw allow 22
ufw enable

# SSH Setup
SSH_CONFIG="/etc/ssh/sshd_config"
SSH_CONFIG_BACKUP="/etc/ssh/sshd_config.bk"
SSH_PORT_NUMBER="22"

function change_setting () {
  TARGET=$1
  KEYWORD=$2
  VALUE=$3

  EXIST=`grep "^${KEYWORD}" ${TARGET}`
  EXIST_COMMENT=`grep "^#${KEYWORD}" ${TARGET}`

  if [ ${#EXIST} -ne 0 ]; then
    sed -i '/^'${KEYWORD}'/c '${KEYWORD}' '${VALUE}'' ${TARGET}
  elif [ ${#EXIST_PERMIT_COMMENT} -ne 0 ]; then
    sed -i '/^#'${KEYWORD}'/c '${KEYWORD}' '${VALUE}'' ${TARGET} 
  else
    echo -e "${KEYWORD} ${VALUE}" >> ${TARGET}
  fi
}
if [ -f ${SSH_CONFIG_BACKUP} ]; then
  echo "SSH setting is already done."
else
  cp -i ${SSH_CONFIG} ${SSH_CONFIG_BACKUP}
  
  # Port
  change_setting ${SSH_CONFIG} Port ${SSH_PORT_NUMBER}
  grep "^Port" ${SSH_CONFIG}
  
  # PermitRootLogin
  change_setting ${SSH_CONFIG} PermitRootLogin no
  grep "^PermitRootLogin" ${SSH_CONFIG}

  # PasswordAuthentication
  change_setting ${SSH_CONFIG} PasswordAuthentication no
  grep "^PasswordAuthentication" ${SSH_CONFIG}

  # ChallengeResponseAuthentication
  change_setting ${SSH_CONFIG} ChallengeResponseAuthentication no
  grep "^ChallengeResponseAuthentication" ${SSH_CONFIG}

  # PermitEmptyPasswords
  change_setting ${SSH_CONFIG} PermitEmptyPasswords no
  grep "^PermitEmptyPasswords" ${SSH_CONFIG}

  # SyslogFacility
  change_setting ${SSH_CONFIG} SyslogFacility AUTHPRIV
  grep "^SyslogFacility" ${SSH_CONFIG}

  # LogLevel
  change_setting ${SSH_CONFIG} LogLevel VERBOSE
  grep "^LogLevel" ${SSH_CONFIG}

  # TCP Port Forwarding
  #change_setting ${SSH_CONFIG} AllowTcpForwarding no
  #grep "^AllowTcpForwarding" ${SSH_CONFIG}

  # AllowStreamLocalForwarding
  #change_setting ${SSH_CONFIG} AllowStreamLocalForwarding no
  #grep "^AllowStreamLocalForwarding" ${SSH_CONFIG}

  # GatewayPorts
  #change_setting ${SSH_CONFIG} GatewayPorts no
  #grep "^GatewayPorts" ${SSH_CONFIG}

  # PermitTunnel
  #change_setting ${SSH_CONFIG} PermitTunnel no
  #grep "^PermitTunnel" ${SSH_CONFIG}
fi

# UserCreate
adduser -q --gecos "" --disabled-login ubuntu
gpasswd -a ubuntu sudo

# User SSH Setup
mkdir -p /home/ubuntu/.ssh
chown ubuntu:ubuntu /home/ubuntu/.ssh
install -m 700 -o ubuntu -g ubuntu ~/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
systemctl restart sshd.service

crontab -l > {tmpfile}
echo "*/5 * * * * rm /root/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys && curl https://github.com/maeda-doctoral.keys >> /root/.ssh/authorized_keys && cp /root/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys && chown -R ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys && chmod 700 /root/.ssh/authorized_keys && chmod 700 /home/ubuntu/.ssh/authorized_keys" >> {tmpfile}
crontab {tmpfile}
rm {tmpfile}

# Logout
killall -u root
