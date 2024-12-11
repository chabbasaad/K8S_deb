#!/bin/bash
# Initialize Kubernetes Master Node
echo "Initializing Kubernetes master node..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Set up kubeconfig for the current user
echo "Setting up kubeconfig..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Master node setup completed. Apply a pod network plugin to the cluster."
