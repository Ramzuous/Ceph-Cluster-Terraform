###############################

# Pre-actions

# set fingerprint script - common
resource "null_resource" "set_fingerprint_script_local" {
        count = 1

        provisioner "local-exec" {
                command = "echo '#!/bin/bash' >> scripts/set-fingerprint.sh"
        }

        provisioner "local-exec" {
                command = "echo 'ssh-keyscan 127.0.0.1 >> /root/.ssh/known_hosts' >> scripts/set-fingerprint.sh"
        }

        provisioner "local-exec" {
                command = "echo 'ssh-keyscan localhost >> /root/.ssh/known_hosts' >> scripts/set-fingerprint.sh"
        }

        provisioner "local-exec" {
                command = "echo 'ssh-keyscan ${var.ceph_admin_ip} >> /root/.ssh/known_hosts' >> scripts/set-fingerprint.sh"
        }
}

# set fingerprint script - ceph osd hosts
resource "null_resource" "set_fingerprint_script_osd" {
        count = "${ var.osd_count }"

        provisioner "local-exec" {
                command = "echo 'ssh-keyscan ${var.ceph_osd_ip}${count.index} >> /root/.ssh/known_hosts' >> scripts/set-fingerprint.sh"
        }

        depends_on = [ null_resource.set_fingerprint_script_local ]

}

# set fingerprint script - ceph mon hosts
resource "null_resource" "set_fingerprint_script_mon" {
        count = "${ var.mon_count }"

        provisioner "local-exec" {
                command = "echo 'ssh-keyscan ${var.ceph_mon_ip}${count.index} >> /root/.ssh/known_hosts' >> scripts/set-fingerprint.sh"
        }

        depends_on = [ null_resource.set_fingerprint_script_osd ]

}

# set /etc/hosts - local
resource "null_resource" "set_localhost" {
        count = 1

        provisioner "local-exec" {
                command = "echo 127.0.0.1 localhost >> scripts/hosts-ceph-cluster"
        }

        depends_on = [ null_resource.set_fingerprint_script_mon ]

}

# set /etc/hosts - local
resource "null_resource" "set_ceph_admin_dns" {
        count = 1

        provisioner "local-exec" {
                command = "echo ${var.ceph_admin_ip} admin${var.domain} admin >> scripts/hosts-ceph-cluster"
        }

        depends_on = [ null_resource.set_localhost ]

}

# set /etc/hosts - ceph osd hosts
resource "null_resource" "set_osd_dns" {
        count = "${ var.osd_count }"

        provisioner "local-exec" {
                command = "echo ${var.ceph_osd_ip}${count.index} osd-${count.index}${var.domain} osd-${count.index} >> scripts/hosts-ceph-cluster"
        }

        depends_on = [ null_resource.set_ceph_admin_dns ]

}


# set /etc/hosts - ceph mon hosts
resource "null_resource" "set_mon_dns" {
        count = "${ var.mon_count }"

        provisioner "local-exec" {
                command = "echo ${var.ceph_mon_ip}${count.index} mon-${count.index}${var.domain} mon-${count.index} >> scripts/hosts-ceph-cluster"
        }

        depends_on = [ null_resource.set_osd_dns ]

}

# set other chrony servers (/etc/chrony.conf) - 
resource "null_resource" "set_chrony_server" {

		count = "${ var.mon_count }"
		
		provisioner "local-exec" {
                command = "echo server ${var.ceph_mon_ip}${count.index} >> scripts/chrony_servers"
        }
		
		depends_on = [ null_resource.set_mon_dns ]
		
}

# set ssh-config (/root/.ssh/config) - admin
resource "null_resource" "set_admin_ssh_config" {
        count = 1

        provisioner "local-exec" {
                command = "echo 'Host admin\n    Hostname ${var.ceph_admin_ip}\n    User root' >> scripts/ssh-config"
        }

        depends_on = [ null_resource.set_chrony_server ]

}

# set ssh-config (/root/.ssh/config) - ceph osd hosts
resource "null_resource" "set_osd_ssh_config" {
        count = "${ var.osd_count }"

        provisioner "local-exec" {
                command = "echo 'Host osd-${count.index}\n    Hostname ${var.ceph_osd_ip}${count.index}\n    User root' >> scripts/ssh-config"
        }

        depends_on = [ null_resource.set_admin_ssh_config ]

}

# set ssh-config (/root/.ssh/config) - ceph mon hosts
resource "null_resource" "set_mon_ssh_config" {
        count = "${ var.mon_count }"

        provisioner "local-exec" {
                command = "echo 'Host mon-${count.index}\n    Hostname ${var.ceph_mon_ip}${count.index}\n    User root' >> scripts/ssh-config"
        }

        depends_on = [ null_resource.set_osd_ssh_config ]

}

#########################################################################################################################

########################################################## Ceph admin ###################################################

#########################################################################################################################

resource "proxmox_vm_qemu" "ceph_admin" {

        agent = 1
        count = 1

        name = "admin"
        target_node = "${ var.mon_target_node }"
        clone = "${ var.clone }"
        os_type = "${ var.type_of_os}"
        onboot = false
        vmid = "400"

        cores = "${ var.cors_num }"
        memory = "${ var.memory_size }"

        bootdisk = "${ var.boot_disk }"
        scsihw = "${ var.scsihw_type }"

        disk {
                type = "${ var.disk_type }"
                storage = "LVM-2"
                size = "32G"
        }

        network {
                model = "${ var.network_model }"
                bridge = "${ var.network_bridge }"
        }


# Cloud init

        # ip
        ipconfig0 = "ip=${var.ceph_admin_ip}${var.ceph_network}"
        nameserver = "${ var.nameserver }"
        searchdomain = "${ var.searchdomain }"

        # ssh key

sshkeys = <<EOF
${var.ssh_pub_key}
EOF

        depends_on = [ null_resource.set_mon_ssh_config ]

}

####################################################################################################################################################
# Skript send and exec - install actions

resource "null_resource" "ceph_admin_set" {

        count = 1

        # Send ssh config
        provisioner "file" {
                source = "scripts/ssh-config"
                destination = "/root/.ssh/config"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Send DNS file
        provisioner "file" {
                source = "scripts/hosts-ceph-cluster"
				destination = "/etc/cloud/templates/hosts.redhat.tmpl"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Send ssh key
        provisioner "file" {
                source = "ssh_key"
                destination = "/root/.ssh/id_rsa"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Set ssh key permission
        provisioner "remote-exec" {
                inline = [
                        "chmod 400 /root/.ssh/id_rsa",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Set host name
        provisioner "remote-exec" {
                inline = [
                        "hostnamectl set-hostname admin",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Send install file-common
        provisioner "file" {
                source = "scripts/install-components.sh"
                destination = "/root/install-components.sh"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Execute install file-common
        provisioner "remote-exec" {
                inline = [
                        "chmod +x /root/install-components.sh",
                        "/bin/bash /root/install-components.sh"
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Send set chrony-server
        provisioner "file" {
                source = "scripts/install-chrony-server.sh"
                destination = "/root/install-chrony-server.sh"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Execute set chrony-server
        provisioner "remote-exec" {
                inline = [
                        "chmod +x /root/install-chrony-server.sh",
                        "/bin/bash /root/install-chrony-server.sh"
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ proxmox_vm_qemu.ceph_admin ]

}


#########################################################################################################################

########################################################## Ceph mon #####################################################

#########################################################################################################################

resource "proxmox_vm_qemu" "ceph_mon" {

        agent = 1
        count = "${ var.mon_count }"

        name = "mon-${count.index}"
        target_node = "${ var.mon_target_node }"
        clone = "${ var.clone }"
        os_type = "${ var.type_of_os}"
        onboot = false
        vmid = "50${count.index}"

        cores = "${ var.cors_num }"
        memory = "${ var.memory_size }"

        bootdisk = "${ var.boot_disk }"
        scsihw = "${ var.scsihw_type }"

        disk {
                type = "${ var.disk_type }"
                storage = "LVM-2"
                size = "32G"
        }

        network {
                model = "${ var.network_model }"
                bridge = "${ var.network_bridge }"
        }


# Cloud init

        # ip
        ipconfig0 = "ip=${var.ceph_mon_ip}${count.index}${var.ceph_network}"
        nameserver = "${ var.nameserver }"
        searchdomain = "${ var.searchdomain }"

        # ssh key

sshkeys = <<EOF
${var.ssh_pub_key}
EOF

        depends_on = [ null_resource.ceph_admin_set ]

}

####################################################################################################################################################
# Skript send and exec - install actions

resource "null_resource" "ceph_mon_set" {

        count = "${ var.mon_count }"

		# Send ssh config
        provisioner "file" {
                source = "scripts/ssh-config"
                destination = "/root/.ssh/config"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_mon.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Send DNS file
        provisioner "file" {
                source = "scripts/hosts-ceph-cluster"
				destination = "/etc/cloud/templates/hosts.redhat.tmpl"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_mon.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Send ssh key
        provisioner "file" {
                source = "ssh_key"
                destination = "/root/.ssh/id_rsa"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_mon.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Set ssh key permission
        provisioner "remote-exec" {
                inline = [
                        "chmod 400 /root/.ssh/id_rsa",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_mon.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Set host name
        provisioner "remote-exec" {
                inline = [
                        "hostnamectl set-hostname mon-${count.index}",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_mon.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Send install file-common
        provisioner "file" {
                source = "scripts/install-components.sh"
                destination = "/root/install-components.sh"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_mon.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Execute install file-common
        provisioner "remote-exec" {
                inline = [
                        "chmod +x /root/install-components.sh",
                        "/bin/bash /root/install-components.sh"
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_mon.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Send set chrony-server
        provisioner "file" {
                source = "scripts/install-chrony-server.sh"
                destination = "/root/install-chrony-server.sh"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Execute set chrony-server
        provisioner "remote-exec" {
                inline = [
                        "chmod +x /root/install-chrony-server.sh",
                        "/bin/bash /root/install-chrony-server.sh"
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ proxmox_vm_qemu.ceph_mon ]

}

#########################################################################################################################

########################################################## Ceph osd #####################################################

#########################################################################################################################

resource "proxmox_vm_qemu" "ceph_osd" {

        agent = 1
        count = "${ var.osd_count }"

        name = "osd-${count.index}"
        target_node = "${ var.osd_target_node }"
        clone = "${ var.clone }"
        os_type = "${ var.type_of_os}"
        onboot = false
        vmid = "60${count.index}"

        cores = "${ var.cors_num }"
        memory = "${ var.memory_size }"

        bootdisk = "${ var.boot_disk }"
        scsihw = "${ var.scsihw_type }"

        disk {
                type = "${ var.disk_type }"
                storage = "LVM-2"
                size = "20G"
        }

        network {
                model = "${ var.network_model }"
                bridge = "${ var.network_bridge }"
        }


# Cloud init

        #ip
        ipconfig0 = "ip=${var.ceph_osd_ip}${count.index}${var.ceph_network}"
        nameserver = "${ var.nameserver }"
        searchdomain = "${ var.searchdomain }"

#ssh key
sshkeys = <<EOF
${var.ssh_pub_key}
EOF

        depends_on = [ null_resource.ceph_mon_set ]

}

#############################################################################################################################
# Skript send and exec - install actions

resource "null_resource" "ceph_osd_set" {

        count = "${ var.osd_count }"

        # Set another disk for osd
        provisioner "remote-exec" {
                inline = [
                        "qm set 60${count.index} --scsi2 LVM-2:32",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.osd_target_node }"
                        password = "${ var.pm_password }"
                }
        }

        # Send ssh config
        provisioner "file" {
                source = "scripts/ssh-config"
                destination = "/root/.ssh/config"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)

				}
		}

        # Send DNS file
        provisioner "file" {
                source = "scripts/hosts-ceph-cluster"
				destination = "/etc/cloud/templates/hosts.redhat.tmpl"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Send ssh key
        provisioner "file" {
                source = "ssh_key"
                destination = "/root/.ssh/id_rsa"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Set ssh key permission
        provisioner "remote-exec" {
                inline = [
                        "chmod 400 /root/.ssh/id_rsa",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Set host name
        provisioner "remote-exec" {
                inline = [
                        "hostnamectl set-hostname osd-${count.index}",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Send install file-common
        provisioner "file" {
                source = "scripts/install-components.sh"
                destination = "/root/install-components.sh"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Execute install file-common
        provisioner "remote-exec" {
                inline = [
                        "chmod +x /root/install-components.sh",
                        "/bin/bash /root/install-components.sh"
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }
        
        # Send chrony-client file
        provisioner "file" {
                source = "scripts/chrony_servers"
                destination = "/etc/chrony.conf"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Set chrony-client
        provisioner "remote-exec" {
                inline = [
                        "echo 'server ${var.ceph_admin_ip}' >> /etc/chrony.conf",
						"timedatectl set-ntp true",
						"systemctl enable --now chronyd"
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }    

        depends_on = [ proxmox_vm_qemu.ceph_osd ]

}

#####################################################################################
############################## Post settings ########################################
#####################################################################################

# Set ceph monitor - admin
resource "null_resource" "set_monitor" {

        count = 1

        provisioner "remote-exec" {

                inline = [
                        "cephadm bootstrap --mon-ip ${var.ceph_admin_ip} --initial-dashboard-password '${var.ceph_init_password}'",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ null_resource.ceph_osd_set ]

}

# Set fingerprint - ceph admin host
resource "null_resource" "admin_fingerprint" {

        count = 1

        # Send fingerprint script
        provisioner "file" {
                source = "scripts/set-fingerprint.sh"
                destination = "/root/set-fingerprint.sh"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Execut fingerprint script
        provisioner "remote-exec" {

                inline = [
                        "chmod +x /root/set-fingerprint.sh",
                        "/bin/bash /root/set-fingerprint.sh"
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ null_resource.set_monitor ]

}

# Set fingerprint - ceph mon hosts
resource "null_resource" "mon_fingerprint" {

        count = "${ var.mon_count }"

        # Send fingerprint script
        provisioner "file" {
                source = "scripts/set-fingerprint.sh"
                destination = "/root/set-fingerprint.sh"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_mon.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Execut fingerprint script
        provisioner "remote-exec" {

                inline = [
                        "chmod +x /root/set-fingerprint.sh",
                        "/bin/bash /root/set-fingerprint.sh"
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_mon.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ null_resource.admin_fingerprint ]

}

# Set fingerprint - ceph osd hosts
resource "null_resource" "osd_fingerprint" {

        count = "${ var.osd_count }"

        # Send fingerprint script
        provisioner "file" {
                source = "scripts/set-fingerprint.sh"
                destination = "/root/set-fingerprint.sh"

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

        # Execut fingerprint script
        provisioner "remote-exec" {

                inline = [
                        "chmod +x /root/set-fingerprint.sh",
                        "/bin/bash /root/set-fingerprint.sh"
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = element(proxmox_vm_qemu.ceph_osd.*.ssh_host, count.index)
                        private_key = file(var.ssh_priv_key)
                }
        }

 #######################################

        depends_on = [ null_resource.mon_fingerprint ]

}

# Set sending ceph key script - ceph admin host
resource "null_resource" "add_mon_keys_to_admin" {

    count = "${ var.mon_count }"

    provisioner "remote-exec" {

                inline = [
                        "ssh-copy-id -f -i /etc/ceph/ceph.pub root@mon-${count.index}",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
        }
    }

    depends_on = [ null_resource.osd_fingerprint ]

}

# Set sending ceph key script - ceph osd hosts
resource "null_resource" "add_osd_keys_to_admin" {

        count = "${ var.osd_count }"

        provisioner "remote-exec" {

                inline = [
                        "ssh-copy-id -f -i /etc/ceph/ceph.pub root@osd-${count.index}",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
      }
    }

        depends_on = [ null_resource.add_mon_keys_to_admin ]

}

# Add ceph osd hosts to ceph admin
resource "null_resource" "adding_ceph_osd_to_admin" {

        count = "${ var.osd_count }"

        provisioner "remote-exec" {

                inline = [
                        "ceph orch host add osd-${count.index} ${var.ceph_osd_ip}${count.index} --labels _admin",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ null_resource.add_osd_keys_to_admin ]

}

# Add ceph mon hosts to ceph admin
resource "null_resource" "adding_ceph_mon_to_admin" {

        count = "${ var.mon_count }"

        provisioner "remote-exec" {

                inline = [
                        "ceph orch host add mon-${count.index} ${var.ceph_mon_ip}${count.index} --labels _admin",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ null_resource.adding_ceph_osd_to_admin ]

}

# Add ceph mon hosts to ceph admin - disable automatic mon adding
resource "null_resource" "unmaneged_add_mon" {

        count = "${ var.mon_count }"

        provisioner "remote-exec" {

                inline = [
                        "ceph orch apply mon --unmanaged",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ null_resource.adding_ceph_mon_to_admin ]
}


# Add ceph mon hosts to ceph admin - ultimate
resource "null_resource" "ultimate_add_mon" {

        count = "${ var.mon_count }"

        provisioner "remote-exec" {

                inline = [
                        "ceph orch daemon add mon mon-${count.index}:${var.ceph_mon_ip}${count.index}",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ null_resource.unmaneged_add_mon ]
}

# Add ceph osd hosts to ceph admin - ultimate
resource "null_resource" "ultimate_add_osd" {

        count = "${ var.osd_count }"

        provisioner "remote-exec" {

                inline = [
                        "ceph orch daemon add osd osd-${count.index}:/dev/sdb",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ null_resource.ultimate_add_mon ]

}

# Seting telemetry
resource "null_resource" "set_telemtry" {

        count = 1

        provisioner "remote-exec" {

                inline = [
                        "ceph telemetry on --license sharing-1-0",
                ]

                connection {
                        type = "${ var.connection_type }"
                        user = "${ var.pve_user }"
                        host = "${ var.ceph_admin_ip }"
                        private_key = file(var.ssh_priv_key)
                }
        }

        depends_on = [ null_resource.ultimate_add_osd ]

}
