version: 2
ethernets:
  ens8:
    dhcp4: false
    addresses: [${addr}]
    gateway4: ${gateway4} 
    nameservers:
      addresses: [192.168.42.1, 1.0.0.1]
