#!/bin/bash

# Check for pending pods
PENDING=$( \
  kubectl get pods -l app=nginx --field-selector=status.phase=Pending -o jsonpath='{.items[*].metadata.name}'; \
  kubectl get pods -n keda --field-selector=status.phase=Pending -o jsonpath='{.items[*].metadata.name}' \
)
#PENDING=$(kubectl get pods -l app=nginx --field-selector=status.phase=Pending -o jsonpath='{.items[*].metadata.name}')
#PENDING=$(kubectl get pods -n keda --field-selector=status.phase=Pending -o jsonpath='{.items[*].metadata.name}')


# if pending pods, then launch VM
if [ -n "$PENDING" ]; then
    echo "Pending Pods detected: $PENDING"
    echo "Launching new VM..."
    RANDOM_SUFFIX=$(tr -dc a-z0-9 </dev/urandom | head -c 8)
    sudo cp /var/lib/libvirt/images/debian-12-generic-arm64.qcow2_bkup_resized /var/lib/libvirt/images/vm-$RANDOM_SUFFIX.qcow2
    VM_NAME="k8s-node-$RANDOM_SUFFIX"
    FQDN="$VM_NAME.example.com"
    export VM_NAME FQDN
    envsubst '$VM_NAME $FQDN' < /var/lib/libvirt/images/data.yaml | sudo tee /var/lib/libvirt/images/data-$RANDOM_SUFFIX.yaml > /dev/null

    sudo virt-install \
      --name "$VM_NAME" \
      --memory 512 \
      --vcpus 1 \
      --disk path=/var/lib/libvirt/images/vm-$RANDOM_SUFFIX.qcow2,size=20 \
      --import \
      --osinfo detect=on,require=off \
      --network network=br0 \
      --cloud-init root-password-file=/var/lib/libvirt/images/pass.txt,user-data=/var/lib/libvirt/images/data-$RANDOM_SUFFIX.yaml,disable=on \
      --graphics none

else
    echo "No pending nginx pods, nothing to do."
fi
