Minikube Installation Guide
This README explains how to install Docker, kubectl, and Minikube on Ubuntu, then start a local Minikube cluster using the Docker driver.

Requirements
Ubuntu-based Linux distribution
Internet access
sudo privileges
Overview
This guide covers:

updating the system,
installing Docker,
enabling and starting Docker,
adding the current user to the Docker group,
installing kubectl,
installing Minikube,
starting a multi-node Minikube cluster, and
verifying the cluster.
Install script
You can run install.sh to automate Docker installation, group configuration, and Minikube setup for this environment.

Installation Steps
1. Update System
Update package lists and install available upgrades.

sudo apt update && sudo apt upgrade -y
2. Install Docker
Install Docker from the Ubuntu package repositories.

sudo apt install -y docker.io
3. Enable and Start Docker
Enable Docker to start on boot, then start the service immediately.

sudo systemctl enable docker
sudo systemctl start docker
4. Add User to Docker Group
Add the current user to the Docker group and refresh the group membership.

sudo usermod -aG docker $USER
newgrp docker
5. Verify Docker
Check Docker installation and ensure the daemon is running.

docker --version
docker ps
6. Install kubectl
Download kubectl, make it executable, and install it to /usr/local/bin/.

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo install kubectl /usr/local/bin/
Verify kubectl:

kubectl version --client
7. Install Minikube
Download the latest Minikube binary and install it.

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
8. Verify Minikube
Confirm Minikube is installed correctly.

minikube version
9. Start Minikube (Docker Driver)
Start a Minikube cluster using the Docker driver with 3 nodes.

minikube start --driver=docker --nodes=3
10. Verify Cluster
Verify the Kubernetes cluster and control plane status.

kubectl get nodes
kubectl cluster-info
🔐 Ports & Services Documentation
Minikube Cluster Ports
Minikube runs locally in Docker containers. The following ports are relevant:

Protocol	Port(s)	Purpose
TCP	6443	Kubernetes API server (kubectl)
TCP	10250	Kubelet API
TCP	30000-32767	NodePort Services
TCP	8080	kubectl proxy (if used)
TCP	8443	Minikube dashboard (optional)
Network Access
Minikube clusters are local only and accessible from localhost
Services are accessed via localhost:<port> or 127.0.0.1:<port>
NodePort services are available on port range 30000-32767
No firewall/security group configuration needed for local development
Accessing Services
# Get service details
kubectl get svc

# Access NodePort service
curl http://localhost:30000  # Example NodePort

# Port-forward for direct access
kubectl port-forward svc/<service-name> 8080:80

# Open Minikube dashboard (optional)
minikube dashboard
Connect with Shubham Tripathi