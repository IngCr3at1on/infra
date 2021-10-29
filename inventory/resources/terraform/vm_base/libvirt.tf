resource "libvirt_volume" "root_base" {
  name   = "${var.hostname}_base.qcow2"
  pool   = "default"
  source = var.source_image
  format = "qcow2"
}

resource "libvirt_volume" "root" {
  name           = "${var.hostname}.qcow2"
  base_volume_id = libvirt_volume.root_base.id
  pool           = var.libvirt_pool
  size           = var.disk_size
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.tpl")
  vars = {
    user          = var.user
    user_password = var.user_password
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.tpl")
  vars = {
    addr     = var.address
    gateway4 = var.gateway4
  }
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name           = "${var.hostname}.init.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = "default"
}

resource "libvirt_domain" "domain" {
  name      = var.hostname
  memory    = var.memory
  vcpu      = var.cpus
  autostart = true

  cloudinit  = libvirt_cloudinit_disk.cloudinit.id
  qemu_agent = true

  network_interface {
    # bridge = "virbr0"
    network_id = "e3fa847e-9b84-4c1a-b50c-d6910ccf7fb5"
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk { volume_id = libvirt_volume.root.id }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}