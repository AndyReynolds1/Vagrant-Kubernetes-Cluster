#! /bin/bash

# Install Kubernetes Dashboard - https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard
echo "Installing kubernetes-dashboard..."
sudo helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
sudo helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard --set metrics-server.enabled=true

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

# Patch kubernetes-dashboard-kong-proxy service to switch from ClusterIP to NodePort to expose dashboard outside the cluster
kubectl patch svc kubernetes-dashboard-kong-proxy -n kubernetes-dashboard --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":30000}]'
