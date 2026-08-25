# KIND Kubernetes Installation Guide

A practical, step-by-step guide to installing **Docker, KIND, and kubectl on Ubuntu**, then creating and verifying a local Kubernetes cluster with **one control-plane node and two worker nodes**.

---

## Requirements

Before starting, make sure you have:

* Ubuntu-based Linux distribution
* Internet access
* `sudo` privileges
* x86_64 architecture for the KIND installation commands below

---

## Overview

This guide covers:

1. Updating Ubuntu packages
2. Installing Docker
3. Enabling and starting Docker
4. Verifying Docker
5. Installing KIND
6. Verifying KIND
7. Installing kubectl
8. Verifying kubectl
9. Creating a Kubernetes cluster
10. Verifying the cluster
11. Understanding KIND networking and ports
12. Accessing Kubernetes services
13. Deleting the cluster when no longer needed

### Architecture

The cluster created in this guide will look like:

```text
                    KIND Kubernetes Cluster
                    -----------------------

                         Control Plane
                       +---------------+
                       |   API Server   |
                       |   Scheduler    |
                       |  Controllers   |
                       |     etcd       |
                       +-------+-------+
                               |
              +----------------+----------------+
              |                                 |
      +-------v-------+                 +-------v-------+
      | Worker Node 1 |                 | Worker Node 2 |
      |               |                 |               |
      |   Kubelet     |                 |   Kubelet     |
      |   Container   |                 |   Container   |
      |   Workloads   |                 |   Workloads   |
      +---------------+                 +---------------+

                         Docker
                           |
              +------------+------------+
              |            |            |
          Container    Container    Container
```

> **Important:** KIND (Kubernetes IN Docker) runs Kubernetes nodes as Docker containers. This makes it useful for local development, learning, testing, and CI environments.

---

# Installation Steps

## 1. Update Ubuntu

Update the package lists and install available updates.

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 2. Install Docker

KIND uses Docker as the container runtime for its Kubernetes nodes.

```bash
sudo apt install docker.io -y
```

---

## 3. Enable Docker

Configure Docker to start automatically when the system boots.

```bash
sudo systemctl enable docker
```

---

## 4. Start Docker

Start the Docker daemon immediately.

```bash
sudo systemctl start docker
```

---

## 5. Verify Docker

Check that Docker is installed and running.

```bash
docker --version
```

Then:

```bash
docker ps
```

If you receive a permission error such as:

```text
permission denied while trying to connect to the Docker daemon
```

add your current user to the Docker group:

```bash
sudo usermod -aG docker $USER
```

Apply the group membership to the current session:

```bash
newgrp docker
```

Then verify again:

```bash
docker ps
```

You should be able to execute Docker commands without `sudo`.

---

# 6. Install KIND

Download the KIND binary for Linux x86_64:

```bash
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
```

Make it executable:

```bash
chmod +x ./kind
```

Move it into `/usr/local/bin`:

```bash
sudo mv ./kind /usr/local/bin/kind
```

---

# 7. Verify KIND

Check the installed KIND version:

```bash
kind version
```

Expected output will look similar to:

```text
kind v0.31.0
```

---

# 8. Install kubectl

Download the latest stable Kubernetes command-line client:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

Make it executable:

```bash
chmod +x kubectl
```

Move it into a directory available in your PATH:

```bash
sudo mv kubectl /usr/local/bin/
```

---

# 9. Verify kubectl

Check the kubectl client version:

```bash
kubectl version --client
```

You can also verify where kubectl is installed:

```bash
which kubectl
```

---

# 10. Create a Kubernetes Cluster

Create a KIND configuration file:

```bash
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```

The configuration creates:

```text
1 Control Plane
      +
2 Worker Nodes
      =
3 Kubernetes Nodes
```

Verify the configuration:

```bash
cat kind-config.yaml
```

Now create the cluster:

```bash
kind create cluster --name dev-cluster --config kind-config.yaml
```

KIND will:

```text
1. Create Docker network
        ↓
2. Create control-plane container
        ↓
3. Create worker containers
        ↓
4. Bootstrap Kubernetes
        ↓
5. Configure kubeadm
        ↓
6. Start Kubernetes components
        ↓
7. Configure kubectl context
```

---

# 11. Verify the Cluster

List KIND clusters:

```bash
kind get clusters
```

Expected:

```text
dev-cluster
```

Check the Kubernetes nodes:

```bash
kubectl get nodes
```

Expected topology:

```text
NAME                         STATUS   ROLES           AGE
dev-cluster-control-plane    Ready    control-plane   ...
dev-cluster-worker           Ready    <none>          ...
dev-cluster-worker2          Ready    <none>          ...
```

Check additional cluster information:

```bash
kubectl cluster-info
```

Check all Kubernetes system pods:

```bash
kubectl get pods -A
```

---

# 12. Verify the Current kubectl Context

KIND automatically creates a kubectl context.

Check the current context:

```bash
kubectl config current-context
```

Expected:

```text
kind-dev-cluster
```

List all available contexts:

```bash
kubectl config get-contexts
```

Switch to the KIND cluster if required:

```bash
kubectl config use-context kind-dev-cluster
```

---

# 13. Explore the Cluster

Check nodes:

```bash
kubectl get nodes
```

Check namespaces:

```bash
kubectl get namespaces
```

Check pods:

```bash
kubectl get pods -A
```

Check services:

```bash
kubectl get services -A
```

Check cluster information:

```bash
kubectl cluster-info
```

---

# Ports & Services Documentation

## KIND Cluster Ports

KIND runs Kubernetes nodes inside Docker containers. Kubernetes uses several important ports internally.

| Protocol |        Port | Purpose                  |
| -------- | ----------: | ------------------------ |
| TCP      |        6443 | Kubernetes API Server    |
| TCP      |       10250 | Kubelet API              |
| TCP      | 30000-32767 | NodePort Services        |
| TCP      |        8080 | kubectl proxy, when used |

> Port availability depends on how the KIND cluster and Docker networking are configured. Not every internal Kubernetes port is automatically exposed directly to the host.

---

# Network Access

KIND is primarily designed for **local Kubernetes development and testing**.

The general flow is:

```text
Your Application
       |
       v
localhost
       |
       v
Docker
       |
       v
KIND Node Container
       |
       v
Kubernetes Service
       |
       v
Pod
```

For services exposed to the host, you may use:

```text
localhost:<port>
```

or:

```text
127.0.0.1:<port>
```

Unlike an Azure-managed or cloud-hosted Kubernetes cluster, KIND does not require configuring an Azure NSG, Azure Load Balancer, or public IP simply to communicate with the local cluster.

---

# Accessing Kubernetes Services

## View Services

```bash
kubectl get svc
```

Example:

```text
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP
```

---

## Port Forwarding

Port forwarding is one of the easiest ways to access a Kubernetes application during local development.

```bash
kubectl port-forward svc/<service-name> 8080:80
```

Example:

```bash
kubectl port-forward svc/my-service 8080:80
```

Then access it from another terminal:

```bash
curl http://localhost:8080
```

The traffic flow is:

```text
Browser / curl
      |
      | localhost:8080
      v
kubectl port-forward
      |
      v
Kubernetes Service :80
      |
      v
Pod
```

---

# NodePort

If an application is exposed using a NodePort:

```bash
kubectl get svc
```

You may see:

```text
NAME          TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
my-service    NodePort   10.96.x.x       <none>        80:30000/TCP
```

The NodePort is:

```text
30000
```

Depending on the KIND port configuration, host access may require explicit Docker port mappings.

For a reliable local-development workflow, `kubectl port-forward` is usually simpler.

---

# Delete the Cluster

When you no longer need the cluster:

```bash
kind delete cluster --name dev-cluster
```

Verify:

```bash
kind get clusters
```

The `dev-cluster` should no longer appear.

---

# Useful Commands

### Docker

```bash
docker ps
docker images
docker network ls
docker info
```

### KIND

```bash
kind get clusters
kind get nodes --name dev-cluster
kind export logs
kind delete cluster --name dev-cluster
```

### kubectl

```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
kubectl get namespaces
kubectl cluster-info
kubectl config get-contexts
kubectl config current-context
```

---

# Troubleshooting

## Docker permission denied

If:

```bash
docker ps
```

returns:

```text
permission denied while trying to connect to the Docker daemon
```

run:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Then:

```bash
docker ps
```

---

## Check Docker Service

```bash
sudo systemctl status docker
```

If Docker is not running:

```bash
sudo systemctl start docker
```

---

## Check KIND Containers

```bash
docker ps
```

You should see containers associated with your KIND cluster.

For example:

```text
kindest/node
```

---

## Check Kubernetes Nodes

```bash
kubectl get nodes
```

If a node is not `Ready`, investigate with:

```bash
kubectl describe node <node-name>
```

---

## Check Kubernetes System Pods

```bash
kubectl get pods -A
```

For a more detailed view:

```bash
kubectl get pods -A -o wide
```

---

# Mental Model

The most important thing to understand is that **KIND is not creating three physical or virtual machines**.

Instead:

```text
                     Ubuntu VM
                         |
                       Docker
                         |
        +----------------+----------------+
        |                |                |
        v                v                v
   Docker Container  Docker Container  Docker Container
        |                |                |
        v                v                v
 Control Plane       Worker Node 1     Worker Node 2
        |                |                |
        +----------------+----------------+
                         |
                    Kubernetes
```

This gives you a lightweight environment where you can learn Kubernetes architecture and operations without provisioning multiple VMs.

---

# Learning Roadmap

This repository will progressively cover:

```text
Kubernetes Fundamentals
        ↓
Architecture
        ↓
kubectl
        ↓
Pods
        ↓
Deployments
        ↓
ReplicaSets
        ↓
Services
        ↓
ConfigMaps & Secrets
        ↓
Networking
        ↓
Storage
        ↓
Ingress
        ↓
Scheduling
        ↓
Security
        ↓
Helm
        ↓
Troubleshooting
        ↓
Production Architecture
        ↓
AKS
```

The goal is not just to memorize Kubernetes commands, but to understand **what happens behind the scenes when a Kubernetes command is executed**.

---

## Connect with Shubham Tripathi

**Shubham Tripathi**

DevOps / DevSecOps Engineer

Focus areas:

* Azure
* Terraform
* Kubernetes
* Docker
* CI/CD
* Cloud Infrastructure
* DevSecOps
