#!/usr/bin/env bash
set -euo pipefail

echo "=== Docker official repository setup start ==="

# Detect Ubuntu codename safely
CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")

if [[ -z "$CODENAME" ]]; then
  echo "ERROR: Failed to detect Ubuntu codename"
  exit 1
fi

echo "Detected Ubuntu codename: $CODENAME"

# Update apt and install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Create keyrings directory
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker's official GPG key
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository (NO variable expansion inside heredoc)
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Update apt with Docker repo
sudo apt-get update

# Install Docker packages
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Enable Docker on boot & start
sudo systemctl enable --now docker

# Add current user to docker group
sudo usermod -aG docker "$USER"

echo
echo "=== Docker installation completed successfully ==="
echo
echo "IMPORTANT:"
echo "You have been added to the 'docker' group."
echo "Log out and log back in to apply group membership."
echo
