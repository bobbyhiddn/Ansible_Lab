#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if a VM ID is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <VMID>"
    exit 1
fi

VMID=$1
CONFIG_FILE="/etc/pve/nodes/proxmox/qemu-server/${VMID}.conf"
LOCK_FILE="/var/lock/qemu-server/lock-${VMID}.conf"

# Remove lock file
if [ -f "$LOCK_FILE" ]; then
    echo "Removing lock file for VM $VMID..."
    rm -f "$LOCK_FILE"
else
    echo "No lock file found for VM $VMID."
fi

# Attempt to stop the VM gracefully
echo "Attempting to stop VM $VMID..."
qm stop $VMID

# Wait a bit to ensure the command has time to execute
sleep 5

# Remove the lock line from the VM configuration
if [ -f "$CONFIG_FILE" ]; then
    echo "Removing lock status from VM $VMID configuration..."
    sed -i '/^lock:/d' "$CONFIG_FILE"
else
    echo "Configuration file for VM $VMID not found."
    exit 1
fi

# Destroy the VM
echo "Destroying VM $VMID..."
qm destroy $VMID

# Confirm VM destruction
sleep 2 # Short pause to ensure the command has processed
if qm list | grep -qw $VMID; then
    echo "Failed to destroy VM $VMID."
    exit 1
else
    echo "VM $VMID successfully destroyed."
fi
