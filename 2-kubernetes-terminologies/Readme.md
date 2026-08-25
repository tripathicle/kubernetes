# Kubernetes Terminologies

Kubernetes becomes much easier once you stop seeing it as hundreds of commands and start seeing it as a system of **objects working together**.

This guide builds the vocabulary you need to understand Kubernetes from the ground up.

The goal is simple:

> **When you see a Kubernetes term, you should immediately know what it is, why it exists, where it lives, and how it interacts with the other pieces.**

---

# 1. The Big Picture

Before learning individual terms, understand this:

Imagine you are running an online shopping application.

```text
                    USER
                     |
                     v
              Online Store
                     |
              +------+------+
              |             |
              v             v
          Frontend       Backend
                             |
                             v
                         Database
```

Now imagine you have thousands of users.

You don't want to manually:

* start servers
* restart crashed applications
* distribute traffic
* replace failed machines
* deploy new versions
* scale applications
* manage configuration
* manage networking

This is where Kubernetes comes in.

Kubernetes is a system that continuously works toward:

> **"Make the actual system look like the system you asked for."**

For example:

```text
You say:

"I want 3 copies of my application."

Kubernetes observes:

Current state = 2 copies

Kubernetes acts:

Create 1 more

Result:

Desired state = 3
Actual state = 3
```

That idea explains a huge portion of Kubernetes.

---

# 2. Kubernetes Cluster

A **cluster** is the complete Kubernetes environment.

It contains:

```text
Kubernetes Cluster
│
├── Control Plane
│
└── Worker Nodes
    ├── Worker Node 1
    ├── Worker Node 2
    └── Worker Node 3
```

Think of a cluster as:

> **The entire Kubernetes system responsible for running your applications.**

For example:

```bash
kubectl get nodes
```

might show:

```text
NAME           STATUS   ROLES
control-plane  Ready    control-plane
worker-01      Ready    <none>
worker-02      Ready    <none>
```

These nodes together form your cluster.

---

# 3. Node

A **Node** is a machine that participates in the Kubernetes cluster.

It can be:

* a physical server
* a virtual machine
* a cloud VM

For example, on Azure:

```text
Azure
 |
 +-- VM: control-plane
 |
 +-- VM: worker-01
 |
 +-- VM: worker-02
```

Each VM can become a Kubernetes node.

Check nodes:

```bash
kubectl get nodes
```

Example:

```text
NAME       STATUS   ROLES
worker-01  Ready    <none>
worker-02  Ready    <none>
```

### Simple mental model

```text
Node = Machine
```

A node provides the compute resources required to run Kubernetes workloads.

---

# 4. Control Plane

The **Control Plane** is the part of Kubernetes that makes decisions about the cluster.

It answers questions such as:

* What workloads should exist?
* Where should they run?
* Are enough replicas running?
* Did a node fail?
* Has the desired state changed?
* What should happen when a deployment is updated?

Think:

```text
Control Plane
      |
      | decides
      v
Worker Nodes
      |
      | execute
      v
Applications
```

The control plane contains several important components.

---

# 5. kube-apiserver

The **kube-apiserver** is the front door of Kubernetes.

Almost everything talks through the Kubernetes API.

When you execute:

```bash
kubectl get pods
```

you are effectively saying:

```text
kubectl
   |
   v
kube-apiserver
   |
   v
Kubernetes API
```

The API Server:

* receives requests
* authenticates users
* authorizes actions
* validates objects
* processes API requests
* communicates with other Kubernetes components

### Simple mental model

```text
kube-apiserver = Front Door of Kubernetes
```

You don't normally walk directly into etcd, the scheduler, or controllers.

You interact with the API.

---

# 6. kubectl

`kubectl` is the command-line client used to communicate with Kubernetes.

Example:

```bash
kubectl get pods
```

```bash
kubectl create deployment nginx --image=nginx
```

```bash
kubectl delete pod nginx
```

Important:

> `kubectl` is **not Kubernetes itself**.

It is a client.

Think:

```text
kubectl = Your remote control
```

The remote control doesn't operate the TV by itself.

It sends commands to the TV.

Similarly:

```text
kubectl
   |
   | API request
   v
kube-apiserver
```

---

# 7. kubeconfig

How does `kubectl` know:

* which cluster to contact?
* which API Server?
* which credentials to use?
* which context is active?

Through the **kubeconfig** file.

Usually:

```text
~/.kube/config
```

It contains information about:

```text
Cluster
User/Credentials
Context
```

Example conceptually:

```yaml
clusters:
- name: dev-cluster
  cluster:
    server: https://10.0.1.4:6443

users:
- name: admin
  ...

contexts:
- name: dev
  cluster: dev-cluster
  user: admin
```

Then:

```bash
kubectl config current-context
```

tells you which context you're currently using.

---

# 8. Context

A **context** tells kubectl:

> "Which cluster and which identity should I use?"

Imagine you have:

```text
Development Cluster
Production Cluster
Testing Cluster
```

You don't want to accidentally deploy to production.

Contexts help you switch between them.

```bash
kubectl config get-contexts
```

Switch:

```bash
kubectl config use-context production
```

### Mental model

```text
Context =
Which cluster?
+
Which credentials?
+
Which namespace?
```

---

# 9. etcd

`etcd` is Kubernetes' distributed key-value store.

It stores the cluster's important state.

For example:

```text
Which Pods should exist?
Which Deployments exist?
Which Services exist?
Which Nodes exist?
Which Secrets exist?
Which ConfigMaps exist?
```

Think of etcd as:

> **The memory/database of the Kubernetes control plane.**

Conceptually:

```text
API Server
    |
    v
  etcd
    |
    v
Cluster State
```

Important distinction:

> etcd does not run your application containers.

It stores Kubernetes state.

---

# 10. Desired State

This is one of the most important Kubernetes concepts.

Suppose you write:

```yaml
replicas: 3
```

You are telling Kubernetes:

> "I want three copies."

That is the **desired state**.

Example:

```text
Desired State:
3 Pods

Actual State:
1 Pod
```

Kubernetes sees the difference:

```text
Desired = 3
Actual  = 1

Difference = 2
```

It takes action.

Eventually:

```text
Desired = 3
Actual  = 3
```

This continuous reconciliation is a fundamental Kubernetes behavior.

---

# 11. Reconciliation

Kubernetes continuously compares:

```text
Desired State
      |
      v
Actual State
      |
      v
Difference?
      |
      v
Take corrective action
```

Example:

```text
You request:

3 replicas

Kubernetes:
Pod 1
Pod 2
Pod 3
```

Then Pod 2 crashes.

Actual state:

```text
Pod 1
Pod 3
```

Kubernetes notices:

```text
Desired = 3
Actual  = 2
```

It creates another Pod.

Result:

```text
Pod 1
Pod 3
Pod 4
```

You didn't manually restart anything.

---

# 12. Controller

A **Controller** watches Kubernetes objects and tries to make actual state match desired state.

Example:

```text
Deployment Controller
```

You say:

```text
replicas = 3
```

The controller keeps checking:

```text
Do I have 3 replicas?
```

If not:

```text
Create/delete/update resources
```

### Mental model

```text
Controller = Reconciliation loop
```

Conceptually:

```text
Observe
   ↓
Compare
   ↓
Decide
   ↓
Act
   ↓
Observe again
```

---

# 13. Controller Manager

The **kube-controller-manager** runs various Kubernetes controllers.

Examples include controllers responsible for:

* Nodes
* ReplicaSets
* Jobs
* Endpoints
* Namespaces
* Services and other cluster resources

Think:

```text
Controller Manager
       |
       +-- Node Controller
       +-- ReplicaSet Controller
       +-- Job Controller
       +-- Namespace Controller
       +-- ...
```

---

# 14. Scheduler

The **kube-scheduler** decides:

> **Which worker node should run this Pod?**

Suppose:

```text
Pod A needs to run
```

Available nodes:

```text
Worker 1 → CPU available
Worker 2 → CPU almost full
Worker 3 → Memory available
```

The scheduler evaluates the constraints and selects an appropriate node.

```text
Pod
 |
 v
Scheduler
 |
 +---- Worker 1
 +---- Worker 2
 +---- Worker 3
       ^
       |
    Selected
```

Important:

> The scheduler decides **where** a Pod should run. It does not itself run the container.

---

# 15. kubelet

The **kubelet** runs on every worker node.

Its job is to make sure the Pods assigned to that node are actually running.

Think:

```text
Control Plane
      |
      | "Run this Pod here"
      v
   kubelet
      |
      v
Container Runtime
      |
      v
Container
```

The kubelet:

* watches assigned Pods
* communicates with the API Server
* works with the container runtime
* reports node and Pod status
* ensures containers are running according to Pod specifications

### Mental model

```text
kubelet = Node-level worker/agent
```

---

# 16. Container Runtime

The container runtime is responsible for actually running containers.

Modern Kubernetes uses a CRI-compatible runtime.

Common runtimes include:

* containerd
* CRI-O

Conceptually:

```text
kubelet
   |
   | CRI
   v
Container Runtime
   |
   v
Container
```

Important distinction:

```text
Kubernetes ≠ Container Runtime
```

Kubernetes orchestrates.

The runtime actually manages containers.

---

# 17. Pod

A **Pod** is the smallest deployable unit in Kubernetes.

A Pod contains one or more containers.

Most commonly:

```text
Pod
 |
 +-- Container
```

But a Pod can contain multiple tightly coupled containers:

```text
Pod
 |
 +-- Application Container
 |
 +-- Sidecar Container
```

Containers inside the same Pod share:

* network namespace
* IP address
* localhost
* volumes configured for the Pod

---

# 18. Why Does Kubernetes Use Pods?

Suppose you have:

```text
Application Container
```

Why not simply tell Kubernetes:

```text
Run this container
```

Kubernetes needs a higher-level abstraction around containers.

That abstraction is the Pod.

```text
Container
    ↓
Pod
    ↓
Kubernetes workload
```

The Pod describes how containers should run together.

---

# 19. Pod IP

Every Pod normally receives an IP address from the cluster's Pod network.

Example:

```text
Pod A → 10.244.1.10
Pod B → 10.244.2.15
```

But don't normally build applications around fixed Pod IPs.

Why?

Because Pods are replaceable.

Pod:

```text
10.244.1.10
```

dies.

Kubernetes creates:

```text
10.244.1.25
```

The IP changed.

This is why Kubernetes provides **Services**.

---

# 20. Deployment

A **Deployment** manages stateless application Pods.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
```

You are saying:

```text
I want:
3 nginx Pods
```

The Deployment does not directly create Pods.

The relationship is:

```text
Deployment
     |
     v
ReplicaSet
     |
     v
Pods
     |
     v
Containers
```

---

# 21. ReplicaSet

A **ReplicaSet** ensures that a specified number of identical Pods exist.

Example:

```text
replicas: 3
```

The ReplicaSet tries to maintain:

```text
Pod 1
Pod 2
Pod 3
```

If one disappears:

```text
Pod 1
Pod 3
```

ReplicaSet creates another.

```text
Pod 1
Pod 3
Pod 4
```

### Why do we usually create Deployments instead?

Because Deployments provide higher-level application management, including:

* rolling updates
* rollbacks
* ReplicaSet management
* version transitions

Usually:

```text
Deployment
   ↓
ReplicaSet
   ↓
Pods
```

---

# 22. StatefulSet

A **StatefulSet** is designed for workloads that need stable identity or persistent storage.

Examples:

* databases
* distributed databases
* Kafka-like systems
* applications requiring stable network identity

A Deployment might create:

```text
nginx-abc
nginx-def
nginx-ghi
```

A StatefulSet creates predictable identities:

```text
database-0
database-1
database-2
```

That identity matters.

---

# 23. DaemonSet

A **DaemonSet** ensures that a Pod runs on selected nodes, commonly one Pod per node.

Example:

```text
Worker 1 → Monitoring Agent
Worker 2 → Monitoring Agent
Worker 3 → Monitoring Agent
```

Typical uses:

* logging agents
* monitoring agents
* node-level security agents
* networking components

Mental model:

```text
DaemonSet = "Run this Pod on every applicable node."
```

---

# 24. Job

A **Job** is used for work that should eventually finish.

Example:

```text
Process 10,000 records
```

The Job runs Pods until the required work successfully completes.

```text
Job
 |
 +-- Pod
 |
 +-- Pod
 |
 +-- Completed
```

Unlike a Deployment, a Job is not designed to keep an application running forever.

---

# 25. CronJob

A **CronJob** runs Jobs on a schedule.

Example:

```text
Every night at 2 AM:
Backup database
```

Conceptually:

```text
CronJob
   |
   | schedule
   v
 Job
   |
   v
 Pod
   |
   v
Container
```

Example schedule:

```text
0 2 * * *
```

means approximately:

```text
Every day at 2:00 AM
```

---

# 26. Service

A Service provides a stable way to reach a group of Pods.

Remember:

```text
Pod IPs can change.
```

So instead of:

```text
Client → Pod IP
```

we use:

```text
Client
   |
   v
Service
   |
   +---- Pod
   +---- Pod
   +---- Pod
```

The Service provides:

* stable virtual IP
* stable DNS name
* traffic distribution to selected Pods

---

# 27. Labels

Labels are key-value pairs attached to Kubernetes objects.

Example:

```yaml
labels:
  app: payment
  environment: production
```

Think of labels as **tags**.

A Pod might have:

```text
app=payment
environment=production
```

Kubernetes can then select it.

---

# 28. Selector

A selector tells Kubernetes:

> "Find objects having these labels."

Example:

```yaml
selector:
  app: payment
```

If three Pods have:

```text
app=payment
```

the selector matches all three.

This is how a Service can know which Pods should receive traffic.

---

# 29. Service + Labels

This relationship is extremely important.

Suppose:

```text
Pod 1 → app=web
Pod 2 → app=web
Pod 3 → app=api
```

Service:

```yaml
selector:
  app: web
```

Result:

```text
             Service
                |
        selector: app=web
                |
          +-----+-----+
          |           |
        Pod 1       Pod 2
        app=web     app=web

Pod 3 is ignored.
```

---

# 30. Service Types

Kubernetes commonly provides:

```text
ClusterIP
NodePort
LoadBalancer
ExternalName
```

---

# 31. ClusterIP

`ClusterIP` is the default Service type.

It exposes the application inside the cluster.

```text
Pod A
 |
 v
Service
 |
 v
Pod B
```

It is useful for internal communication.

Example:

```text
frontend
   |
   v
backend-service
   |
   v
backend Pods
```

---

# 32. NodePort

NodePort exposes a Service through a port on each node.

Example:

```text
NodePort: 30080
```

Traffic:

```text
Client
  |
  | :30080
  v
Node
  |
  v
Service
  |
  v
Pod
```

NodePort normally uses:

```text
30000-32767
```

---

# 33. LoadBalancer

`LoadBalancer` requests an external load-balancing mechanism from the underlying environment.

In a cloud environment:

```text
Internet
   |
   v
Cloud Load Balancer
   |
   v
Kubernetes Service
   |
   +---- Pod
   +---- Pod
   +---- Pod
```

In Azure, this can integrate with Azure load-balancing infrastructure depending on the Kubernetes environment.

---

# 34. Ingress

Ingress provides HTTP/HTTPS routing into Kubernetes applications.

Instead of exposing every application independently:

```text
Internet
  |
  +---- Service A
  |
  +---- Service B
  |
  +---- Service C
```

you can route through an ingress layer:

```text
                 Internet
                    |
                    v
                  Ingress
                /    |    \
               /     |     \
              v      v      v
           Service A B      C
```

Example:

```text
shop.example.com/products
        |
        v
Products Service

shop.example.com/orders
        |
        v
Orders Service
```

Ingress is primarily about HTTP/HTTPS routing.

---

# 35. Ingress Controller

An Ingress object describes routing rules.

But something needs to actually implement those rules.

That component is the **Ingress Controller**.

Examples include controllers based on:

* NGINX
* Traefik
* HAProxy
* cloud-provider integrations

Mental model:

```text
Ingress = Rules

Ingress Controller = Component that implements those rules
```

---

# 36. Namespace

A Namespace provides logical separation inside a Kubernetes cluster.

Imagine one cluster hosting:

```text
Development
Testing
Production
```

You could organize:

```text
namespace: dev
namespace: test
namespace: prod
```

Then:

```bash
kubectl get pods -n dev
```

shows Pods in the `dev` namespace.

Namespaces are useful for:

* organization
* access control
* resource management
* isolation boundaries

Important:

> A Namespace is not the same thing as a separate cluster.

---

# 37. ConfigMap

A ConfigMap stores non-sensitive configuration.

Example:

```text
DATABASE_HOST=database
LOG_LEVEL=info
ENVIRONMENT=production
```

Instead of hardcoding these into the image, the application can receive them from a ConfigMap.

```text
ConfigMap
    |
    v
Pod
    |
    v
Application
```

---

# 38. Secret

A Secret is intended for sensitive configuration.

Examples:

```text
Database password
API token
TLS material
Credentials
```

Conceptually:

```text
Secret
   |
   v
Pod
   |
   v
Application
```

Important:

> Kubernetes Secrets are not automatically equivalent to a fully secured enterprise secrets-management system. Their storage and encryption configuration matter.

For production environments, integrate Kubernetes with an appropriate external secret-management solution where required.

---

# 39. Volume

Containers are generally ephemeral.

If a container disappears, data stored only inside its writable container filesystem may disappear with it.

A Volume provides storage associated with a Pod.

```text
Pod
 |
 +-- Container
 |
 +-- Volume
```

---

# 40. PersistentVolume

A **PersistentVolume (PV)** represents persistent storage available to the cluster.

Think:

```text
PersistentVolume
      |
      v
Actual persistent storage
```

It can represent storage backed by infrastructure such as cloud disks or network storage.

---

# 41. PersistentVolumeClaim

A **PersistentVolumeClaim (PVC)** is a request for storage.

Instead of asking:

> "Give me this exact disk."

you say:

> "I need 20 GiB of persistent storage with these requirements."

Conceptually:

```text
Application
    |
    v
PVC
    |
    v
PV
    |
    v
Storage
```

---

# 42. StorageClass

A StorageClass defines how storage can be dynamically provisioned.

For example:

```text
Application
    |
    v
PVC
    |
    v
StorageClass
    |
    v
Dynamic Provisioning
    |
    v
Persistent Storage
```

This is especially important in cloud environments.

---

# 43. Resource Requests

A container can tell Kubernetes:

```text
"I need at least this much CPU and memory."
```

Example:

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "256Mi"
```

This influences scheduling.

If a Pod requests:

```text
500Mi memory
```

the scheduler looks for a node with sufficient allocatable capacity.

---

# 44. Resource Limits

A limit defines the maximum resource usage allowed for a container.

Example:

```yaml
resources:
  limits:
    cpu: "1"
    memory: "512Mi"
```

Conceptually:

```text
Request = What I need

Limit = Maximum I'm allowed to use
```

---

# 45. CPU Units

Kubernetes CPU can be expressed in millicores.

```text
1000m = 1 CPU
500m  = 0.5 CPU
250m  = 0.25 CPU
```

Example:

```yaml
cpu: "500m"
```

means:

```text
Half of one CPU core
```

---

# 46. Memory Units

Memory can be specified using units such as:

```text
Mi
Gi
```

Examples:

```text
256Mi
512Mi
1Gi
2Gi
```

---

# 47. Namespace vs Node

These are completely different.

### Namespace

Logical grouping:

```text
Cluster
 |
 +-- dev
 +-- test
 +-- prod
```

### Node

Actual compute machine:

```text
Cluster
 |
 +-- VM 1
 +-- VM 2
 +-- VM 3
```

One namespace can have Pods running across many nodes.

---

# 48. Container vs Pod

These are also different.

```text
Pod
 |
 +-- Container
```

A container is the application runtime unit.

A Pod is the Kubernetes unit that wraps one or more containers.

Think:

```text
Container = Application process environment

Pod = Kubernetes execution boundary around containers
```

---

# 49. Deployment vs Pod

Do not think:

```text
Deployment = Pod
```

Think:

```text
Deployment
    |
    v
ReplicaSet
    |
    v
Pods
    |
    v
Containers
```

The Deployment manages the desired state of the application.

---

# 50. Service vs Deployment

They solve different problems.

### Deployment

Answers:

> How many application instances should exist?

### Service

Answers:

> How should clients reach those application instances?

Together:

```text
Deployment
    |
    v
Pods
    |
    v
Service
    |
    v
Clients
```

---

# 51. API Object

Most things you create in Kubernetes are API objects.

Examples:

```text
Pod
Deployment
Service
ConfigMap
Secret
Namespace
Job
StatefulSet
DaemonSet
```

You can think of them as structured records describing desired state.

---

# 52. Manifest

A Kubernetes manifest is usually a YAML file describing an object.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: nginx

spec:
  replicas: 3
```

This says:

```text
Object type = Deployment
Name = nginx
Desired replicas = 3
```

---

# 53. `apiVersion`

Every Kubernetes object usually specifies an API version.

Example:

```yaml
apiVersion: apps/v1
```

It tells Kubernetes which API group/version the object belongs to.

---

# 54. `kind`

`kind` tells Kubernetes what object you're describing.

Examples:

```yaml
kind: Pod
```

```yaml
kind: Deployment
```

```yaml
kind: Service
```

```yaml
kind: ConfigMap
```

---

# 55. `metadata`

Metadata identifies and describes the object.

Example:

```yaml
metadata:
  name: nginx
  labels:
    app: nginx
```

---

# 56. `spec`

`spec` describes the desired configuration.

Example:

```yaml
spec:
  replicas: 3
```

Think:

```text
metadata = What is this?

spec = What do I want?
```

---

# 57. `status`

Kubernetes objects also have status information.

Conceptually:

```text
spec   = Desired state

status = Observed/current state
```

Example:

```text
spec:
  replicas: 3

status:
  readyReplicas: 3
```

This distinction is central to Kubernetes.

---

# 58. Annotation

Annotations store additional metadata that is not normally used as a selector.

Example:

```yaml
annotations:
  description: "Payment service"
```

Controllers and tools can use annotations to store configuration or metadata.

### Labels vs Annotations

```text
Label       → Used for identification/selection

Annotation  → Extra metadata/configuration
```

---

# 59. Replica

A replica is another running copy of a Pod.

If:

```yaml
replicas: 3
```

you want:

```text
Pod 1
Pod 2
Pod 3
```

Replicas improve:

* availability
* capacity
* resilience

---

# 60. Rolling Update

Suppose your application currently runs:

```text
Version 1
Version 1
Version 1
```

You deploy:

```text
Version 2
```

Kubernetes can gradually replace the old Pods:

```text
V1 V1 V1

↓

V2 V1 V1

↓

V2 V2 V1

↓

V2 V2 V2
```

This is a rolling update.

---

# 61. Rollback

Suppose Version 2 has a bug.

You can roll back to a previous Deployment revision.

```bash
kubectl rollout undo deployment/nginx
```

Conceptually:

```text
Version 1
    ↓
Version 2
    ↓
Problem
    ↓
Rollback
    ↓
Version 1
```

---

# 62. Readiness Probe

A readiness probe answers:

> **"Is this application ready to receive traffic?"**

Example:

```text
Application starts
       |
       v
Not ready
       |
       v
Database connection established
       |
       v
Ready
       |
       v
Receive traffic
```

If a Pod is not ready, Kubernetes can remove it from Service endpoints.

---

# 63. Liveness Probe

A liveness probe answers:

> **"Is this application still alive?"**

If the application becomes unhealthy according to the probe, Kubernetes may restart the container.

Example:

```text
Container
   |
   v
Liveness check
   |
   +---- Healthy → Continue
   |
   +---- Unhealthy → Restart
```

---

# 64. Startup Probe

A startup probe helps with applications that take a long time to start.

Example:

```text
Large Java application

Startup:
90 seconds
```

Without appropriate startup handling, liveness checks could incorrectly restart the application during initialization.

---

# 65. Readiness vs Liveness

Remember this:

```text
Readiness:
"Should I send traffic to you?"

Liveness:
"Are you still alive?"

Startup:
"Have you finished starting?"
```

---

# 66. Taints

A taint tells Kubernetes:

> "Don't schedule Pods here unless they tolerate this condition."

Example:

```text
Control Plane Node
       |
       | taint
       v
Regular application Pods
       |
       X
     Blocked
```

Taints are useful for controlling which workloads can run on which nodes.

---

# 67. Tolerations

A toleration allows a Pod to be scheduled onto a node with a matching taint.

Relationship:

```text
Node
 |
 +-- Taint
       |
       | requires matching
       v
     Pod
       |
 +-- Toleration
```

---

# 68. Node Affinity

Node affinity allows you to express:

> "Prefer or require this Pod to run on nodes with specific properties."

Example:

```text
Pod
 |
 | required
 v
Node with:
disk=ssd
```

Useful for workload placement.

---

# 69. Service Discovery

Applications inside Kubernetes often need to find each other.

Instead of hardcoding:

```text
10.244.1.25
```

an application can communicate using a Service DNS name.

Example:

```text
backend-service
```

Kubernetes DNS resolves the Service.

Conceptually:

```text
frontend
   |
   | http://backend-service
   v
Kubernetes DNS
   |
   v
Service
   |
   v
Backend Pods
```

---

# 70. CoreDNS

**CoreDNS** provides DNS-based service discovery in Kubernetes clusters.

For example:

```text
backend-service
```

can resolve to the Service's virtual IP.

This allows applications to use stable names instead of changing Pod IP addresses.

---

# 71. kube-proxy

`kube-proxy` is a node-level component involved in implementing Service networking.

Conceptually:

```text
Client
  |
  v
Service IP
  |
  v
kube-proxy / networking rules
  |
  +---- Pod
  +---- Pod
```

The exact packet-processing implementation can depend on the Kubernetes networking environment.

---

# 72. CNI

CNI stands for:

**Container Network Interface**

It defines how container networking is configured.

A Kubernetes cluster needs a networking implementation so Pods can communicate.

Examples include:

* Calico
* Cilium
* Flannel
* cloud-provider networking solutions

Think:

```text
Kubernetes
    |
    v
CNI
    |
    v
Pod Networking
```

---

# 73. Calico

Calico is a Kubernetes networking and network-policy solution.

It can provide:

* Pod networking
* network policies
* routing/networking capabilities

In a kubeadm lab:

```text
kubeadm
   |
   v
Kubernetes Cluster
   |
   v
Calico
   |
   v
Pod Network
```

---

# 74. NetworkPolicy

A NetworkPolicy controls which network traffic is allowed to or from selected Pods.

Without policies, communication might be broad depending on the cluster networking setup.

With a NetworkPolicy:

```text
Frontend
   |
   | ALLOW
   v
Backend

Backend
   |
   X
Database
```

You can express network security rules at the Kubernetes level.

---

# 75. RBAC

RBAC stands for:

**Role-Based Access Control**

It controls:

> Who can perform which actions on which Kubernetes resources?

Example:

```text
Developer
   |
   v
Role
   |
   +-- get pods
   +-- list pods
   +-- create deployments
```

But perhaps:

```text
delete namespaces
```

is not allowed.

---

# 76. Role

A Role defines permissions within a namespace.

Example concept:

```text
Role
 |
 +-- get pods
 +-- list pods
 +-- watch pods
```

It answers:

> What actions are allowed?

---

# 77. ClusterRole

A ClusterRole can define permissions that apply at cluster scope or can be bound within namespaces depending on how it is used.

Examples:

```text
Read nodes
Read namespaces
Read pods
```

---

# 78. RoleBinding

A RoleBinding connects:

```text
User/Group/ServiceAccount
        +
Role
```

Example:

```text
developer
    |
    v
RoleBinding
    |
    v
pod-reader
```

---

# 79. ServiceAccount

A ServiceAccount provides an identity for workloads running inside Kubernetes.

Example:

```text
Pod
 |
 | identity
 v
ServiceAccount
 |
 v
Kubernetes API
```

This allows applications to authenticate to the Kubernetes API when configured to do so.

---

# 80. Authentication vs Authorization

These are different.

### Authentication

> "Who are you?"

```text
User → Identity
```

### Authorization

> "What are you allowed to do?"

```text
Identity → Permissions
```

Example:

```text
Who?
  ↓
Shubham

Can Shubham delete Pods?
  ↓
Authorization
  ↓
Yes / No
```

---

# 81. Admission Controller

After authentication and authorization, Kubernetes can apply admission controls to API requests.

Conceptually:

```text
Request
   ↓
Authentication
   ↓
Authorization
   ↓
Admission
   ↓
Validation / Mutation
   ↓
Persisted State
```

Admission controllers can:

* validate requests
* mutate objects
* enforce policies

---

# 82. ClusterIP vs Pod IP

A Pod IP belongs to a Pod.

A ClusterIP belongs to a Service.

Example:

```text
Pod:
10.244.1.10

Pod:
10.244.1.11

Service:
10.96.20.10
```

The Service provides a stable virtual endpoint for the changing Pods.

---

# 83. EndpointSlice

A Service needs to know which backend endpoints are currently available.

Kubernetes uses **EndpointSlices** to track groups of network endpoints associated with Services.

Conceptually:

```text
Service
   |
   v
EndpointSlice
   |
   +---- Pod IP
   +---- Pod IP
   +---- Pod IP
```

This is important for scalable Service endpoint management.

---

# 84. NodePort vs LoadBalancer vs Ingress

A useful comparison:

```text
NodePort
   ↓
Expose through node port

LoadBalancer
   ↓
Request external load balancing

Ingress
   ↓
HTTP/HTTPS routing based on host/path
```

Example:

```text
Internet
   |
   v
Load Balancer
   |
   v
Ingress Controller
   |
   +------ /products ------> Products Service
   |
   +------ /orders --------> Orders Service
```

---

# 85. Horizontal Pod Autoscaler

HPA stands for:

**Horizontal Pod Autoscaler**

It automatically adjusts the number of Pod replicas based on metrics.

Example:

```text
Normal traffic

3 Pods
```

Traffic increases:

```text
CPU ↑
Traffic ↑

3 Pods
   ↓
5 Pods
```

Traffic decreases:

```text
5 Pods
   ↓
3 Pods
```

Horizontal scaling means:

> **More or fewer Pods.**

---

# 86. Vertical Pod Autoscaler

VPA adjusts resource requests/limits for Pods based on observed usage, subject to its configuration and operating mode.

Horizontal:

```text
3 Pods → 6 Pods
```

Vertical:

```text
CPU:
250m → 500m

Memory:
256Mi → 512Mi
```

---

# 87. Cluster Autoscaler

Cluster Autoscaler operates at the **node** level.

If Pods cannot be scheduled because there isn't enough node capacity:

```text
Pods waiting
     |
     v
Cluster Autoscaler
     |
     v
Add Node
```

If nodes are no longer needed:

```text
Underutilized Nodes
        |
        v
Remove Node
```

In cloud environments, this can interact with cloud infrastructure to create or remove VMs.

---

# 88. Horizontal vs Vertical vs Cluster Scaling

Remember:

```text
Horizontal Pod Autoscaler
    ↓
More/Fewer Pods

Vertical Pod Autoscaler
    ↓
More/Fewer resources per Pod

Cluster Autoscaler
    ↓
More/Fewer Nodes
```

---

# 89. `kubectl apply`

A very common command:

```bash
kubectl apply -f deployment.yaml
```

It means:

> "Take this configuration and make the cluster converge toward it."

The conceptual flow:

```text
kubectl
   |
   v
API Server
   |
   v
Authentication
   |
   v
Authorization
   |
   v
Admission
   |
   v
State stored
   |
   v
Controllers
   |
   v
Scheduler
   |
   v
Kubelet
   |
   v
Container Runtime
   |
   v
Pod
```

---

# 90. Declarative vs Imperative

Kubernetes supports both styles.

### Imperative

You tell Kubernetes **how to perform an action**.

```bash
kubectl create deployment nginx --image=nginx
```

### Declarative

You describe **what the final state should be**.

```yaml
replicas: 3
image: nginx
```

Then:

```bash
kubectl apply -f deployment.yaml
```

The declarative approach is especially powerful for:

* GitOps
* Infrastructure automation
* version control
* reproducibility

---

# 91. GitOps

GitOps treats Git as a source of truth for desired application state.

Conceptually:

```text
Git Repository
      |
      | Desired State
      v
GitOps Controller
      |
      v
Kubernetes
      |
      v
Actual State
```

If someone changes the cluster manually:

```text
Git = desired state
Cluster = actual state
```

The GitOps controller can detect and reconcile differences.

---

# 92. Helm

Helm is a package manager for Kubernetes.

Instead of maintaining many YAML files manually:

```text
deployment.yaml
service.yaml
configmap.yaml
ingress.yaml
```

Helm packages Kubernetes resources into reusable charts.

```text
Helm Chart
   |
   +-- Deployment
   +-- Service
   +-- ConfigMap
   +-- Ingress
```

---

# 93. Helm Chart

A Helm Chart is a package containing Kubernetes templates and metadata.

Typical structure:

```text
my-chart/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

---

# 94. Helm Values

`values.yaml` provides configurable values for a Helm chart.

Example:

```yaml
replicaCount: 3

image:
  repository: nginx
  tag: "latest"
```

The same chart can then be configured differently for:

```text
Development
Testing
Production
```

---

# 95. Container Image

A container image is a packaged application environment.

Example:

```text
nginx:latest
```

An image contains things such as:

* application
* libraries
* filesystem
* configuration required to run the application

A container is a running instance of an image.

```text
Image
  |
  | run
  v
Container
```

---

# 96. Container Registry

A registry stores container images.

Examples:

* Docker Hub
* Azure Container Registry
* Amazon ECR
* Google Artifact Registry

Flow:

```text
Developer
   |
   v
docker build
   |
   v
Container Image
   |
   v
Container Registry
   |
   v
Kubernetes
   |
   v
Pod
```

---

# 97. Image Pull

When Kubernetes needs to start a container:

```text
Pod specification
       |
       v
Image:
nginx:latest
       |
       v
Container Runtime
       |
       v
Registry
       |
       v
Download Image
       |
       v
Run Container
```

---

# 98. `imagePullPolicy`

This controls when Kubernetes attempts to pull an image.

Common values include:

```text
Always
IfNotPresent
Never
```

For production workloads, use controlled immutable image versions/digests rather than relying on mutable tags such as `latest`.

---

# 99. Init Container

An Init Container runs before the main application containers in a Pod.

Example:

```text
Pod
 |
 +-- Init Container
 |       |
 |       +-- Prepare configuration
 |
 +-- Application Container
```

Useful for:

* initialization
* waiting for prerequisites
* preparing files
* setup tasks

---

# 100. Sidecar Container

A sidecar is an additional container running alongside the main application container in the same Pod.

Example:

```text
Pod
 |
 +-- Application
 |
 +-- Logging Sidecar
```

Because containers in the same Pod share the Pod network namespace, they can communicate through `localhost`.

---

# 101. Pod Lifecycle

A Pod commonly moves through states such as:

```text
Pending
   ↓
Running
   ↓
Succeeded / Failed
```

For a normal long-running application:

```text
Pending
   ↓
Container created
   ↓
Running
```

If it terminates successfully:

```text
Succeeded
```

If it fails:

```text
Failed
```

---

# 102. Pod Restart Policy

Pods have restart policies such as:

```text
Always
OnFailure
Never
```

The appropriate behavior depends on the workload type.

For example:

```text
Deployment → long-running application
Job        → finite work
```

---

# 103. CrashLoopBackOff

You may eventually see:

```text
CrashLoopBackOff
```

It means Kubernetes is repeatedly trying to start a container that keeps failing, with increasing delays between restarts.

Example:

```text
Container starts
      ↓
Application crashes
      ↓
Restart
      ↓
Application crashes
      ↓
Restart
      ↓
Increasing backoff
```

Useful debugging:

```bash
kubectl describe pod <pod-name>
```

and:

```bash
kubectl logs <pod-name>
```

---

# 104. Pending Pod

If a Pod is:

```text
Pending
```

it means it has not reached the Running state.

Possible causes include:

* insufficient CPU
* insufficient memory
* scheduling constraints
* taints
* missing volumes
* image or infrastructure problems

Start with:

```bash
kubectl describe pod <pod-name>
```

---

# 105. ImagePullBackOff

This commonly means Kubernetes is having trouble pulling the container image.

Possible causes:

```text
Wrong image name
Wrong image tag
Private registry authentication
Registry unavailable
Network problem
```

Check:

```bash
kubectl describe pod <pod-name>
```

---

# 106. Node `Ready`

When:

```bash
kubectl get nodes
```

shows:

```text
STATUS
Ready
```

the node is considered healthy enough for Kubernetes scheduling according to its current conditions.

If:

```text
NotReady
```

investigate:

```bash
kubectl describe node <node-name>
```

---

# 107. Control Plane vs Worker Node

A useful mental model:

```text
CONTROL PLANE
=============
Makes decisions

API Server
Scheduler
Controller Manager
etcd


WORKER NODE
===========
Runs workloads

kubelet
Container Runtime
kube-proxy
Pods
```

In a small learning cluster, some components may run together depending on the installation.

---

# 108. The Complete Kubernetes Picture

Now put everything together:

```text
                         USER
                          |
                          v
                       kubectl
                          |
                          v
                  +----------------+
                  |  API SERVER    |
                  +-------+--------+
                          |
              +-----------+-----------+
              |           |           |
              v           v           v
             etcd     Scheduler   Controllers
              |                       |
              |                       |
              +-----------+-----------+
                          |
                    Desired State
                          |
                          v
                    Worker Nodes
                          |
             +------------+------------+
             |                         |
             v                         v
          kubelet                  kubelet
             |                         |
             v                         v
      Container Runtime        Container Runtime
             |                         |
             v                         v
           Pods                      Pods
             |                         |
             +------------+------------+
                          |
                       Services
                          |
                       Ingress
                          |
                       Clients
```

---

# 109. One Real Example

Suppose you run:

```bash
kubectl apply -f deployment.yaml
```

Your YAML says:

```yaml
replicas: 3
```

What happens?

### Step 1 — kubectl

`kubectl` reads your kubeconfig.

```text
kubectl
   |
   v
Which cluster?
Which credentials?
```

### Step 2 — API Server

The request reaches the API Server.

```text
kubectl
   |
   v
API Server
```

### Step 3 — Authentication

Kubernetes determines:

```text
Who is making this request?
```

### Step 4 — Authorization

Kubernetes asks:

```text
Is this identity allowed to create/update this Deployment?
```

### Step 5 — Admission

Admission controls validate or modify the request where configured.

### Step 6 — State

The object is persisted in the cluster state.

```text
API Server
    |
    v
etcd
```

### Step 7 — Deployment Controller

The Deployment controller notices the desired state.

```text
Desired:
3 replicas
```

It creates/manages a ReplicaSet.

### Step 8 — ReplicaSet

ReplicaSet creates the required Pods.

```text
Pod
Pod
Pod
```

### Step 9 — Scheduler

The scheduler finds suitable nodes.

```text
Pod 1 → Worker 1
Pod 2 → Worker 2
Pod 3 → Worker 1
```

### Step 10 — kubelet

The kubelet on each selected node sees the assigned Pod.

### Step 11 — Container Runtime

The runtime pulls the image if needed and starts the container.

### Step 12 — Application

Your application is now running.

The entire flow:

```text
kubectl
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
Deployment Controller
  ↓
ReplicaSet
  ↓
Scheduler
  ↓
kubelet
  ↓
Container Runtime
  ↓
Container
  ↓
Application
```

---

# 110. The Most Important Relationships

If you remember only a few relationships, remember these:

```text
Cluster
  |
  +-- Control Plane
  |
  +-- Nodes
```

```text
Deployment
    |
    v
ReplicaSet
    |
    v
Pod
    |
    v
Container
```

```text
Service
    |
    v
Pod
```

```text
Ingress
    |
    v
Service
    |
    v
Pod
```

```text
PVC
 |
 v
PV
 |
 v
Storage
```

```text
ConfigMap / Secret
        |
        v
       Pod
```

```text
Node
 |
 +-- kubelet
 +-- Container Runtime
 +-- kube-proxy
 +-- Pods
```

```text
Control Plane
 |
 +-- API Server
 +-- Scheduler
 +-- Controller Manager
 +-- etcd
```

---

# 111. The Kubernetes Vocabulary Cheat Sheet

| Term               | Simple Meaning                          |
| ------------------ | --------------------------------------- |
| Cluster            | Complete Kubernetes environment         |
| Node               | Machine participating in the cluster    |
| Control Plane      | Makes cluster decisions                 |
| Worker Node        | Runs application workloads              |
| kube-apiserver     | Kubernetes API front door               |
| kubectl            | CLI used to communicate with Kubernetes |
| kubeconfig         | Configuration used by kubectl           |
| Context            | Selects cluster/identity/namespace      |
| etcd               | Stores Kubernetes state                 |
| Scheduler          | Chooses a node for a Pod                |
| Controller         | Reconciles desired and actual state     |
| Controller Manager | Runs Kubernetes controllers             |
| kubelet            | Node-level agent                        |
| Container Runtime  | Runs containers                         |
| Pod                | Smallest deployable Kubernetes unit     |
| Deployment         | Manages stateless application replicas  |
| ReplicaSet         | Maintains desired Pod count             |
| StatefulSet        | Manages stateful workloads              |
| DaemonSet          | Runs Pods on selected/all nodes         |
| Job                | Runs finite work                        |
| CronJob            | Runs Jobs on a schedule                 |
| Service            | Stable network endpoint for Pods        |
| ClusterIP          | Internal Service                        |
| NodePort           | Exposes Service through node port       |
| LoadBalancer       | Integrates with external load balancing |
| Ingress            | HTTP/HTTPS routing rules                |
| Ingress Controller | Implements Ingress behavior             |
| Namespace          | Logical grouping                        |
| Label              | Key-value tag used for selection        |
| Selector           | Finds resources using labels            |
| ConfigMap          | Non-sensitive configuration             |
| Secret             | Sensitive configuration data            |
| Volume             | Storage attached to a Pod               |
| PV                 | Persistent storage resource             |
| PVC                | Request for persistent storage          |
| StorageClass       | Defines dynamic storage provisioning    |
| CNI                | Container networking interface          |
| Calico             | Networking/policy solution              |
| NetworkPolicy      | Controls Pod network traffic            |
| RBAC               | Access control system                   |
| Role               | Namespace-scoped permissions            |
| ClusterRole        | Cluster-scoped/reusable permissions     |
| RoleBinding        | Connects identity to Role               |
| ServiceAccount     | Identity for workloads                  |
| HPA                | Scales Pod count                        |
| VPA                | Adjusts Pod resources                   |
| Cluster Autoscaler | Scales nodes                            |
| Helm               | Kubernetes package manager              |
| Manifest           | YAML/JSON resource definition           |
| Desired State      | What you want                           |
| Actual State       | What currently exists                   |
| Reconciliation     | Process of correcting differences       |

---

# 112. The Five Questions to Ask About Any Kubernetes Object

Whenever you encounter a new Kubernetes resource, ask:

### 1. What is it?

Example:

```text
Deployment
```

### 2. Why does it exist?

```text
To manage application replicas and updates.
```

### 3. What does it manage?

```text
ReplicaSets → Pods
```

### 4. Who interacts with it?

```text
API Server
Controllers
Scheduler
kubelet
```

### 5. What happens behind the scenes?

Don't stop at:

```bash
kubectl apply
```

Trace:

```text
kubectl
 ↓
API Server
 ↓
Authentication
 ↓
Authorization
 ↓
Admission
 ↓
State
 ↓
Controller
 ↓
Scheduler
 ↓
kubelet
 ↓
Runtime
 ↓
Container
```

That mental model will take you much further than memorizing commands.

---

# 113. Final Mental Model

Kubernetes can be understood as a continuous loop:

```text
             YOU
              |
              | Desired State
              v
         Kubernetes API
              |
              v
             etcd
              |
              v
        Controllers
              |
              v
          Scheduler
              |
              v
         Worker Nodes
              |
              v
            kubelet
              |
              v
      Container Runtime
              |
              v
           Workload
              |
              v
        Actual State
              |
              |
              +------------------+
                                 |
                                 v
                         Kubernetes observes
                                 |
                                 v
                         Compare with desired
                                 |
                                 v
                            Reconcile
                                 |
                                 +-----> repeat
```

The central idea is:

```text
              DESIRED STATE
                    |
                    v
              Kubernetes
                    |
                    v
              ACTUAL STATE
                    |
              Are they equal?
                /       \
              YES        NO
               |          |
               |          v
               |       Take action
               |          |
               +----------+
                    |
                  Repeat
```

Once this clicks, Kubernetes stops looking like a collection of unrelated terms.

You start seeing the system:

```text
API
 ↓
State
 ↓
Controllers
 ↓
Scheduling
 ↓
Nodes
 ↓
Pods
 ↓
Containers
 ↓
Networking
 ↓
Storage
 ↓
Applications
```

**That is the foundation on which everything else in Kubernetes is built.**
