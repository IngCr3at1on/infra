terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.2"
    }
  }
  backend "gcs" {
    bucket = "lab_ingcr3at1on_com_infra_terraform-state"
    prefix = "dev"
    credentials = "../../../../auth/infra-287801-b1bc0b27ce22.json"
  }
}

locals {
  hostname     = "dev"
  memory       = 1024 * 6
  cpu          = 1
  # FIXME: need to re-remember how to use my own images...
  source_image = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

provider "libvirt" {
  uri = "qemu+ssh://ing@192.168.42.10/system?keyfile=id_rsa"
}
