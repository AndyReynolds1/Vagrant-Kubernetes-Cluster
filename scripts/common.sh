#! /bin/bash

KUBERNETES_VERSION="1.30"

# Install containerd - https://www.nocentino.com/posts/2021-12-27-installing-and-configuring-containerd-as-a-kubernetes-container-runtime/

# Configure required modules
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Configure required sysctl to persist across system reboots
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl parameters without reboot to current running enviroment
sudo sysctl --system

# Install containerd packages
sudo apt-get update 
sudo apt-get install -y containerd

# Create a containerd configuration file
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Set the cgroup driver for runc to systemd
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd with the new configuration
sudo systemctl restart containerd

# Disable swap
sudo swapoff -a
sudo sed -i 's/\/swap.img/#\/swap.img/' /etc/fstab

sudo sysctl net.bridge.bridge-nf-call-iptables=1

# Install Kubernetes tools
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubectl kubeadm
sudo apt-mark hold kubelet kubeadm kubectl

# Install Helm
sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh