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
VM_INFO=$(curl -k -s -b "PVEAuthCookie=$TICKET" "https://${PROXMOX_IP}:8006/api2/json/nodes/${NODE}/qemu/${VM_ID}/status/current")

# Parse the VM information using jq
echo "VM Status: $(echo $VM_INFO | jq -r '.data.status')"
echo "VM CPU Usage: $(echo $VM_INFO | jq -r '.data.cpu')"
echo "VM Memory Usage: $(echo $VM_INFO | jq -r '.data.mem')"

# Fetch the VM configuration to get the IP address
VM_CONFIG=$(curl -k -s -b "PVEAuthCookie=$TICKET" "https://${PROXMOX_IP}:8006/api2/json/nodes/${NODE}/qemu/${VM_ID}/config")

# Extract the IP address from the VM configuration
IP_ADDRESS=$(echo $VM_CONFIG | jq -r '.data.net0' | awk -F'=' '{print $2}' | awk -F',' '{print $1}')

echo "VM IP Address: $IP_ADDRESS"
# Add more fields as needed