#! /bin/bash

# Initialise cluster
MASTER_IP="192.168.56.10"
NODENAME=$(hostname -s)
POD_CIDR="10.0.0.1/24"

DASHBOARD_VERSION="v2.7.0"

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

# Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics-server deployment to use --kubelet-insecure-tls arg - https://github.com/kubernetes-sigs/metrics-server
kubectl patch deployment metrics-server -n kube-system --type='json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls" }]'

# Install Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/$DASHBOARD_VERSION/aio/deploy/recommended.yaml

# Create dashboard User
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Export admin token for dashboard
kubectl -n kubernetes-dashboard create token admin-user >> /vagrant/config/token

# Patch dashboard service to use NodePort on specific port
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":30000}]'
