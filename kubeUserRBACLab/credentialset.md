# Kubernetes User Credential & Context Setup

## Purpose

This script configures the Kubernetes client (`kubectl`) to authenticate as the user `tripathicle` using a client certificate and private key, then creates and activates a dedicated Kubernetes context.

---

## 1. Configure User Credentials

**Why:**
Registers the user's client certificate and private key in the kubeconfig file. Kubernetes will use these credentials to authenticate the user with the API server.

```bash
kubectl config set-credentials tripathicle \
  --client-certificate=/home/tripathicle/kubernetes/tripathicle.crt \
  --client-key=/home/tripathicle/kubernetes/tripathicle.key
```

---

## 2. Create User Context

**Why:**
Creates a kubeconfig context that associates the `tripathicle` user with the Kubernetes cluster and the `dev` namespace.

```bash
kubectl config set-context tripathicle-context \
  --cluster=kind-tripathicle-dev-cluster \
  --namespace=dev \
  --user=tripathicle
```

The context contains:

```text
Context
├── Cluster    → kind-tripathicle-dev-cluster
├── User       → tripathicle
└── Namespace  → dev
```

---

## 3. Activate the User Context

**Why:**
Makes `tripathicle-context` the current kubectl context. Future kubectl commands will use this user, cluster, and namespace by default.

```bash
kubectl config use-context tripathicle-context
```

---

## 4. Verify Available Contexts

**Why:**
Confirms that the `tripathicle-context` was successfully created and shows which context is currently active.

```bash
kubectl config get-contexts
```

---

## 5. Verify Current Context

**Why:**
Confirms that kubectl is currently operating with the `tripathicle-context`.

```bash
kubectl config current-context
```

Expected output:

```text
tripathicle-context
```

---

## 6. Test Authentication and RBAC

**Why:**
Tests the complete authentication and authorization flow without explicitly specifying `--as`. The identity comes from the active kubeconfig context.

```bash
kubectl get pods
```

The request flow is:

```text
kubectl
   │
   ▼
kubeconfig
   │
   ├── User: tripathicle
   ├── Client Certificate: tripathicle.crt
   └── Private Key: tripathicle.key
   │
   ▼
Kubernetes API Server
   │
   ▼
Authentication
   │
   ▼
User identified as "tripathicle"
   │
   ▼
RBAC Authorization
   │
   ▼
RoleBinding
   │
   ▼
Role
   │
   ▼
ALLOW / DENY
```

---

## Complete `credentialset.sh`

```bash
#!/bin/bash

# 1. Configure user credentials
kubectl config set-credentials tripathicle \
  --client-certificate=/home/tripathicle/kubernetes/tripathicle.crt \
  --client-key=/home/tripathicle/kubernetes/tripathicle.key

# 2. Create Kubernetes context
kubectl config set-context tripathicle-context \
  --cluster=kind-tripathicle-dev-cluster \
  --namespace=dev \
  --user=tripathicle

# 3. Activate the context
kubectl config use-context tripathicle-context

# 4. Verify available contexts
kubectl config get-contexts

# 5. Verify current context
kubectl config current-context

# 6. Test user access
kubectl get pods
```

### Important

This script **does not create the user certificate/key** and **does not create the RBAC Role/RoleBinding**.

It assumes these already exist:

```text
tripathicle.crt
tripathicle.key
       │
       ▼
kubeconfig credentials
       │
       ▼
tripathicle-context
       │
       ▼
kubectl
       │
       ▼
API Server
       │
       ▼
RBAC
```

So this script's responsibility is specifically:

**Certificate + Private Key → kubeconfig user → context → active kubectl identity → RBAC test**
