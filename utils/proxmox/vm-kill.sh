#!/bin/bash

# Must be run from the Proxmox host
# Must be run as root

# Function to ensure the script is run as root
ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
}

# Function to check VM existence
vm_exists() {
    qm list | grep -qw "\b$VMID\b"
    return $?
}

# Function to remove lock file
remove_lock_file() {
    if [ -f "$LOCK_FILE" ]; then
        echo "Removing lock file for VM $VMID..."
        rm -f "$LOCK_FILE"
    else
        echo "No lock file found for VM $VMID."
    fi
}

# Function to attempt stopping the VM gracefully
stop_vm() {
    echo "Attempting to stop VM $VMID..."
    qm stop $VMID
    sleep 5
}

# Function to remove the lock line from VM configuration
remove_lock_status() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "Removing lock status from VM $VMID configuration..."
        sed -i '/^lock:/d' "$CONFIG_FILE"
    else
        echo "Configuration file for VM $VMID not found."
        exit 1
    fi
}

# Function to destroy the VM
destroy_vm() {
    echo "Destroying VM $VMID..."
    qm destroy $VMID
    sleep 2
    if qm list | grep -qw "\b$VMID\b"; then
        echo "Failed to destroy VM $VMID."
        exit 1
    else
        echo "VM $VMID successfully destroyed."
    fi
}

# Cleaning up related task logs for VM $VMID
cleanup_logs() {
    echo "Cleaning up related task logs for VM $VMID..."
    # Backup original log file before modifications
    cp "$LOG_FILE" "$BACKUP_FILE"

    # Use sed to remove lines that exactly match the VMID in the expected log format
    # The pattern ensures that the VMID is exactly matched, following 'qm*' operations and colon-separated fields
    sed -i "/:qm[^:]*:$VMID:/d" "$LOG_FILE"

    echo "Log cleanup for VM $VMID completed."
}

# Main script execution starts here
ensure_root

if [ $# -eq 0 ]; then
    echo "Usage: $0 <VMID> [VMID...]"
    exit 1
fi

for VMID in "$@"; do
    CONFIG_FILE="/etc/pve/nodes/proxmox/qemu-server/${VMID}.conf"
    LOCK_FILE="/var/lock/qemu-server/lock-${VMID}.conf"
    LOG_FILE="/var/log/pve/tasks/active"
    BACKUP_FILE="${LOG_FILE}.backup"

    if vm_exists; then
        remove_lock_file
        stop_vm
        remove_lock_status
        destroy_vm
    fi

    cleanup_logs
done
