variable "uri" {
    type = string
}

variable "pool" {
    type = string
}

terraform {
    required_version = ">= 1.0.7"
    required_providers {
        libvirt = {
            source  = "dmacvicar/libvirt"
            version = "0.6.11"
        }
    }
}

provider "libvirt" {
    uri = var.uri
}

resource "libvirt_pool" "default" {
    name = "default"
    type = "dir"
    path = var.pool
}
