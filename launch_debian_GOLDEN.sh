#!/bin/bash

# Check for pending nginx pods
PENDING=$(kubectl get pods -l app=nginx --field-selector=status.phase=Pending -o jsonpath='{.items[*].metadata.name}')

if [ -n "$PENDING" ]; then
    echo "Pending Pods detected: $PENDING"
    echo "Launching new VM..."

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

else
    echo "No pending nginx pods, nothing to do."
fi
