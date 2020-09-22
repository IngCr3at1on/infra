resource "libvirt_volume" "node3_root" {
  name   = "node3.qcow2"
  pool   = "default"
  source = local.source_image
  format = "qcow2"
}

data "template_file" "node3_network" {
  template = "${file("${path.module}/node3.network_config.cfg")}"
}

resource "libvirt_cloudinit_disk" "node3_init" {
  name           = "node3.init.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.node3_network.rendered
}

resource "libvirt_domain" "node3" {
  name      = "node3"
  memory    = local.memory
  vcpu      = local.cpu
  autostart = true

  cloudinit  = libvirt_cloudinit_disk.node3_init.id
  qemu_agent = true

  # TODO: figure out how to parameterize this better.
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

  disk { volume_id = libvirt_volume.node3_root.id }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
