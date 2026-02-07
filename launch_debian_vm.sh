sudo cp /var/lib/libvirt/images/debian-12-generic-arm64.qcow2_bkup_resized /var/lib/libvirt/images/debian-12-generic-arm64-GOLDEN.qcow2
sudo virt-install \
  --name k8s-node \
  --memory 512 \
  --vcpus 1 \
  --disk path=/var/lib/libvirt/images/debian-12-generic-arm64-GOLDEN.qcow2,size=20 \
  --import \
  --osinfo detect=on,require=off \
  --network network=br0 \
  --cloud-init root-password-file=/var/lib/libvirt/images/pass.txt,user-data=/var/lib/libvirt/images/data.yaml,disable=on \
  --graphics none
#  --network network=default \
