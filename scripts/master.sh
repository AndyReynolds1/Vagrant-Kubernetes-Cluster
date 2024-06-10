#! /bin/bash

# Initialise cluster
MASTER_IP="192.168.56.10"
NODENAME=$(hostname -s)
POD_CIDR="10.0.0.1/24"

sudo kubeadm init --apiserver-advertise-address=$MASTER_IP  --apiserver-cert-extra-sans=$MASTER_IP --node-name $NODENAME --pod-network-cidr=$POD_CIDR

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Remove previous config files
rm -rf /vagrant/config

# Create path
mkdir -p /vagrant/config

cp -i /etc/kubernetes/admin.conf /vagrant/config/config
touch /vagrant/config/join.sh
chmod +x /vagrant/config/join.sh

# Create cluster join command
kubeadm token create --print-join-command > /vagrant/config/join.sh

# Install Calico CNI
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml