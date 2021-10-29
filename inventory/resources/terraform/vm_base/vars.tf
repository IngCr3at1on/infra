variable "source_image" {
  type    = string
  default = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

variable "user" {
  type = string
}

variable "user_password" {
  type = string
}

variable "hostname" {
  type = string
}

variable "cpus" {
  type    = number
  default = 1
}

variable "memory" {
  type    = number
  default = 1024
}

variable "disk_size" {
  type    = number
  default = 1024 * 1024 * 1024 * 20
}

variable "libvirt_uri" {
  type    = string
  default = "qemu:///system"
}

variable "libvirt_pool" {
  type    = string
  default = "default"
}

variable "address" {
  type = string
}

variable "gateway4" {
  type    = string
  default = "192.168.122.1"
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
  uri = var.libvirt_uri
}