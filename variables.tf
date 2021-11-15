variable "pm_api_url" {
	default = "https://<ipv4>:8006/api2/json"
}

variable "pm_user" {
	default = "root@pam"
}

variable "pve_user" {
	default = "<proxmox_user>"
}

variable "pm_password" {
	default = "<password>"
}

variable "pve_host" {
	default = "<ipv4>"
}

variable "connection_type" {
	default = "ssh"
}

variable "ssh_pub_key"{
	default = "<public_key>"
}

variable "ssh_priv_key"{
	default = "/root/ssh_key"
}

variable "clone" {
	default = "<name_of_the_template>"
}

variable "type_of_os" {
	default = "cloud-init"
}

variable "cors_num"{
	default = ""
}

variable "memory_size"{
	default = "<mb>"
}

variable "boot_disk"{
	default = ""
}

variable "scsihw_type"{
	default = ""
}

variable "disk_type"{
	default = ""
}

variable "network_model"{
	default = ""
}

variable "network_bridge"{
	default = "<bridge_name>"
}

variable "nameserver"{
	default = "<ipv4>"
}

variable "searchdomain"{
	default = "<ipv4>"
}

variable "osd_count"{
	default = "<int>"
}

variable "mon_count"{
	default = "<int>"
}

variable "mon_target_node"{
	default = "<target_node_name>"
}

variable "osd_target_node"{
	default = "<target_node_name>"
}

variable "ceph_init_password"{
	default = "<password>"
}

# example: .my.domain
variable "domain"{
	default = ""
}

variable "ceph_mon_storage"{
	default = "<storage_name>"
}

variable "ceph_osd_storage"{
	default = "<storage_name>"
}

variable "ceph_mon_disk_size"{
	default = "<disk_size>"
}

variable "ceph_osd_disk_size"{
	default = "<disk_size>"
}

# example: --scsi2 LVM-2:32
variable "second_osd_disk"{
	default = ""
}

# All IP addresses have to be in one network

variable "ceph_admin_ip"{
	default = "<ipv4>"
}

# Last octet needs to have only two numbers
variable "ceph_mon_ip"{
	default = ""
}

# Last octet needs to have only two numbers
variable "ceph_osd_ip"{
	default = ""
}

# Cloudinit network (mask & gateway, example: /24,gw=192.168.0.1)
variable "ceph_network"{
	default = ""
}
