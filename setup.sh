#!/bin/bash
# Initial Setup Script for Raspberry Pi 3 - Docker & Docker-Compose Installation
# This script installs Ansible and runs the playbook to set up Docker

set -e  # Exit on error

echo "=========================================="
echo "Raspberry Pi Docker Setup"
echo "=========================================="
echo ""

# Update package list
echo "Step 1/4: Updating package list..."
sudo apt update

# Install Ansible
echo ""
echo "Step 2/4: Installing Ansible..."
sudo apt install -y ansible

# Create localhost inventory file
echo ""
echo "Step 3/4: Creating localhost inventory..."
cat > localhost.ini << EOF
[local]
localhost ansible_connection=local
EOF

echo "Inventory file created: localhost.ini"

# Run the Ansible playbook
echo ""
echo "Step 4/4: Running Ansible playbook..."
ansible-playbook -i localhost.ini ansible.yml

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "IMPORTANT: Please log out and log back in (or reboot)"
echo "for Docker group membership to take effect."
echo ""
echo "After re-login, test with: docker --version"
echo "                           docker-compose --version"
echo ""
