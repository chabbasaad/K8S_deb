#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Colors for output
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"

log() {
  echo -e "${green}[INFO] $1${reset}"
}

error() {
  echo -e "${red}[ERROR] $1${reset}" >&2
  exit 1
}

# Update and upgrade the system
log "Updating and upgrading the system..."
sudo apt-get update && sudo apt-get upgrade -y || error "Failed to update the system."

# Install prerequisites
log "Installing prerequisites..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gpg || error "Failed to install prerequisites."

# Install Docker
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - || error "Failed to add Docker GPG key."
echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update || error "Failed to update after adding Docker repo."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io || error "Failed to install Docker."
sudo systemctl enable docker || error "Failed to enable Docker."
sudo systemctl start docker || error "Failed to start Docker."
docker --version || error "Docker installation failed."

# Install Kubernetes tools
log "Installing Kubernetes tools..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || error "Failed to add Kubernetes GPG key."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update || error "Failed to update after adding Kubernetes repo."
sudo apt-get install -y kubelet kubeadm kubectl || error "Failed to install Kubernetes tools."
sudo apt-mark hold kubelet kubeadm kubectl || error "Failed to hold Kubernetes versions."
sudo systemctl enable --now kubelet || error "Failed to enable kubelet."

# Disable swap
log "Disabling swap..."
sudo swapoff -a || error "Failed to disable swap."
sudo sed -i '/ swap / s/^/#/' /etc/fstab || error "Failed to comment out swap in /etc/fstab."

# Install Containerd
log "Installing and configuring Containerd..."
sudo apt-get install -y containerd || error "Failed to install Containerd."
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml || error "Failed to configure Containerd."
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || error "Failed to set SystemdCgroup to true."
sudo systemctl restart containerd || error "Failed to restart Containerd."
sudo systemctl enable containerd || error "Failed to enable Containerd."

log "Script completed successfully! Docker and Kubernetes are installed and configured."
