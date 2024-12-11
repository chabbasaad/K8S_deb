#!/bin/bash
# Prompt for IP addresses and suffix
echo "Please enter the details for the node setup."
read -p "Enter the master IP (e.g., 192.168.1.23): " MASTER_IP
read -p "Enter the first worker IP (e.g., 192.168.1.24): " WORKER1_IP
read -p "Enter the second worker IP (e.g., 192.168.1.25): " WORKER2_IP
read -p "Enter the node type (e.g., master or worker01/worker02): " NODE_TYPE
read -p "Enter the suffix (e.g., linuxtechi): " SUFFIX

# Set Hostname
HOSTNAME="k8s-$NODE_TYPE.$SUFFIX.local"
echo "Setting hostname to $HOSTNAME..."
sudo hostnamectl set-hostname "$HOSTNAME"

# Update /etc/hosts file
echo "Updating /etc/hosts file..."
cat <<EOF | sudo tee /etc/hosts
$MASTER_IP   k8s-master.$SUFFIX.local     k8s-master
$WORKER1_IP  k8s-worker01.$SUFFIX.local   k8s-worker01
$WORKER2_IP  k8s-worker02.$SUFFIX.local   k8s-worker02
EOF

# Disable Swap
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Containerd Runtime
echo "Installing containerd runtime..."
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo apt update
sudo apt -y install containerd

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1

# Set systemd as the cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# Add Kubernetes Repository
echo "Adding Kubernetes apt repository..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes Tools
echo "Installing Kubernetes tools..."
sudo apt update
sudo apt install kubelet kubeadm kubectl -y
sudo apt-mark hold kubelet kubeadm kubectl

echo "Setup completed for $HOSTNAME. Reboot the system to apply changes."
