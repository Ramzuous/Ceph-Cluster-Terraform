#!/bin/bash

#########################################################
####################### Besic settings ##################
#########################################################

# upgrade

dnf -y upgrade

# set keyboard

localectl set-keymap de

# Enable login via SSH by password

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

systemctl restart sshd

# qemu guest agent - install and set

dnf -y install qemu-guest-agent

systemctl enable qemu-guest-agent

systemctl start qemu-guest-agent

########################################################
#################### Requaired packages ################
########################################################

# Install podman

dnf -y module disable container-tools

dnf -y install 'dnf-command(copr)'

dnf -y copr enable rhcontainerbot/container-selinux

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo

dnf -y --refresh install runc

dnf -y --refresh install podman

dnf -y install crun

# Python 3

dnf -y install python3

dnf -y install python3-pip

# Chrony

timedatectl set-timezone Europe/Berlin

dnf -y install chrony

systemctl enable --now chronyd

rm -f /etc/chrony.conf

# Install LVM2

dnf -y install lvm2

# Cephadm

curl --silent --remote-name --location https://github.com/ceph/ceph/raw/octopus/src/cephadm/cephadm

chmod +x /root/cephadm

/root/./cephadm add-repo --release octopus

/root/./cephadm install

cephadm install ceph-common ceph-osd

mkdir -p /etc/ceph

dnf -y upgrade
