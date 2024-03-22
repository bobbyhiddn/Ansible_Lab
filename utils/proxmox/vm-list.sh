#!/bin/bash

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
CSRF_TOKEN=$(echo $RESPONSE | jq -r '.data.CSRFPreventionToken')

# Check if we successfully obtained a ticket
if [ -z "$TICKET" ] || [ "$TICKET" == "null" ]; then
  echo "Failed to obtain a ticket from Proxmox API."
  exit 1
fi

echo "Obtained ticket: $TICKET"
echo "CSRF Token: $CSRF_TOKEN"

# Use the ticket for subsequent API calls
# Example: List VMs on a specific Proxmox node
NODE="pve" # Adjust the node name as necessary
curl -k -s -b "PVEAuthCookie=$TICKET" "https://${PROXMOX_IP}:8006/api2/json/nodes/${NODE}/qemu"
