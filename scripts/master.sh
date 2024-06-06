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

# Install Helm
sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh

# Install Dashboard
sudo helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
sudo helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

# Create dashboard admin user
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

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: "admin-user"   
type: kubernetes.io/service-account-token  
EOF

# Export admin token for dashboard
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d >> /vagrant/config/token

# Patch dashboard service to use NodePort on specific port
kubectl patch svc kubernetes-dashboard-kong-proxy -n kubernetes-dashboard --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":30000}]'
