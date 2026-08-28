# kubectx and kubens — Kubernetes Context & Namespace Management

## 1. Overview

`kubectx` and `kubens` are command-line utilities that make it easier to work with Kubernetes contexts and namespaces.

```text
kubectx → Manage Kubernetes contexts
kubens  → Manage Kubernetes namespaces
```

They work with the Kubernetes configuration file:

```text
~/.kube/config
```

---

# 2. kubectx

## What is kubectx?

`kubectx` is used to **list and switch between Kubernetes contexts**.

A Kubernetes context defines:

```text
Context
├── Cluster
├── User
└── Namespace
```

---

## List Available Contexts

```bash
kubectx
```

Example:

```text
kind-tripathicle-dev-cluster
tripathicle-context
```

---

## Switch to Another Context

```bash
kubectx kind-tripathicle-dev-cluster
```

This changes the active Kubernetes context.

Verify:

```bash
kubectl config current-context
```

---

## Switch Back to the Previous Context

```bash
kubectx -
```

This switches between the current and previously used context.

Example:

```text
tripathicle-context
        ↓
kubectx -
        ↓
kind-tripathicle-dev-cluster
        ↓
kubectx -
        ↓
tripathicle-context
```

---

## Show kubectx Help

```bash
kubectx --help
```

or:

```bash
kubectx -h
```

---

## Show kubectx Version

```bash
kubectx --version
```

or:

```bash
kubectx -V
```

---

# 3. kubens

## What is kubens?

`kubens` is used to **list and switch between Kubernetes namespaces** in the current context.

---

## List Namespaces

```bash
kubens
```

Example:

```text
default
dev
kube-node-lease
kube-public
kube-system
```

---

## Show Current Namespace

```bash
kubens -c
```

Example:

```text
dev
```

---

## Switch Namespace

To switch to the `default` namespace:

```bash
kubens default
```

To switch back to the `dev` namespace:

```bash
kubens dev
```

---

## Switch to Previous Namespace

```bash
kubens -
```

Example:

```text
dev
  ↓
kubens -
  ↓
default
  ↓
kubens -
  ↓
dev
```

---

## Show kubens Help

```bash
kubens --help
```

or:

```bash
kubens -h
```

---

## Show kubens Version

```bash
kubens --version
```

or:

```bash
kubens -V
```

---

# 4. kubectx vs kubens

| Tool      | Purpose                       | Example                       |
| --------- | ----------------------------- | ----------------------------- |
| `kubectx` | Switch Kubernetes context     | `kubectx tripathicle-context` |
| `kubens`  | Switch Kubernetes namespace   | `kubens dev`                  |
| `kubectl` | Execute Kubernetes operations | `kubectl get pods`            |

Simple mental model:

```text
kubectx
   ↓
Which Kubernetes context?

kubens
   ↓
Which namespace?

kubectl
   ↓
What Kubernetes operation?
```

---

# 5. Our Current Kubernetes Setup

The current context is:

```text
tripathicle-context
```

It is configured with:

```text
Cluster    → kind-tripathicle-dev-cluster
User       → tripathicle
Namespace  → dev
```

Conceptually:

```text
tripathicle-context
        │
        ├── Cluster
        │      └── kind-tripathicle-dev-cluster
        │
        ├── User
        │      └── tripathicle
        │
        └── Namespace
               └── dev
```

---

# 6. How kubectx and kubens Work Together

Suppose the current configuration is:

```text
Context = tripathicle-context
User = tripathicle
Namespace = dev
```

Running:

```bash
kubectx kind-tripathicle-dev-cluster
```

changes the **context**.

Running:

```bash
kubens default
```

changes the **namespace associated with the current context**.

They control different parts of the Kubernetes configuration.

---

# 7. Kubernetes RBAC Example

Our `tripathicle` user has permissions within the `dev` namespace.

Therefore:

```bash
kubens dev
kubectl get pods
```

can successfully return pods from the `dev` namespace.

Example:

```text
NAME
nginx-dev
tripathicle-in-dev-nginx
```

However:

```bash
kubectl get nodes
```

returns:

```text
Error from server (Forbidden):
nodes is forbidden:
User "tripathicle" cannot list resource "nodes"
at the cluster scope
```

This happens because Nodes are **cluster-scoped resources**, while the user's permissions are namespace-scoped.

---

# 8. RBAC Flow

When running:

```bash
kubectl get pods
```

the request follows this flow:

```text
kubectl
   ↓
~/.kube/config
   ↓
Current Context
   ↓
tripathicle-context
   ↓
User = tripathicle
   ↓
Namespace = dev
   ↓
Kubernetes API Server
   ↓
Authentication
   ↓
User identified as tripathicle
   ↓
RBAC Authorization
   ↓
Can tripathicle list pods in dev?
   ↓
YES
   ↓
Pods returned
```

For Nodes:

```text
kubectl get nodes
        ↓
User = tripathicle
        ↓
Resource = nodes
        ↓
Scope = cluster
        ↓
RBAC Authorization
        ↓
No cluster-level permission
        ↓
403 Forbidden
```

---

# 9. Important Difference: Authentication vs Authorization

## Authentication

Authentication answers:

```text
Who are you?
```

In our setup:

```text
User = tripathicle
```

The client certificate and private key configured in kubeconfig are used for authentication.

---

## Authorization

Authorization answers:

```text
What are you allowed to do?
```

For example:

```text
tripathicle
   │
   ├── List pods in dev       → ALLOWED
   ├── Get pods in dev        → ALLOWED
   └── List nodes cluster-wide → DENIED
```

Therefore, a `Forbidden` response does **not** necessarily mean authentication failed.

It can mean:

```text
Authentication → SUCCESS
Authorization  → DENIED
```

---

# 10. Kubeconfig Location

The default kubeconfig file is:

```text
~/.kube/config
```

For our user:

```text
/home/tripathicle/.kube/config
```

Verify:

```bash
ls ~/.kube/config
```

You can explicitly tell kubectl to use this file:

```bash
kubectl get pods --kubeconfig ~/.kube/config
```

This is equivalent to the normal command when `~/.kube/config` is the default configuration:

```bash
kubectl get pods
```

---

# 11. Common Path Mistake

Incorrect:

```bash
kubectl get nodes --kubeconfig ~/.kube.config
```

This produces:

```text
stat /home/tripathicle/.kube.config:
no such file or directory
```

The correct path is:

```bash
kubectl get nodes --kubeconfig ~/.kube/config
```

Remember:

```text
~/.kube/
    └── config
```

`config` is a file inside the `.kube` directory.

---

# 12. Useful Commands

## Check Current Context

```bash
kubectl config current-context
```

## List Contexts

```bash
kubectl config get-contexts
```

## List Contexts with kubectx

```bash
kubectx
```

## Switch Context

```bash
kubectx <context-name>
```

## List Namespaces

```bash
kubens
```

## Show Current Namespace

```bash
kubens -c
```

## Switch Namespace

```bash
kubens <namespace-name>
```

## Get Pods

```bash
kubectl get pods
```

## Get Pods in a Specific Namespace

```bash
kubectl get pods -n <namespace>
```

---

# 13. Quick Reference

```text
kubectx
    ↓
List contexts

kubectx <context>
    ↓
Switch context

kubectx -
    ↓
Switch to previous context


kubens
    ↓
List namespaces

kubens <namespace>
    ↓
Switch namespace

kubens -
    ↓
Switch to previous namespace

kubens -c
    ↓
Show current namespace


kubectl config current-context
    ↓
Show current context

kubectl config get-contexts
    ↓
Show all contexts
```

---

# 14. Final Mental Model

Think of Kubernetes access as:

```text
                    ~/.kube/config
                           │
                           ▼
                    Current Context
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
           Cluster        User       Namespace
              │            │            │
              ▼            ▼            ▼
       kind-tripathicle   tripathicle    dev
              │
              └──────────────┬───────────┘
                             ▼
                       API Server
                             │
                             ▼
                      Authentication
                             │
                             ▼
                    RBAC Authorization
                             │
                    ┌────────┴────────┐
                    ▼                 ▼
                  ALLOW             DENY
                    │                 │
                    ▼                 ▼
                 Resource          Forbidden
```

### Remember

```text
kubectx = Context
kubens  = Namespace
kubectl = Kubernetes operation
kubeconfig = Configuration used by kubectl
RBAC = Determines what the authenticated user can do
```
