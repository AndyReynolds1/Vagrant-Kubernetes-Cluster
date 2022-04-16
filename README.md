# Vagrant Kubernetes Cluster

Testing using Vagrant to automate deploying a local Kubernetes cluster.

Creates specified number of VMs and installs Docker, Kubernetes and initialises a Kubernetes cluster.

Updated to use latest Kubernetes version and switch container runtime to containerd instead of Docker.

## Run

```bash
vagrant up
```

Kubernetes dashboard should be available at `https://192.168.56.10:30000`

Admin token for logging into the dashboard will be output into the `config/token` file.