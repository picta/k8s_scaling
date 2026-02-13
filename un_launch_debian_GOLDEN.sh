#!/bin/bash

# If any pod is pending, do nothing
if kubectl get pods -A --field-selector=status.phase=Pending | grep -q .; then
  echo "Pending pods detected. No nodes are safe to delete."
  exit 0
fi

kubectl get nodes \
  -l '!node-role.kubernetes.io/control-plane' \
  --no-headers \
  -o custom-columns=NAME:.metadata.name \
| while read NODE; do

  echo "Evaluating node: $NODE"

  # Skip unschedulable nodes
  if kubectl get node "$NODE" -o jsonpath='{.spec.unschedulable}' 2>/dev/null | grep -q true; then
    echo "  - Skipping (unschedulable)"
    continue
  fi

  # Check for workload pods
  WORKLOAD_PODS=$(kubectl get pods -A \
    --field-selector spec.nodeName=$NODE \
    -o jsonpath='{range .items[*]}{.metadata.ownerReferences[0].kind}{"\n"}{end}' \
    | grep -v DaemonSet || true)

  if [ -n "$WORKLOAD_PODS" ]; then
    echo "  - NOT safe (workload pods present)"
    continue
  fi

  # Final authority: drain simulation
  if kubectl drain "$NODE" \
    --ignore-daemonsets \
    --delete-emptydir-data \
    --dry-run=client >/dev/null 2>&1; then
    echo "SAFE TO DELETE"
    echo "Deleting node $NODE..."
    kubectl delete node "$NODE"
    sudo virsh destroy $NODE
    sudo virsh undefine $NODE --nvram
    sudo rm /var/lib/libvirt/images/vm-$NODE.qcow2
    sudo rm /var/lib/libvirt/images/data-$NODE.yaml
  else
    echo "  - NOT safe (drain would fail)"
  fi
done

