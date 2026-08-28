# Kubernetes User Creation, Authentication, and RBAC

## A Plain-English Guide for Technical and Non-Technical Readers

> **Goal:** Understand how a person or automation is identified by Kubernetes and how Kubernetes decides what that identity is allowed to do.

---

# 1. The Big Picture

Imagine a company office.

Before a person can enter a restricted area, two questions must be answered:

1. **Who are you?**
2. **What are you allowed to do?**

Kubernetes works in much the same way.

| Real-world example | Kubernetes equivalent |
|---|---|
| Employee ID | User identity |
| Security check | Authentication |
| Access policy | Authorization |
| Access card | Certificate or token |
| Permission rules | RBAC Role |
| Assigning access to a person | RoleBinding |

The complete flow looks like this:

```text
User or Application
        |
        v
Authentication
"Who are you?"
        |
        v
Authorization
"What are you allowed to do?"
        |
        v
Kubernetes Resource
Pods, Deployments, Services, etc.
```

---

# 2. Authentication vs. Authorization

These two terms are often confused.

## Authentication = Who are you?

Authentication verifies identity.

Examples:

- Client certificate
- Service account token
- OIDC identity
- Cloud identity provider

In our lab, we used a **client certificate**.

```text
Certificate says:

"I am tripathicle."
```

Kubernetes verifies the certificate and identifies the request as coming from:

```text
User: tripathicle
Group: developers
```

## Authorization = What are you allowed to do?

Once Kubernetes knows who you are, it checks permissions.

For example:

```text
tripathicle
      |
      +--> View Pods       YES
      |
      +--> List Pods       YES
      |
      +--> Watch Pods      YES
      |
      +--> Delete Pods     NO
      |
      +--> Create Pods     NO
```

This decision is controlled by **RBAC**.

---

# 3. What Does "Creating a User" Mean in Kubernetes?

This is an important point.

Unlike many traditional systems, Kubernetes does not normally create a human user with a command like:

```bash
kubectl create user tripathicle
```

Instead, Kubernetes receives an identity from an authentication mechanism.

In our example, we created a certificate-based identity.

```text
Private Key
    |
    v
Certificate Signing Request
    |
    v
Kubernetes CA signs the request
    |
    v
Client Certificate
    |
    v
Kubernetes recognizes the identity
```

The username comes from the certificate's **Common Name (CN)**.

We used:

```text
CN = tripathicle
```

Therefore, Kubernetes recognizes the user as:

```text
tripathicle
```

We also used:

```text
O = developers
```

This represents a group named:

```text
developers
```

Important: being part of a group does **not automatically grant permissions**. RBAC must still grant those permissions.

---

# 4. Step 1: Create a Private Key

Command:

```bash
openssl genrsa -out tripathicle.key 2048
```

This creates:

```text
tripathicle.key
```

The private key is the secret part of the user's cryptographic identity.

Think of it as the user's highly sensitive digital proof of identity.

```text
tripathicle.key
       |
       +--> Must remain private
       +--> Should never be shared
       +--> Used to prove possession of the identity
```

Verify it:

```bash
ls -l tripathicle.key
```

---

# 5. Step 2: Create a Certificate Signing Request

Next, we create a CSR.

Command:

```bash
openssl req -new \
  -key tripathicle.key \
  -out tripathicle.csr \
  -subj "/CN=tripathicle/O=developers"
```

This creates:

```text
tripathicle.csr
```

A CSR is essentially a request that says:

> "Here is my public identity information. Please sign and issue a certificate for it."

The important fields are:

```text
CN = tripathicle
O  = developers
```

Meaning:

```text
Username = tripathicle
Group    = developers
```

At this point, we have:

```text
tripathicle.key  --> Private key
tripathicle.csr  --> Certificate request
```

---

# 6. Step 3: Convert the CSR to Base64

The Kubernetes CSR API expects the certificate request in Base64 format.

Command:

```bash
cat tripathicle.csr | base64 | tr -d '\n'
```

This produces one long string.

That output is placed directly after:

```yaml
request:
```

---

# 7. Step 4: Submit the CSR to Kubernetes

Create a file named:

```text
csr.yaml
```

Example:

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest

metadata:
  name: tripathicle

spec:
  request: PASTE_BASE64_OUTPUT_HERE
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
```

Apply it:

```bash
kubectl apply -f csr.yaml
```

Check the status:

```bash
kubectl get csr tripathicle
```

Initially, the request will usually be:

```text
Pending
```

That means:

> Kubernetes has received the certificate request, but it has not yet been approved and signed.

---

# 8. Step 5: Approve the CSR

Approve the request:

```bash
kubectl certificate approve tripathicle
```

Then check again:

```bash
kubectl get csr tripathicle
```

The expected state is:

```text
Approved,Issued
```

The flow is:

```text
User creates CSR
       |
       v
CSR submitted to Kubernetes
       |
       v
Pending
       |
       v
Administrator approves
       |
       v
Kubernetes CA signs the certificate
       |
       v
Approved,Issued
```

---

# 9. Step 6: Extract the Signed Certificate

Run:

```bash
kubectl get csr tripathicle \
  -o jsonpath='{.status.certificate}' \
  | base64 --decode > tripathicle.crt
```

Now verify:

```bash
ls -l tripathicle.*
```

You should have:

```text
tripathicle.key
tripathicle.csr
tripathicle.crt
```

Their roles are:

| File | Purpose |
|---|---|
| `tripathicle.key` | Private cryptographic key |
| `tripathicle.csr` | Certificate signing request |
| `tripathicle.crt` | Signed client certificate |

At this stage, Kubernetes can authenticate the identity.

However, authentication does not mean permission.

This is the difference:

```text
Authentication:
"Yes, you are tripathicle."

Authorization:
"Now let's check what tripathicle is allowed to do."
```

---

# 10. RBAC: Role-Based Access Control

RBAC answers the question:

> "What is this user allowed to do?"

The main objects we used are:

```text
Role
RoleBinding
```

## Role

A Role defines permissions.

Think of it as a job description or access policy.

For example:

```text
This identity can:

- Get Pods
- List Pods
- Watch Pods
```

## RoleBinding

A RoleBinding connects the permissions to an identity.

Think of it as:

> "Assign this access policy to this person."

The relationship is:

```text
Role
  |
  | defines permissions
  v
pod-reader

RoleBinding
  |
  | assigns permissions
  v
tripathicle
```

---

# 11. Creating the Role

Create a file named:

```text
role.yaml
```

Add:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role

metadata:
  name: pod-reader
  namespace: default

rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs:
      - get
      - list
      - watch
```

Apply it:

```bash
kubectl apply -f role.yaml
```

Verify:

```bash
kubectl get roles
```

---

# 12. Understanding the Role Line by Line

## API Version

```yaml
apiVersion: rbac.authorization.k8s.io/v1
```

This tells Kubernetes:

> "This object uses the RBAC API."

## Object Type

```yaml
kind: Role
```

This tells Kubernetes:

> "Create a Role containing permissions."

## Name

```yaml
name: pod-reader
```

This is simply the name of our permission set.

## Namespace

```yaml
namespace: default
```

This Role applies only inside the `default` namespace.

It does not automatically grant access to Pods in other namespaces.

For example:

```text
default namespace
    |
    +--> nginx        ALLOWED

kube-system namespace
    |
    +--> coredns      NOT covered by this Role
```

## API Group

```yaml
apiGroups: [""]
```

Pods belong to Kubernetes' core API group, represented by an empty string.

## Resource

```yaml
resources: ["pods"]
```

The permissions apply to Pods.

## Verbs

```yaml
verbs:
  - get
  - list
  - watch
```

Meaning:

| Verb | Plain-English meaning |
|---|---|
| `get` | View one specific Pod |
| `list` | View a list of Pods |
| `watch` | Continuously observe changes |

The following are not allowed because we did not grant them:

```text
create
update
patch
delete
```

---

# 13. Creating the RoleBinding

A Role by itself does not give anyone access.

We must assign it to the user.

Create:

```text
rolebinding.yaml
```

Add:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding

metadata:
  name: tripathicle-pod-reader
  namespace: default

subjects:
  - kind: User
    name: tripathicle
    apiGroup: rbac.authorization.k8s.io

roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Apply it:

```bash
kubectl apply -f rolebinding.yaml
```

Verify:

```bash
kubectl get rolebindings
```

---

# 14. Understanding RoleBinding

The most important section is:

```yaml
subjects:
  - kind: User
    name: tripathicle
```

This identifies the person receiving the permissions.

The `roleRef` section says:

```yaml
roleRef:
  kind: Role
  name: pod-reader
```

Meaning:

> Assign the permissions defined in `pod-reader` to `tripathicle`.

The complete relationship is:

```text
Certificate
     |
     v
Identity: tripathicle
     |
     v
RoleBinding
     |
     v
Role: pod-reader
     |
     +--> get Pods
     +--> list Pods
     +--> watch Pods
```

---

# 15. Can Role and RoleBinding Be in the Same YAML File?

Yes.

One YAML file can contain multiple Kubernetes objects.

Use:

```yaml
---
```

as a separator.

Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role

metadata:
  name: pod-reader
  namespace: default

rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding

metadata:
  name: tripathicle-pod-reader
  namespace: default

subjects:
  - kind: User
    name: tripathicle
    apiGroup: rbac.authorization.k8s.io

roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Then apply both objects with one command:

```bash
kubectl apply -f rbac.yaml
```

The separator:

```yaml
---
```

means:

> "The first YAML document ends here. The next Kubernetes object begins here."

---

# 16. The Complete Story

Here is the entire process from beginning to end.

```text
STEP 1
Create Private Key
tripathicle.key
        |
        v
STEP 2
Create Certificate Signing Request
tripathicle.csr
        |
        | CN = tripathicle
        | O = developers
        v
STEP 3
Submit CSR to Kubernetes
        |
        v
Pending
        |
        v
STEP 4
Administrator approves CSR
        |
        v
Kubernetes CA signs certificate
        |
        v
STEP 5
tripathicle.crt
        |
        v
AUTHENTICATION
"Who are you?"
        |
        v
tripathicle
        |
        v
STEP 6
Create Role
pod-reader
        |
        v
Permissions:
get / list / watch Pods
        |
        v
STEP 7
Create RoleBinding
        |
        v
Connect:
tripathicle ---> pod-reader
        |
        v
AUTHORIZATION
"What are you allowed to do?"
        |
        v
Access granted only to the allowed actions
```

---

# 17. A Simple Example for a Non-Technical Manager

Imagine a company building.

## Step 1: Identity

An employee named Shubham receives an official ID card.

In Kubernetes:

```text
Certificate = Identity Card
```

## Step 2: Authentication

Security checks the ID card.

```text
Security asks:
"Who are you?"

Answer:
"I am tripathicle."
```

In Kubernetes:

```text
API Server verifies the certificate.
```

## Step 3: Authorization

Now security checks the access policy.

```text
Can tripathicle enter the server room?

Policy says:
No.
```

But:

```text
Can tripathicle view Pod information?

Policy says:
Yes.
```

The Role is the access policy.

The RoleBinding is the assignment of that policy to a specific identity.

---

# 18. Authentication and Authorization in One Diagram

```text
                    KUBERNETES

User: tripathicle
        |
        | Uses
        v
Client Certificate
        |
        v
+----------------------+
|      API SERVER      |
+----------------------+
        |
        | Authentication
        v
"Who are you?"
        |
        v
tripathicle
        |
        | Authorization / RBAC
        v
+----------------------+
|     RoleBinding      |
+----------------------+
        |
        v
+----------------------+
|   Role: pod-reader   |
+----------------------+
        |
        +--> get Pods      YES
        +--> list Pods     YES
        +--> watch Pods    YES
        |
        +--> create Pods   NO
        +--> delete Pods   NO
```

---

# 19. Why Is This Important in Real Companies?

In a real organization, not everyone should have full access to a Kubernetes cluster.

For example:

| Team | Typical access |
|---|---|
| Developer | View logs and application resources |
| QA team | Access test namespaces |
| DevOps team | Manage infrastructure and deployments |
| Security team | Audit and review permissions |
| Cluster administrator | Full cluster administration |

Without RBAC, every person could potentially change or delete production resources.

That would be dangerous.

RBAC follows the **principle of least privilege**:

> Give each identity only the access required to perform its job.

For example:

```text
Developer:
Can view application Pods
Cannot delete production infrastructure

CI/CD pipeline:
Can deploy to a specific namespace
Cannot access every cluster resource

Cluster administrator:
Has broader administrative access
```

---

# 20. Role vs. ClusterRole

A `Role` is namespace-specific.

```text
Role
  |
  +--> default namespace only
```

A `ClusterRole` can define permissions across the entire cluster or for cluster-scoped resources.

```text
ClusterRole
  |
  +--> Multiple namespaces
  +--> Cluster-wide resources
```

A simple mental model:

```text
Role = Access to one department

ClusterRole = Access across the entire company
```

---

# 21. RoleBinding vs. ClusterRoleBinding

```text
RoleBinding
    |
    +--> Grants permissions within a namespace

ClusterRoleBinding
    |
    +--> Grants cluster-wide permissions
```

Be careful with `ClusterRoleBinding`, especially when assigning powerful roles such as:

```text
cluster-admin
```

Giving someone `cluster-admin` is similar to giving them administrator access to the entire Kubernetes cluster.

---

# 22. Final Summary

The most important lesson is this:

```text
IDENTITY != PERMISSION
```

A valid certificate only proves:

> "This request belongs to tripathicle."

It does not automatically mean:

> "Tripathicle can do anything."

Kubernetes still checks RBAC.

The final mental model is:

```text
Certificate
    |
    v
Authentication
"Who are you?"
    |
    v
tripathicle
    |
    v
RBAC
    |
    +--> Role
    |      "What actions are allowed?"
    |
    +--> RoleBinding
           "Who receives those permissions?"
    |
    v
Authorization Decision
    |
    +--> ALLOW
    |
    +--> DENY
```

---

# Key Takeaway

**Authentication identifies you.**

**Authorization controls what you can do.**

In our lab:

```text
Identity:
tripathicle

Authentication:
Client Certificate

Permissions:
get
list
watch

Resource:
Pods

Scope:
default namespace

Authorization mechanism:
RBAC
```

This is the foundation of secure access control in Kubernetes.

---

## Next Step

The next logical step is to configure a separate `kubeconfig` for `tripathicle`, switch `kubectl` to that identity, and prove that RBAC is working by testing:

```bash
kubectl get pods
```

and then attempting an action that should be denied, such as:

```bash
kubectl delete pod nginx
```

Expected result:

```text
get/list/watch Pods  -> ALLOWED
delete Pods          -> FORBIDDEN
```
