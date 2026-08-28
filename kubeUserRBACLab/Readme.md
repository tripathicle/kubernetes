# Kubernetes RBAC Lab — Step by Step

## Step 1: Check the Cluster

```bash
kubectl get namespaces
```

We had:

```text
default
dev
kube-node-lease
kube-public
kube-system
local-path-storage
prod
test
```

---

## Step 2: Create a Folder for the User

```bash
mkdir -p ~/k8s-user
cd ~/k8s-user
```

---

## Step 3: Create the User's Private Key

```bash
openssl genrsa -out tripathicle.key 2048
```

Check:

```bash
ls
```

You should see:

```text
tripathicle.key
```

---

## Step 4: Create the CSR

```bash
openssl req -new \
  -key tripathicle.key \
  -out tripathicle.csr \
  -subj "/CN=tripathicle"
```

Check:

```bash
ls
```

You should now have:

```text
tripathicle.key
tripathicle.csr
```

---

## Step 5: Find the Kind Control Plane Container

```bash
docker ps
```

We used the control-plane container:

```text
tripathicle-dev-cluster-control-plane
```

---

## Step 6: Copy the CSR Into the Control Plane

```bash
docker cp tripathicle.csr \
  tripathicle-dev-cluster-control-plane:/tmp/tripathicle.csr
```

---

## Step 7: Sign the CSR With the Kubernetes CA

```bash
docker exec tripathicle-dev-cluster-control-plane \
  openssl x509 -req \
  -in /tmp/tripathicle.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial \
  -out /tmp/tripathicle.crt \
  -days 365
```

---

## Step 8: Copy the Signed Certificate Back

```bash
docker cp \
  tripathicle-dev-cluster-control-plane:/tmp/tripathicle.crt \
  ./tripathicle.crt
```

Check:

```bash
ls
```

You should have:

```text
tripathicle.key
tripathicle.csr
tripathicle.crt
```

---

# Step 9: Add the User to kubeconfig

```bash
kubectl config set-credentials tripathicle \
  --client-certificate=$HOME/k8s-user/tripathicle.crt \
  --client-key=$HOME/k8s-user/tripathicle.key
```

---

# Step 10: Create the User Context

First check the cluster name:

```bash
kubectl config get-contexts
```

Our cluster was:

```text
kind-tripathicle-dev-cluster
```

Create the context:

```bash
kubectl config set-context tripathicle-context \
  --cluster=kind-tripathicle-dev-cluster \
  --user=tripathicle
```

Check:

```bash
kubectl config get-contexts
```

---

# Step 11: Create the DEV Role

Create the file:

```bash
nano developer-role.yaml
```

Put this inside:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role

metadata:
  name: developer
  namespace: dev

rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - delete
```

Save the file.

Apply it:

```bash
kubectl apply -f developer-role.yaml
```

Check:

```bash
kubectl get role -n dev
```

---

# Step 12: Give the DEV Role to tripathicle

Create:

```bash
nano developer-rolebinding.yaml
```

Put:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding

metadata:
  name: developer-binding
  namespace: dev

subjects:
  - kind: User
    name: tripathicle
    apiGroup: rbac.authorization.k8s.io

roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

Save.

Apply:

```bash
kubectl apply -f developer-rolebinding.yaml
```

Check:

```bash
kubectl get rolebinding -n dev
```

---

# Step 13: Create the TEST Role

Create:

```bash
nano tester-role.yaml
```

Put:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role

metadata:
  name: tester
  namespace: test

rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs:
      - get
      - list
      - watch
      - create
      - delete
```

Apply:

```bash
kubectl apply -f tester-role.yaml
```

Check:

```bash
kubectl get role -n test
```

---

# Step 14: Give the TEST Role to tripathicle

Create:

```bash
nano tester-rolebinding.yaml
```

Put:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding

metadata:
  name: tester-binding
  namespace: test

subjects:
  - kind: User
    name: tripathicle
    apiGroup: rbac.authorization.k8s.io

roleRef:
  kind: Role
  name: tester
  apiGroup: rbac.authorization.k8s.io
```

Apply:

```bash
kubectl apply -f tester-rolebinding.yaml
```

Check:

```bash
kubectl get rolebinding -n test
```

---

# Step 15: Create the PROD Role

Create:

```bash
nano prod-viewer-role.yaml
```

Put:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role

metadata:
  name: prod-viewer
  namespace: prod

rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs:
      - get
      - list
      - watch
```

Apply:

```bash
kubectl apply -f prod-viewer-role.yaml
```

Check:

```bash
kubectl get role -n prod
```

---

# Step 16: Give the PROD Role to tripathicle

Create:

```bash
nano prod-viewer-rolebinding.yaml
```

Put:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding

metadata:
  name: prod-viewer-binding
  namespace: prod

subjects:
  - kind: User
    name: tripathicle
    apiGroup: rbac.authorization.k8s.io

roleRef:
  kind: Role
  name: prod-viewer
  apiGroup: rbac.authorization.k8s.io
```

Apply:

```bash
kubectl apply -f prod-viewer-rolebinding.yaml
```

Check:

```bash
kubectl get rolebinding -n prod
```

---

# Step 17: Check DEV Permissions

```bash
kubectl auth can-i get pods \
  --as=tripathicle \
  -n dev
```

```bash
kubectl auth can-i create pods \
  --as=tripathicle \
  -n dev
```

```bash
kubectl auth can-i update pods \
  --as=tripathicle \
  -n dev
```

```bash
kubectl auth can-i delete pods \
  --as=tripathicle \
  -n dev
```

All should return:

```text
yes
```

---

# Step 18: Check TEST Permissions

```bash
kubectl auth can-i get pods \
  --as=tripathicle \
  -n test
```

```bash
kubectl auth can-i create pods \
  --as=tripathicle \
  -n test
```

```bash
kubectl auth can-i delete pods \
  --as=tripathicle \
  -n test
```

These should return:

```text
yes
```

Check update:

```bash
kubectl auth can-i update pods \
  --as=tripathicle \
  -n test
```

Expected:

```text
no
```

---

# Step 19: Check PROD Permissions

Read:

```bash
kubectl auth can-i get pods \
  --as=tripathicle \
  -n prod
```

Expected:

```text
yes
```

Create:

```bash
kubectl auth can-i create pods \
  --as=tripathicle \
  -n prod
```

Expected:

```text
no
```

Update:

```bash
kubectl auth can-i update pods \
  --as=tripathicle \
  -n prod
```

Expected:

```text
no
```

Delete:

```bash
kubectl auth can-i delete pods \
  --as=tripathicle \
  -n prod
```

Expected:

```text
no
```

---

# Step 20: Create a Pod in DEV

```bash
kubectl run nginx-dev \
  --image=nginx \
  --namespace=dev
```

Check:

```bash
kubectl get pods -n dev
```

You should see:

```text
nginx-dev
```

---

# Step 21: Check All Pods

```bash
kubectl get pods -A
```

This shows Pods from:

```text
default
dev
test
prod
kube-system
```

---

# Step 22: Check All Roles

```bash
kubectl get roles -A
```

---

# Step 23: Check All RoleBindings

```bash
kubectl get rolebindings -A
```

---

# Final Setup

We ended up with **one user**:

```text
tripathicle
```

with **different permissions in each environment**:

```text
DEV
└── developer
    ├── get
    ├── list
    ├── watch
    ├── create
    ├── update
    └── delete

TEST
└── tester
    ├── get
    ├── list
    ├── watch
    ├── create
    └── delete

PROD
└── prod-viewer
    ├── get
    ├── list
    └── watch
```

So the final flow is:

```text
tripathicle
     │
     ├── DEV  → developer Role  → Full CRUD
     │
     ├── TEST → tester Role     → Limited access
     │
     └── PROD → viewer Role     → Read only
```
