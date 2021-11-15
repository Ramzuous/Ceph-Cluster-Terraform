#/bin/bash

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
	rm /root/plan

	rm /root/terraform.tfstate*

	rm /root/scripts/ssh-config

	rm /root/scripts/hosts-ceph-cluster

	rm /root/scripts/set-fingerprint.sh

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
