#!/bin/bash

# install chrony server

echo -e "server 0.europe.pool.ntp.org iburst\nserver 1.europe.pool.ntp.org iburst\nserver 2.europe.pool.ntp.org iburst\nserver 3.europe.pool.ntp.org iburst" > /etc/chrony.conf

timedatectl set-ntp true

systemctl restart chronyd
