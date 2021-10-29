#cloud-config
ssh_pwauth: false

package_update: true
package_upgrade: true
packages:
    - qemu-guest-agent
    - cloud-initramfs-growroot

users:
  - name: ${user}
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    groups: wheel
    lock-passwd: false
    passwd: ${user_password}
    ssh_import_id:
    - gh:IngCr3at1on
