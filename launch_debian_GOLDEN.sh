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
    VM_NAME="k8s-node-$RANDOM_SUFFIX"
    FQDN="$VM_NAME.example.com"
    sudo cp /var/lib/libvirt/images/debian-12-generic-arm64.qcow2_bkup_resized /var/lib/libvirt/images/vm-$VM_NAME.qcow2
    export VM_NAME FQDN
    envsubst '$VM_NAME $FQDN' < /var/lib/libvirt/images/data.yaml | sudo tee /var/lib/libvirt/images/data-$VM_NAME.yaml > /dev/null

    sudo virt-install \
      --name "$VM_NAME" \
      --memory 512 \
      --vcpus 1 \
      --disk path=/var/lib/libvirt/images/vm-$VM_NAME.qcow2,size=20 \
      --import \
      --osinfo detect=on,require=off \
      --network network=br0 \
      --cloud-init root-password-file=/var/lib/libvirt/images/pass.txt,user-data=/var/lib/libvirt/images/data-$VM_NAME.yaml,disable=on \
      --graphics none

else
    echo "No pending pods, nothing to do."
fi
