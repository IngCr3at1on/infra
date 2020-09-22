resource "libvirt_volume" "root_base" {
  name   = "ubuntu_base.qcow2"
  pool   = "default"
  source = local.source_image
  format = "qcow2"
}

resource "libvirt_volume" "root" {
  name           = "${local.hostname}.qcow2"
  base_volume_id = libvirt_volume.root_base.id
  pool           = "default"
  size           = 1024 * 1024 * 1024 * 20
}

data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.tpl")}"
  vars = {
    ing_password  = local.ing_password
  }
}

data "template_file" "network_config" {
  template = "${file("${path.module}/network_config.cfg")}"
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name           = "${local.hostname}.init.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool = "default"
}

resource "libvirt_domain" "domain" {
  name      = local.hostname
  memory    = local.memory
  vcpu      = local.cpu
  autostart = true

  cloudinit  = libvirt_cloudinit_disk.cloudinit.id
  qemu_agent = true

  network_interface {
    bridge = "br0"
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
