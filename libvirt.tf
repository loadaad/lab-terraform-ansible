// fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "os_image" {
  name = "${var.hostname}-os_image"
  pool = "default"
  source = "bionic-server-cloudimg-amd64.img"
  format = "qcow2"
}

data "template_file" "network_config" {
  template = file("${path.module}/network.cfg")
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    hostname = var.hostname
    fqdn = "${var.hostname}.${var.domain}"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}

data "template_cloudinit_config" "config" {
  gzip = false
  base64_encode = false
  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = "${data.template_file.user_data.rendered}"
  }
}


resource "libvirt_pool" "default" {
  name = "default1"
  type = "dir"
  path = "/tmp/kvm"
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "${var.hostname}-commoninit.iso"
  pool = libvirt_pool.default.name# List storage pools using virsh pool-list
  user_data = "${data.template_cloudinit_config.config.rendered}"
  network_config = "${data.template_file.network_config.rendered}"
}


# Define KVM domain to create
resource "libvirt_domain" "ubuntu" {
  name   = "ubuntu.16.04"
  memory = "2048"
  vcpu   = 2

  network_interface {
    network_name = "default" # List networks with virsh net-list
    wait_for_lease = true
  }

  disk {
    volume_id = "${libvirt_volume.os_image.id}"
  }

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

# Output Server IP
output "ip" {
  value = "${libvirt_domain.ubuntu.network_interface.0.addresses}"
}
