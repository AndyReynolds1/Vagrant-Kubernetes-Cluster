# Vagrant Kubernetes Cluster

Testing using Vagrant to automate deploying a local Kubernetes cluster.

Creates specified number of VMs and installs Docker, Kubernetes and initialises a Kubernetes cluster.

## Run

```bash
vagrant up
```

Kubernetes dashboard should be available at `https://192.168.1.180:3000`

Admin token for logging into the dashboard will be output into the `token` file.