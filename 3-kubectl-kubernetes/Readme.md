# Kubernetes Masterclass: kubectl Explained

> A practical beginner-to-intermediate guide to understanding and using `kubectl` to interact with Kubernetes clusters.

---

## 📖 What is `kubectl`?

`kubectl` is the command-line tool used to communicate with a Kubernetes cluster.

Think of Kubernetes as a large building and `kubectl` as the **control panel** you use to inspect and operate it.

With `kubectl`, you can:

- View Kubernetes resources
- Deploy applications
- Scale applications
- Troubleshoot failures
- View application logs
- Access containers
- Modify resources
- Delete resources
- Inspect cluster state

The important thing to understand is:

> **`kubectl` does not directly control Pods or Nodes. It communicates with the Kubernetes API Server.**

---

# 🧠 The Big Picture

When you run:

```bash
kubectl get pods

you can imagine the following:

You
 |
 | kubectl get pods
 v
kubectl
 |
 | HTTPS API Request
 v
Kubernetes API Server
 |
 +------> etcd
 |
 +------> Scheduler
 |
 +------> Controller Manager
 |
 +------> Kubelet
             |
             v
           Pods

Your command goes to the API Server.

The API Server authenticates and authorizes the request, reads or changes Kubernetes state, and communicates with the appropriate Kubernetes components.

So remember:

kubectl
   ↓
API Server
   ↓
Kubernetes Cluster
🔐 How does kubectl know which cluster to connect to?

When you install Kubernetes, kubectl normally uses a configuration file called:

~/.kube/config

This file contains information such as:

Kubernetes API Server address
Cluster information
User/identity information
Authentication credentials
Contexts

Check your current configuration:

kubectl config view
Current Context

A context tells kubectl:

"Which cluster should I talk to, and as which user?"

Check the current context:

kubectl config current-context

List all contexts:

kubectl config get-contexts

Switch context:

kubectl config use-context <context-name>

For example:

kubectl config use-context dev-cluster
✅ 1. Check Cluster Connectivity

Before doing anything else, verify that kubectl can communicate with Kubernetes.

kubectl cluster-info

Example:

Kubernetes control plane is running at https://127.0.0.1:6443

This tells you that:

kubectl
   ↓
API Server

communication is working.

🖥️ 2. View Kubernetes Nodes
kubectl get nodes

Example:

NAME           STATUS   ROLES           AGE   VERSION
master-node    Ready    control-plane   10m   v1.34.x
worker-node-1  Ready    <none>          8m    v1.34.x
worker-node-2  Ready    <none>          8m    v1.34.x

A Node is a machine that Kubernetes uses to run workloads.

It can be:

Virtual machine
Physical machine
Cloud VM

For example:

Kubernetes Cluster

        Control Plane
             |
      +------+------+
      |             |
      v             v
   Worker 1      Worker 2
      |             |
     Pods          Pods
Get More Node Information
kubectl get nodes -o wide

You can see additional information such as:

Internal IP
OS
Kernel
Container runtime
Kubernetes version
🔎 3. kubectl get

get means:

"Show me the current state of this resource."

This is probably the command you will use most often.

Get Pods
kubectl get pods

Example:

NAME                     READY   STATUS    RESTARTS   AGE
nginx-7d8b49557c-x7k2m  1/1     Running   0          2m

You are asking Kubernetes:

"Show me the Pods in my current namespace."

Get Pods from Every Namespace
kubectl get pods -A

-A means:

--all-namespaces

This is extremely useful when troubleshooting cluster-level problems.

Get Pods with More Information
kubectl get pods -o wide

Example:

NAME      READY   STATUS    IP          NODE
nginx     1/1     Running   10.244.1.5  worker-node-1

Now you can see:

Pod
 |
 +-- IP
 |
 +-- Node where it is running
📦 4. Kubernetes Namespaces

Kubernetes uses namespaces to logically separate resources.

For example:

Cluster
 |
 +-- default
 |
 +-- development
 |
 +-- staging
 |
 +-- production

List namespaces:

kubectl get namespaces

or:

kubectl get ns

Get Pods from a specific namespace:

kubectl get pods -n development

Get everything in a namespace:

kubectl get all -n development
🚀 5. View Deployments

A Deployment manages application Pods.

kubectl get deployments

or:

kubectl get deploy

Example:

NAME    READY   UP-TO-DATE   AVAILABLE
nginx   3/3     3            3

This means:

Deployment
     |
     +---- Pod
     +---- Pod
     +---- Pod

The Deployment makes sure the desired number of Pods exists.

🌐 6. View Services
kubectl get services

or:

kubectl get svc

Example:

NAME         TYPE        CLUSTER-IP     PORT(S)
kubernetes   ClusterIP   10.96.0.1      443/TCP
nginx        NodePort    10.96.10.20    80:30080/TCP

A Service provides a stable way to access Pods.

Why?

Because Pods are temporary.

A Pod can be destroyed and recreated with a different IP.

So instead of connecting directly to:

Pod IP

applications usually connect through:

Service
   ↓
Pods
🔥 7. View Almost Everything
kubectl get all

This can show common resources such as:

Pods
Services
Deployments
ReplicaSets

For a specific namespace:

kubectl get all -n production
🔬 8. kubectl describe

get tells you:

What is happening?

describe helps answer:

Why is it happening?

Syntax:

kubectl describe <resource> <name>

Example:

kubectl describe pod nginx
What does describe show?

It can show:

Name
Namespace
Labels
Annotations
Node
IP address
Containers
Images
Environment variables
Volumes
Conditions
Events
Scheduling information
🚨 Why describe is important

Suppose:

kubectl get pods

returns:

NAME    READY   STATUS
nginx   0/1     Pending

You don't know why.

Run:

kubectl describe pod nginx

At the bottom you may find:

Events:

FailedScheduling
Insufficient cpu

Now you know the problem.

The mental model is:

kubectl get
     ↓
"What?"
     ↓
kubectl describe
     ↓
"Why?"
📜 9. kubectl logs

Applications write logs.

You can view them using:

kubectl logs <pod-name>

Example:

kubectl logs nginx

For a Pod with multiple containers:

kubectl logs <pod-name> -c <container-name>
Follow Logs in Real Time
kubectl logs -f <pod-name>

-f means:

follow

It behaves similarly to:

tail -f

You can stop following with:

Ctrl + C
Previous Container Logs

This is extremely useful after a container crashes.

kubectl logs <pod-name> --previous

Example:

kubectl logs nginx --previous

This can help when you see:

CrashLoopBackOff
🐚 10. kubectl exec

Sometimes logs aren't enough.

You want to inspect what's happening inside the running container.

Use:

kubectl exec -it <pod-name> -- sh

Example:

kubectl exec -it nginx -- sh

If Bash exists:

kubectl exec -it nginx -- bash

Now you are inside the container.

You can run:

pwd
ls
hostname
env

You can also test connectivity:

curl http://service-name
Important Mental Model

This:

kubectl exec

does NOT mean you SSH into the Kubernetes Node.

You are executing a command inside a container.

Think:

Your Laptop
     |
   kubectl
     |
 API Server
     |
    Pod
     |
 Container
     |
   Command
📝 11. kubectl apply

This is one of the most important Kubernetes commands.

kubectl apply -f deployment.yaml

It tells Kubernetes:

"Make the cluster match the configuration described in this file."

📄 Example Deployment

Create:

deployment.yaml

with:

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
          image: nginx:latest
          ports:
            - containerPort: 80

Apply it:

kubectl apply -f deployment.yaml

Check:

kubectl get deployment

Then:

kubectl get pods

You should see approximately:

NAME                     READY   STATUS
nginx-xxxxxxxxxx-abc12   1/1     Running
nginx-xxxxxxxxxx-def34   1/1     Running
nginx-xxxxxxxxxx-ghi56   1/1     Running
🧠 What actually happened?

You wrote:

replicas: 3

You are declaring:

"I want 3 replicas."

That is your desired state.

Kubernetes continuously compares:

Desired State
      vs
Current State

If:

Desired = 3 Pods
Current = 2 Pods

Kubernetes attempts to create another Pod.

If:

Desired = 3
Current = 4

Kubernetes attempts to reduce the number.

This is one of the most important ideas in Kubernetes.

🔄 12. Update an Application

Suppose your Deployment currently uses:

image: nginx:1.25

You change it to:

image: nginx:1.26

Then:

kubectl apply -f deployment.yaml

Kubernetes detects the change and performs the required rollout.

Check:

kubectl rollout status deployment nginx

View rollout history:

kubectl rollout history deployment nginx
↩️ 13. Rollback a Deployment

If the new version causes problems:

kubectl rollout undo deployment nginx

Check:

kubectl rollout status deployment nginx

This is extremely useful during production incidents.

📈 14. Scale an Application

Suppose you have:

3 Pods

and suddenly traffic increases.

You can scale the Deployment:

kubectl scale deployment nginx --replicas=5

Verify:

kubectl get pods

Now you should have:

nginx Pod
nginx Pod
nginx Pod
nginx Pod
nginx Pod
✏️ 15. kubectl edit

You can directly edit a Kubernetes resource:

kubectl edit deployment nginx

For example:

replicas: 1

Change it to:

replicas: 3

Save and exit.

Kubernetes applies the change.

⚠️ Production Note

kubectl edit is useful for emergency debugging and quick changes.

But in production GitOps environments, prefer:

Git
 ↓
YAML
 ↓
Pull Request
 ↓
Review
 ↓
CI/CD or GitOps
 ↓
Kubernetes

rather than making undocumented manual changes.

🗑️ 16. kubectl delete

Delete a Pod:

kubectl delete pod nginx

Delete a Deployment:

kubectl delete deployment nginx

Delete a Service:

kubectl delete service nginx

Delete resources defined in YAML:

kubectl delete -f deployment.yaml
⚠️ Important: Deleting a Pod Doesn't Always Mean the Application Is Gone

Suppose a Deployment manages 3 Pods:

Deployment
    |
    +-- Pod 1
    +-- Pod 2
    +-- Pod 3

You execute:

kubectl delete pod pod-1

Kubernetes sees:

Desired = 3
Current = 2

So the Deployment controller creates another Pod.

You may see:

Pod 1 → Deleted

Pod 4 → Created

This is Kubernetes maintaining the desired state.

🧭 17. kubectl get with Labels

Labels are extremely important in Kubernetes.

Example:

labels:
  app: nginx
  environment: production

Find Pods with a specific label:

kubectl get pods -l app=nginx

Another example:

kubectl get pods -l environment=production

Labels allow Kubernetes resources to identify and group other resources.

🏷️ 18. Show Labels
kubectl get pods --show-labels

Example:

NAME    STATUS    LABELS
nginx   Running   app=nginx,environment=production
📋 19. kubectl get with YAML

Sometimes you want to see the actual Kubernetes object definition.

kubectl get deployment nginx -o yaml

This is useful for understanding:

Current configuration
Metadata
Status
Spec
Labels
Annotations

You can also use:

kubectl get pod nginx -o yaml
📄 20. Output Formats

Kubernetes supports different output formats.

Normal:

kubectl get pods

Wide:

kubectl get pods -o wide

YAML:

kubectl get pod nginx -o yaml

JSON:

kubectl get pod nginx -o json

Custom output:

kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
🔍 21. kubectl explain

This is one of the most useful commands for learning Kubernetes.

You don't always need Google.

Ask Kubernetes itself:

kubectl explain deployment

For a specific field:

kubectl explain deployment.spec

Go deeper:

kubectl explain deployment.spec.template

Another example:

kubectl explain pod.spec.containers

This helps you understand what fields Kubernetes expects in YAML files.

🌐 22. kubectl port-forward

Sometimes you have a Service or Pod that is not exposed outside the cluster.

You can temporarily forward a local port.

For a Pod:

kubectl port-forward pod/nginx 8080:80

Now:

localhost:8080
      |
      v
Pod:80

Open:

http://localhost:8080

For a Service:

kubectl port-forward service/nginx 8080:80

This is extremely useful during development and debugging.

📦 23. Working with Multiple YAML Files

Suppose your project looks like:

kubernetes/
│
├── deployment.yaml
├── service.yaml
├── configmap.yaml
└── secret.yaml

You can apply everything:

kubectl apply -f .

Or apply a directory:

kubectl apply -f ./kubernetes/
🔥 24. Real-World Troubleshooting Workflow

Imagine your application is not working.

Don't randomly execute commands.

Follow a logical path.

Step 1 — Check Nodes
kubectl get nodes

Question:

Are my Kubernetes nodes healthy?

If you see:

NotReady

investigate the node.

Step 2 — Check Pods
kubectl get pods -A

Look for:

Pending
CrashLoopBackOff
ImagePullBackOff
ErrImagePull
Error
ContainerCreating
Step 3 — Describe the Problematic Pod
kubectl describe pod <pod-name>

Look at:

Events

This often tells you why Kubernetes cannot run the Pod.

Step 4 — Check Logs
kubectl logs <pod-name>

If the container previously crashed:

kubectl logs <pod-name> --previous
Step 5 — Enter the Container
kubectl exec -it <pod-name> -- sh

Then investigate:

env
ls
pwd

Test connectivity if tools are available:

curl http://service-name
Step 6 — Check the Service
kubectl get svc

Then:

kubectl describe svc <service-name>
Step 7 — Check Endpoints
kubectl get endpoints

Or:

kubectl get endpointslices

If the Service has no backend endpoints, the Service cannot send traffic to your Pods.

🧠 The Troubleshooting Mental Model

Think about an application like this:

User
 |
 v
Ingress / Load Balancer
 |
 v
Service
 |
 v
Pods
 |
 v
Container
 |
 v
Application

When something fails, walk down the chain.

Is the Node healthy?
       ↓
Are Pods running?
       ↓
Is the application healthy?
       ↓
Does the Service have endpoints?
       ↓
Can the Service reach Pods?
       ↓
Can the application process the request?

This is much better than randomly running commands.

⚡ 25. The Most Important kubectl Commands
Command	Purpose
kubectl cluster-info	Check cluster connectivity
kubectl get nodes	List nodes
kubectl get pods	List Pods
kubectl get pods -A	List Pods across namespaces
kubectl get svc	List Services
kubectl get deployments	List Deployments
kubectl get all	View common resources
kubectl describe	Investigate a resource
kubectl logs	View application logs
kubectl exec	Execute commands inside containers
kubectl apply -f	Create/update resources
kubectl delete	Delete resources
kubectl edit	Edit a live resource
kubectl scale	Change replica count
kubectl rollout status	Check rollout
kubectl rollout undo	Roll back deployment
kubectl port-forward	Temporarily expose resource locally
kubectl explain	Learn Kubernetes resource fields
kubectl get -o yaml	Inspect resource as YAML
🎯 One Command → One Question

A useful way to remember kubectl is to associate commands with questions.

kubectl get
    ↓
"What exists?"

kubectl describe
    ↓
"What's happening and why?"

kubectl logs
    ↓
"What is my application saying?"

kubectl exec
    ↓
"What's happening inside the container?"

kubectl apply
    ↓
"Make the cluster match my configuration."

kubectl delete
    ↓
"Remove this resource."

kubectl scale
    ↓
"Run more or fewer replicas."

kubectl rollout
    ↓
"What's happening with my deployment version?"

kubectl explain
    ↓
"What does this Kubernetes field mean?"
🧪 Complete Example

Let's deploy Nginx.

Create:

apiVersion: apps/v1
kind: Deployment

metadata:
  name: nginx

spec:
  replicas: 2

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
          image: nginx:latest
          ports:
            - containerPort: 80

Apply:

kubectl apply -f deployment.yaml

Check Deployment:

kubectl get deployment

Check Pods:

kubectl get pods

Get more details:

kubectl get pods -o wide

Inspect a Pod:

kubectl describe pod <pod-name>

View logs:

kubectl logs <pod-name>

Enter the container:

kubectl exec -it <pod-name> -- sh

Check the Deployment rollout:

kubectl rollout status deployment nginx

Scale:

kubectl scale deployment nginx --replicas=5

Verify:

kubectl get pods

Delete:

kubectl delete deployment nginx
🧠 What You Should Understand

Don't try to memorize hundreds of commands.

Understand the relationship:

kubectl
   |
   v
API Server
   |
   v
Kubernetes Objects
   |
   +---- Nodes
   +---- Pods
   +---- Deployments
   +---- Services
   +---- ConfigMaps
   +---- Secrets
   +---- Ingress

Then understand the basic operations:

GET
DESCRIBE
CREATE / APPLY
UPDATE
LOG
EXEC
SCALE
DELETE

Once these concepts are clear, learning additional kubectl commands becomes much easier.

🚨 Production Troubleshooting Cheat Sheet
Pod is Pending
kubectl describe pod <pod-name>

Check:

Events
Pod is CrashLoopBackOff
kubectl logs <pod-name>

Then:

kubectl logs <pod-name> --previous

And:

kubectl describe pod <pod-name>
ImagePullBackOff
kubectl describe pod <pod-name>

Look for:

Failed to pull image

Check:

Image name
Image tag
Registry access
ImagePullSecrets
Pod is Running but Application Doesn't Work

Check:

kubectl get svc

Then:

kubectl describe svc <service-name>

Then:

kubectl get endpoints

Then test from inside the cluster if appropriate.

Node is NotReady
kubectl describe node <node-name>

Check:

Conditions
Events
🏆 Final Mental Model

If you remember only one thing from this README, remember this:

                 YOU
                  |
                  | kubectl
                  v
          +---------------+
          |  API SERVER   |
          +---------------+
                  |
       +----------+----------+
       |          |          |
       v          v          v
   Deployment   Service     Config
       |
       v
     Pods
       |
       v
   Containers
       |
       v
   Application

And when something breaks:

1. GET
   ↓
   What is broken?

2. DESCRIBE
   ↓
   Why is it broken?

3. LOGS
   ↓
   What is the application saying?

4. EXEC
   ↓
   Can I investigate from inside?

5. APPLY / SCALE / ROLLOUT
   ↓
   Can I safely fix it?

6. GET
   ↓
   Did the fix work?

That workflow is far more valuable than memorizing a long list of commands.

📚 Recommended Learning Path

After mastering kubectl, continue with:

Kubernetes Architecture
Pods Deep Dive
ReplicaSets
Deployments
Services
Namespaces
Labels & Selectors
ConfigMaps
Secrets
Volumes
Ingress
StatefulSets
DaemonSets
Jobs & CronJobs
Resource Requests & Limits
Probes
RBAC
Network Policies
Helm
Kubernetes Production Architecture
⭐ If this repository helped you, consider giving it a star and sharing it with others learning Kubernetes.
Connect with Shubham Tripathi