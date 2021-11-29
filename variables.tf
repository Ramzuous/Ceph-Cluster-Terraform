# Example: https://10.1.0.20:8006/api2/json
variable "pm_api_url" {
	default = ""
}

# Example: root@pam
variable "pm_user" {
	default = ""
}

# Example: root
variable "pve_user" {
	default = ""
}

# Plain text
variable "pm_password" {
	default = ""
}

# IP of API host
variable "pve_host" {
	default = ""
}

# Example: ssh
variable "connection_type" {
	default = ""
}

# Whole ssh public key
variable "ssh_pub_key"{
	default = ""
}

# Name of the file with private key (example: id_rsa)
variable "ssh_priv_key"{
	default = ""
}

# Name of template to clone
variable "clone" {
	default = ""
}

# Type of OS (example: cloud-init)
variable "type_of_os" {
	default = ""
}

# Number of cors (example: 2)
variable "cors_num"{
	default = ""
}

# RAM size (example: 2048)
variable "memory_size"{
	default = ""
}

# Boot disk (examle: scsi0)
variable "boot_disk"{
	default = ""
}

# Type of scsi hardware (example: virtio-scsi-pci)
variable "scsihw_type"{
	default = ""
}

# Disk type (example: scsi)
variable "disk_type"{
	default = ""
}

# Network card model (example: virtio)
variable "network_model"{
	default = ""
}

# Network card model (example: vmbr0)
variable "network_bridge"{
	default = ""
}

# DNS 1 (example: 1.1.1.1)
variable "nameserver"{
	default = ""
}

# DNS 2 (example: 8.8.8.8)
variable "searchdomain"{
	default = ""
}

# Number of osd nodes (example: 4)
variable "osd_count"{
	default = ""
}

# Numer of mon nodes (example: 3)
# Admin nodes is also mon
variable "mon_count"{
	default = ""
}

# Target node to migrate mon nodes (example: pve10)
variable "mon_target_node"{
	default = ""
}

# Target node to migrate osd nodes (example: pve10)
variable "osd_target_node"{
	default = ""
}

# Plain text - default password which will be
# set before you start using Ceph cluster
variable "ceph_init_password"{
	default = ""
}

# Example: .my.domain.test
# Name of the domain need to have {dot} at the beginning
variable "domain"{
	default = ""
}

# All IP addresses have to be in one network!

variable "ceph_admin_ip"{
	default = ""
}

# Last octet needs to have only two numbers maximum
# Example: 192.168.0.1 or 192.168.0.22
variable "ceph_mon_ip"{
	default = ""
}

# Last octet needs to have only two numbers maximum
# Example: 192.168.0.1 or 192.168.0.22
variable "ceph_osd_ip"{
	default = ""
}

# Cloudinit network (mask & gateway) 
# Format & example: /24,gw=192.168.0.1
variable "ceph_network"{
	default = "/24,gw=192.168.4.1"
}