# Kubernetes Under the Hood: From CLI to Architecture

A comprehensive technical guide breaking down the internals of Kubernetes, request lifecycle execution, and local multi-node cluster bootstrapping using **Kind** (Kubernetes in Docker).

---

## 🛠️ Prerequisites & Setup

Ensure the following CLI tools are installed on your workstation before bootstrapping the cluster:

| Component | Minimum Version | Purpose |
| :--- | :--- | :--- |
| **Docker Engine** | `20.10+` | Containerization platform used as the virtual node driver. |
| **Kind** | `v0.20+` | Local Kubernetes cluster bootstrapper using Docker containers. |
| **kubectl** | `v1.28+` | Kubernetes command-line interface for cluster interaction. |

---

## 🚀 Quickstart: Bootstrapping a Multi-Node Cluster

Instead of a default single-node environment, we provision a multi-node cluster (1 Control Plane, 2 Worker Nodes) to mirror production architecture.

### 1. Create Cluster Configuration

Save the following manifest as `kind-config.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: dev-cluster
nodes:
  - role: control-plane
  - role: worker
  - role: worker


2. Provision the Cluster
Execute the creation command referencing your config file:

Bash
kind create cluster --config kind-config.yaml
3. Verify Cluster Nodes
Check the health and IP assignment of your provisioned nodes:

Bash
kubectl get nodes -o wide

Behind the Scenes: What Happens During kind create cluster?
When kind create cluster runs, it executes a 6-phase bootstrap sequence:

┌─────────────────────────────────────────────────────────────────────────────────┐
│                           KIND BOOTSTRAP WORKFLOW                               │
└─────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 1. Docker Image Retrieval                                                       │
│    Pulls 'kindest/node' image (contains containerd, systemd, kubelet, kubeadm). │
└─────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 2. Node Provisioning & CGroups Mounting                                         │
│    Spins up Docker containers acting as virtual Linux machines (--privileged).  │
└─────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 3. Network Bridge & Subnet Allocation                                           │
│    Creates isolated Docker bridge network and assigns static internal IPs.      │
└─────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 4. Control Plane Bootstrap (kubeadm init)                                       │
│    Generates PKI CA Certs ➔ Starts etcd ➔ Launches Core Control Plane Components.│
└─────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 5. Worker Node Registration (kubeadm join)                                      │
│    Worker kubelets fetch bootstrap tokens, issue CSRs, and join Control Plane.  │
└─────────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 6. CNI/CoreDNS Deployment & Kubeconfig Merge                                    │
│    Deploys Kindnet & CoreDNS ➔ Merges cluster credentials into ~/.kube/config.  │
└─────────────────────────────────────────────────────────────────────────────────┘

Phase Breakdown
Image Retrieval (kindest/node): Kind pulls a pre-packaged image containing systemd, containerd, kubelet, kubeadm, and cached control plane images.

Node Provisioning: Docker containers spin up with --privileged flags and mounted /sys/fs/cgroup mounts, allowing nested container runtime management inside the container node.

Control Plane Initialization (kubeadm init): Inside the control plane container, kubeadm generates TLS certificates, starts the etcd database backend, and executes static pods for kube-apiserver, kube-controller-manager, and kube-scheduler.

Worker Node Join (kubeadm join): Worker node containers execute kubeadm join via bootstrap tokens, passing CSR verification to register with the kube-apiserver.

Add-on Installation & Context Merge: Kind applies kindnet (CNI) and CoreDNS. It then reads /etc/kubernetes/admin.conf, maps the internal API server port to a host loopback port, and appends the entry to ~/.kube/config.

⚡ Complete Request Lifecycle: Running kubectl apply -f pod.yaml
When you submit a manifest to the cluster, the request undergoes processing across Client Side, Control Plane Pipeline, Scheduler, and Worker Node Execution.

[ Your Terminal ] 
       │
       ├─► 1. Resolves credentials & endpoint in ~/.kube/config
       ├─► 2. Validates client-side YAML against OpenAPI Schema
       └─► 3. Constructs HTTP POST payload ──► /api/v1/namespaces/default/pods
                               │
                               ▼
[ kube-apiserver Pipeline ]
       │
       ├─► Step 1: API Priority & Fairness (Throttling & Queueing)
       ├─► Step 2: Authentication (Validates bearer tokens / certs)
       ├─► Step 3: Authorization (RBAC permission evaluation)
       ├─► Step 4: Mutating Admission (Injects defaults & sidecars)
       ├─► Step 5: Schema Validation (Verifies mandatory payload fields)
       ├─► Step 6: Validating Admission (Enforces ResourceQuotas & Security Policies)
       └─► Step 7: Persistence (Atomic Protobuf write to etcd)
                               │
                               ▼
                     Returns "HTTP 201 Created" to kubectl
                               │
                               ▼ (Asynchronous Watch Stream)
[ kube-scheduler ]
       │
       ├─► Detects unassigned Pod (spec.nodeName: "")
       ├─► Filtering Phase (Predicates check CPU/RAM/Taints)
       ├─► Scoring Phase (Ranks viable candidate nodes)
       └─► Binding Phase (Writes spec.nodeName="worker-1" back to etcd)
                               │
                               ▼ (Asynchronous Watch Stream)
[ kubelet on Worker Node ]
       │
       ├─► Detects Pod assigned to its host
       ├─► Calls CRI (containerd) to pull container image
       ├─► Calls CNI (kindnet) to allocate Pod IP address
       ├─► Calls CSI (if volumes attached) to mount storage
       └─► Starts Container ➔ Updates status.phase = "Running"
🏗️ System Architecture Summary
+-----------------------------------------------------------------------------------+
|                                  HOST WORKSTATION                                 |
|                                                                                   |
|  ~/.kube/config (Points to 127.0.0.1:<Mapped-Port>)                              |
|  kubectl CLI ──────────────────────────────────────┐                              |
+----------------------------------------------------|------------------------------+
                                                     | (HTTPS / gRPC)
                                                     v
+-----------------------------------------------------------------------------------+
|                                DOCKER CONTAINER NETWORK                           |
|                                                                                   |
|  ┌─────────────────────────────────────────────────────────────────────────────┐  |
|  │ CONTROL-PLANE CONTAINER (dev-cluster-control-plane)                         │  |
|  │                                                                             │  |
|  │  [systemd] ──► [containerd]                                                 │  |
|  │                     │                                                       │  |
|  │                     ├──► kube-apiserver (Port 6443)                         │  |
|  │                     ├──► etcd (Key-Value Store)                             │  |
|  │                     ├──► kube-scheduler                                     │  |
|  │                     └──► kube-controller-manager                            │  |
|  └─────────────────────────────────────────────────────────────────────────────┘  |
|                                         │                                         |
|                          (Isolated Kind Bridge Network)                           |
|                                         │                                         |
|  ┌──────────────────────────────────────┴──────────────────────────────────┐  |
|  │ WORKER NODE CONTAINER (dev-cluster-worker)                             │  |
|  │                                                                        │  |
|  │  [systemd] ──► [containerd] ──► [kubelet] ──► Application Pods          │  |
|  └────────────────────────────────────────────────────────────────────────┘  |
+-----------------------------------------------------------------------------------+
🧹 Cleanup
To tear down the cluster and release Docker resources:

Bash
kind delete cluster --name dev-cluster