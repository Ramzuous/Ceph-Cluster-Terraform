#!/bin/bash

# It destroys created VMs by Terraform
# terraform plan files
# and other previously used files
# but only hen you say 'yes' twice

terraform destroy

echo ""

echo "Do you really want to destroy terraform plan?"

echo "If you lie, you'll have problems with not removed files"

read -p "So, did you say yes? ": confirm

echo ""

if [ $confirm == 'yes' ]
then

	rm terraform.tfstate*

	if test -f plan;
	then
		rm plan
	fi

	if test -f scripts/ssh-config;
	then
		rm scripts/ssh-config
	fi

	if test -f scripts/hosts-ceph-cluster;
	then
		rm scripts/hosts-ceph-cluster
	fi

	if test -f scripts/set-fingerprint.sh;
	then
		rm scripts/set-fingerprint.sh
	fi

	if test -f scripts/chrony_servers;
	then
		rm scripts/chrony_servers
	fi

	echo "Useless files are deleted"
	echo ""

elif [ $confirm == 'no' ]
then
	echo "Project's files weren't deleted"
	echo ""
else
	echo "Wrong Value!"
	echo "No actions can be done"
	echo ""
fi
