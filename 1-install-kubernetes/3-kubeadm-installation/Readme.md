# Kubernetes Cluster Setup on Azure VMs — 1 Control Plane + N Workers

This guide helps you create a **Kubernetes cluster using kubeadm on Azure Virtual Machines**.

It is designed for:

* Kubernetes learning
* DevOps hands-on practice
* Azure Kubernetes experimentation
* Kubernetes architecture demonstrations
* Interview preparation
* Personal labs and projects

The cluster architecture consists of:

* **1 Control Plane node**
* **N Worker nodes**
* Ubuntu-based Azure VMs
* Container runtime
* kubeadm
* kubelet
* kubectl
* Calico networking

---

# 🧱 Architecture

The final architecture will look like this:

```text
                         Internet
                            |
                            |
                       Azure NSG
                            |
                            |
                    +-------v-------+
                    | Control Plane |
                    |   Azure VM    |
                    |               |
                    | kube-apiserver|
                    | kube-scheduler|
                    | controllers   |
                    | etcd          |
                    | kubelet       |
                    +-------+-------+
                            |
                    Private Network
                            |
              +-------------+-------------+
              |                           |
      +-------v-------+           +-------v-------+
      |   Worker 01   |           |   Worker 02   |
      |   Azure VM    |           |   Azure VM    |
      |               |           |               |
      |    kubelet    |           |    kubelet    |
      |    kube-proxy |           |    kube-proxy |
      |    Pods       |           |    Pods       |
      +---------------+           +---------------+
```

All Kubernetes nodes should communicate with each other using their **Azure private IP addresses**.

---

# ☁️ Azure VM Configuration

For a learning environment, you can use the following configuration.

## ✅ Control Plane VM

Recommended minimum configuration:

* VM Size: `Standard_B2s`
* CPU: 2 vCPU
* RAM: 4 GB
* OS: Ubuntu 22.04 LTS or newer supported Ubuntu version
* OS Disk: 30 GB or more
* Network: Same Azure VNet as worker nodes

> For a serious production cluster, use appropriately sized VMs based on workload requirements. The configuration above is intended for learning and lab environments.

---

## ✅ Worker VM

Recommended minimum configuration:

* VM Size: `Standard_B2s`
* CPU: 2 vCPU
* RAM: 4 GB
* OS: Ubuntu 22.04 LTS or newer supported Ubuntu version
* OS Disk: 30 GB or more
* Network: Same Azure VNet as the control plane

For multiple workers:

```text
Control Plane VM
      |
      +---- Worker VM 01
      |
      +---- Worker VM 02
      |
      +---- Worker VM 03
```

---

# 🌐 Azure Network Architecture

All VMs should be placed inside the same:

```text
Azure Subscription
       |
    Resource Group
       |
      VNet
       |
   +---+----------------+
   |                    |
Subnet                NSG
   |
   +----------------------------+
   |             |              |
Control       Worker 01      Worker 02
Plane VM         VM             VM
```

Example:

```text
VNet: 10.0.0.0/16

Subnet: 10.0.1.0/24

Control Plane:
10.0.1.4

Worker 01:
10.0.1.5

Worker 02:
10.0.1.6
```

> **Important:** Kubernetes node-to-node communication should use **private IP addresses**, not public IP addresses.

---

# 🔐 Azure NSG Rules

The Azure Network Security Group controls inbound and outbound network traffic to the VMs.

## Control Plane VM

Recommended inbound rules for a lab environment:

| Protocol |      Port | Source                  | Purpose                 |
| -------- | --------: | ----------------------- | ----------------------- |
| TCP      |        22 | Your IP                 | SSH access              |
| TCP      |      6443 | Worker subnet           | Kubernetes API Server   |
| TCP      | 2379-2380 | Control Plane           | etcd                    |
| TCP      |     10250 | Control Plane + Workers | Kubelet API             |
| TCP      |     10257 | Control Plane           | kube-controller-manager |
| TCP      |     10259 | Control Plane           | kube-scheduler          |

---

## Worker Nodes

Recommended inbound rules:

| Protocol |        Port | Source           | Purpose           |
| -------- | ----------: | ---------------- | ----------------- |
| TCP      |          22 | Your IP          | SSH access        |
| TCP      |       10250 | Control Plane    | Kubelet API       |
| TCP      | 30000-32767 | Required clients | NodePort Services |

---

## Pod Network

The pod network depends on the CNI plugin.

For this guide, **Calico** is used.

Calico may require additional networking depending on the selected configuration.

Always ensure that the required traffic between Kubernetes nodes is permitted by the Azure NSG and operating-system firewall.

---

# 🔑 Important Azure Networking Rule

The most important communication path is:

```text
Worker Node
     |
     | TCP 6443
     |
     v
Control Plane
     |
     v
kube-apiserver
```

Therefore:

```text
Worker Private IP
       |
       | TCP/6443
       v
Control Plane Private IP
```

For example:

```text
Worker 01
10.0.1.5
     |
     | TCP 6443
     v
Control Plane
10.0.1.4
```

Do **not** expose Kubernetes API port `6443` publicly unless there is a specific requirement and appropriate security controls.

---

# 📌 Azure VM Preparation

SSH into each Azure VM.

For example:

```bash
ssh azureuser@<CONTROL-PLANE-PUBLIC-IP>
```

For a worker:

```bash
ssh azureuser@<WORKER-PUBLIC-IP>
```

Once connected, verify the private IP:

```bash
hostname -I
```

You should see the Azure private IP.

Example:

```text
10.0.1.4
```

---

# 📦 Prerequisite: Install Docker / Container Runtime

Before running the Kubernetes setup scripts, install the required container runtime on **every node**.

If using the Docker installation script from this repository:

```bash
chmod +x docker-install.sh
./docker-install.sh
```

Repository:

[Kubernetes repository — Shubham Tripathi] (https://github.com/tripathicle/kubernetes.git)

After installation, verify:

```bash
docker --version
```

And:

```bash
docker ps
```

> Kubernetes currently uses a CRI-compatible container runtime. If your setup uses containerd, configure containerd appropriately. Docker itself is not directly used as the Kubernetes CRI in modern Kubernetes versions without an additional CRI adapter.

---

# ⚙️ CONTROL PLANE SETUP

## Step 1: Clone the Repository

On the control-plane Azure VM:

```bash
git clone https://github.com/tripathicle/kubernetes.git
```

Move into the appropriate directory:

```bash
cd kubernetes-tutorial
```

---

## Step 2: Run the Control Plane Setup

Make the script executable:

```bash
chmod +x master-node-setup.sh
```

Run:

```bash
./master-node-setup.sh
```

The control-plane setup script should perform tasks such as:

* Configure the hostname
* Disable swap
* Configure kernel networking
* Configure the container runtime
* Install kubeadm
* Install kubelet
* Install kubectl
* Initialize the Kubernetes control plane
* Configure kubectl
* Install the Calico CNI

---

# 🧠 What Happens During `kubeadm init`

The most important command is:

```bash
sudo kubeadm init
```

This initializes the Kubernetes control plane.

Conceptually:

```text
kubeadm init
      |
      +---- kube-apiserver
      |
      +---- etcd
      |
      +---- kube-scheduler
      |
      +---- kube-controller-manager
      |
      +---- kubelet
      |
      +---- Certificates
      |
      +---- kubeconfig
```

After initialization, Kubernetes generates a worker join command similar to:

```bash
kubeadm join 10.0.1.4:6443 \
    --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH>
```

**Save this command.**

You will execute it on the worker nodes.

---

# 🧱 WORKER NODE SETUP

Each worker Azure VM needs the Kubernetes prerequisites installed.

SSH into the worker:

```bash
ssh azureuser@<WORKER-PUBLIC-IP>
```

Verify its private IP:

```bash
hostname -I
```

Example:

```text
10.0.1.5
```

---

# Step 1: Clone the Repository

```bash
git clone https://github.com/tripathicle/kubernetes.git
```

Then:

```bash
cd kubernetes
```

---

# Step 2: Install Dependencies

Run the Docker/container-runtime setup:

```bash
chmod +x docker-install.sh
./docker-install.sh
```

Then install the Kubernetes packages using the worker setup script.

```bash
chmod +x worker-node-setup.sh
./worker-node-setup.sh
```

---

# Step 3: Join the Cluster

Take the `kubeadm join` command generated by the control plane.

Example:

```bash
sudo kubeadm join 10.0.1.4:6443 \
    --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH>
```

Notice:

```text
10.0.1.4:6443
```

is the **private IP address of the Azure control-plane VM**.

---

# 🔍 VERIFY CLUSTER

Go back to the control-plane VM.

Run:

```bash
kubectl get nodes
```

Expected:

```text
NAME            STATUS   ROLES           AGE
control-plane   Ready    control-plane   ...
worker-01       Ready    <none>          ...
worker-02       Ready    <none>          ...
```

Your actual VM hostnames may be different.

---

# 📦 Verify Kubernetes Pods

Run:

```bash
kubectl get pods -A
```

You should see Kubernetes system components running.

For example:

```text
NAMESPACE     NAME                                      STATUS
kube-system   calico-node-xxxxx                         Running
kube-system   coredns-xxxxx                             Running
kube-system   kube-apiserver-control-plane              Running
kube-system   kube-controller-manager-control-plane     Running
kube-system   kube-scheduler-control-plane              Running
```

---

# 🔎 Verify Node Details

```bash
kubectl get nodes -o wide
```

This is particularly useful on Azure because it lets you inspect node networking information.

Example:

```text
NAME          STATUS   ROLES           INTERNAL-IP
control-plane Ready    control-plane   10.0.1.4
worker-01     Ready    <none>          10.0.1.5
worker-02     Ready    <none>          10.0.1.6
```

The `INTERNAL-IP` should correspond to the Azure VM's private networking.

---

# 🧠 COMMAND EXPLANATION

## `kubeadm init`

```bash
sudo kubeadm init
```

Initializes the Kubernetes control plane.

---

## `kubeadm join`

```bash
sudo kubeadm join <CONTROL-PLANE-IP>:6443 ...
```

Joins a worker node to the Kubernetes cluster.

---

## `kubectl get nodes`

```bash
kubectl get nodes
```

Shows the nodes registered with the Kubernetes API Server.

---

## `kubectl get pods -A`

```bash
kubectl get pods -A
```

Shows pods across all Kubernetes namespaces.

---

## `kubectl get nodes -o wide`

```bash
kubectl get nodes -o wide
```

Shows additional node information including internal IP addresses.

---

# 🧠 What Happens Behind the Scenes?

When a worker executes:

```bash
kubeadm join 10.0.1.4:6443 ...
```

the basic communication flow is:

```text
Worker Azure VM
       |
       | HTTPS / TCP 6443
       v
Azure NSG
       |
       v
Control Plane Private IP
       |
       v
kube-apiserver
       |
       v
Kubernetes Cluster
```

After successful registration:

```text
                  Control Plane
                       |
                  kube-apiserver
                       |
              +--------+--------+
              |                 |
              v                 v
         Worker 01         Worker 02
              |                 |
           kubelet           kubelet
              |                 |
             Pods              Pods
```

This is the fundamental architecture you should understand before moving to managed Kubernetes services such as AKS.

---

# ⚠️ IMPORTANT NOTES

* Use **private IP addresses** for Kubernetes node-to-node communication.
* Keep all nodes in the same Azure VNet/subnet where practical for a lab.
* Ensure Azure NSG rules allow required Kubernetes traffic.
* Do not unnecessarily expose port `6443` to the public internet.
* Allow SSH (`22`) only from trusted source IPs whenever possible.
* Disable swap on all Kubernetes nodes.
* Ensure the container runtime is configured correctly.
* Ensure all nodes can resolve and communicate with each other.
* Install the same Kubernetes version across the cluster.
* Install the CNI before expecting nodes/pods to become fully operational.
* Save the `kubeadm join` command generated by the control plane.
* For production, use a highly available control plane rather than a single control-plane VM.

---

# 🏗️ Final Azure Architecture

```text
                       Azure
                         |
                    Resource Group
                         |
                        VNet
                         |
                    10.0.0.0/16
                         |
                    Subnet
                  10.0.1.0/24
                         |
          +--------------+--------------+
          |              |              |
          |              |              |
     Control Plane    Worker 01      Worker 02
       10.0.1.4       10.0.1.5       10.0.1.6
          |              |              |
          |              |              |
      kube-apiserver   kubelet        kubelet
      scheduler        kube-proxy     kube-proxy
      controller       Pods           Pods
      etcd
          |
          +---------------+
                          |
                    Kubernetes
                      Cluster
```

---

# 🎯 FINAL RESULT

After completing this guide, you will have:

* 1 Azure VM running the Kubernetes control plane
* N Azure VMs running Kubernetes worker nodes
* kubeadm-based Kubernetes cluster
* kubelet installed on every node
* kubectl configured on the control plane
* Container runtime configured on every node
* Calico CNI installed
* Azure VNet connectivity between nodes
* Azure NSG rules configured for Kubernetes communication

Final verification:

```bash
kubectl get nodes -o wide
```

and:

```bash
kubectl get pods -A
```

The target result is:

```text
Control Plane    Ready
Worker 01        Ready
Worker 02        Ready
...
```

---

# 🚀 Next Step

Once this cluster is working, the next important exercise is **not immediately deploying an application**.

First understand what actually happens when you run:

```bash
kubectl get nodes
```

and:

```bash
kubectl apply -f deployment.yaml
```

Trace the complete path:

```text
kubectl
   ↓
kubeconfig
   ↓
API Server
   ↓
Authentication
   ↓
Authorization
   ↓
Admission
   ↓
etcd
   ↓
Scheduler
   ↓
Controller Manager
   ↓
Kubelet
   ↓
Container Runtime
   ↓
Pod
```

That is where Kubernetes starts becoming an actual distributed-system architecture rather than just a collection of commands.

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
