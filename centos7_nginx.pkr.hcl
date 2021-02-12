
variable "vsphere-server" {
    default = "vsphere"
}
variable "vsphere-user" {
    default = "admin"
} 
variable "vsphere-password" {
    default = "Ins3cur3P@ssw0rd"
} 
variable "vsphere-cluster" {
    default = "Cluster"
} 
variable "vsphere-network" {
    default = "VM Network"
} 
variable "vsphere-datastore" {
    default = "Datastore"
}
variable "vm-name" {
    default = "vmName"
}
variable "vm-cpu-num" {
    default = "2"
}
variable "vm-mem-size" {
    default = "1024"
}
variable "vm-disk-size" {
    default = "26000"
}
variable "iso_url" {
    default = "http://10.1.1.1/files/CentOS-7-x86_64-Minimal-2009.iso"
}  
variable "iso_checksum" {
    default = "07b94e6b1a0b0260b94c83d6bb76b26bf7a310dc78d7a9c7432809fb9bc6194a"
}

# source blocks configure your builder plugins; your source is then used inside
# build blocks to create resources. A build block runs provisioners and
# post-processors on an instance created by the source.

source "vsphere-iso" "centos7_vsphere_nginx" {
  iso_url = "{{user 'iso_url'}}"
  iso_checksum = "{{user 'iso_checksum'}}"
  
  floppy_files = ["ks.cfg"]
  boot_command = [
    "<esc><wait>",
    "linux ks=hd:fd0:/ks.cfg<enter>"
  ]
  
  vcenter_server = "{{user 'vsphere-server'}}"
  username = "{{user 'vsphere-user'}}"
  password = "{{user 'vsphere-password'}}"
  insecure_connection = "true"

  ssh_username = "root"
  ssh_password = "server"
  ssh_timeout = "15m"
  
  cluster = "{{user 'vsphere-cluster'}}"
  folder = "F5"
  datastore = "{{user 'vsphere-datastore'}}"
  
  vm_name = "{{user 'vm-name'}}"
  guest_os_type = "centos7_64Guest"
  CPUs = "{{user 'vm-cpu-num'}}"
  RAM = "{{user 'vm-mem-size'}}"
  RAM_reserve_all = "false"
  storage {
      disk_size = "{{user 'vm-disk-size'}}"
      disk_thin_provisioned = true
  }
  network_adapters {
      network = "{{user 'vsphere-network'}}"
      network_card = "vmxnet3"
  }
  shutdown_command = "shutdown -P now"
}

# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["sources.vsphere-iso.centos7_vsphere_nginx"]
  provisioner "shell" {
    inline = [
      "sleep 30",
      "sudo mkdir /etc/ssl/nginx"
    ]
  }
  provisioner "file" {
    destination = "/etc/ssl/nginx/"
    source      = "certs/"
  }
  provisioner "shell" {
    inline = [
      "sleep 5",
      "sudo yum -y update",
      "sudo yum -y install ca-certificates",
      "sudo yum -y install wget",
      "sudo wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/nginx-plus-7.4.repo",
      "sudo yum -y install nginx-plus",
      "sudo systemctl enable nginx.service"
    ]
  }
}