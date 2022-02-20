# Ceph-Cluster-Terraform

This project creats Ceph cluster on Proxmox VMs 
It can have maximal nine osd nodes and maximaum nine mon nodes.

Number of the nodes is liited by network implementation.

# What we need to start

 1. Terraform installed on Proxmox cluster
 2. VM template with CentOS-8-Stream Cloud init
 3. RSA public and private keys
 
 When we have all stuff from above, we need to set all variables.
 
 # First run
 
 To run project just use:
 
 ```bash
    ./terraform-run.sh
 ```
  
  
 In this script is set all what runs terraform script.
 
 If we want to destroy terraform, run:
 
 ```bash
    ./terraform-clean.sh
 ```
