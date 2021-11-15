# Ceph-Cluster-Terraform

This project creats Ceph cluster on Proxmox VMs 
It can have maximal nine osd nodes and maximaum nine mon nodes.

Number of the nodes is liited by network implementation.

It uses Terraform.

# What we need to start
 1. Terraform installed on Proxmox cluster
 2. VM template with CentOS8-Stream Cloud init
 3. RSA public and private keys
 
 When you have all stuff from above, you need to set all variables.
 
 # First run
 
 To run project just use:
 
 <code>
 ./terraform-run.sh
 </code>
  
  
 In this script is set all what runs terraform script.
 
 If you want to destroy terraform, run:
 
 <code>
 ./terraform-clean.sh
  </code>
