#!/bin/bash

# Check if VM ID was passed as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 VM_ID"
    exit 1
fi

VM_ID=$1

# Ask for the Proxmox API password
echo "Enter the Proxmox API password:"
read -s PASSWORD

# Set the Proxmox server IP address and credentials
PROXMOX_IP="192.168.0.128"
USERNAME="root@pam"

# Authenticate and obtain a ticket
RESPONSE=$(curl -k -s -d "username=${USERNAME}" -d "password=${PASSWORD}" "https://${PROXMOX_IP}:8006/api2/json/access/ticket")

# Extract the ticket and CSRFPreventionToken using jq
TICKET=$(echo $RESPONSE | jq -r '.data.ticket')

# Check if we successfully obtained a ticket
if [ -z "$TICKET" ] || [ "$TICKET" == "null" ]; then
  echo "Failed to obtain a ticket from Proxmox API."
  exit 1
fi

echo "Obtained ticket: $TICKET"

# Assuming NODE variable is set or hardcoded here, or you could prompt for it
NODE="proxmox" # Adjust the node name as necessary

# Use the ticket to list information for the specific VM by VM_ID
# For a QEMU VM:
echo "Getting info for QEMU VM ID $VM_ID on node $NODE..."
curl -k -s -b "PVEAuthCookie=$TICKET" "https://${PROXMOX_IP}:8006/api2/json/nodes/${NODE}/qemu/${VM_ID}/status/current"

# Uncomment the following lines if you also need to fetch information for an LXC container by ID
# echo "Getting info for LXC container ID $VM_ID on node $NODE..."
# curl -k -s -b "PVEAuthCookie=$TICKET" "https://${PROXMOX_IP}:8006/api2/json/nodes/${NODE}/lxc/${VM_ID}/status/current"
