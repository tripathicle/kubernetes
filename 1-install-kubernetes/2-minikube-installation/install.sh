```bash
#!/bin/bash

# Simple KIND Kubernetes cluster setup script.
# Docker must already be installed and running.

set -e

# Install KIND.
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
chmod +x kind
sudo mv kind /usr/local/bin/kind

# Install kubectl.
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# Create a KIND cluster with one control-plane and two workers.
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

# Create the cluster.
kind create cluster --name dev-cluster --config kind-config.yaml

# Verify the cluster.
kubectl get nodes

echo "KIND cluster created successfully."
echo "Delete it with: kind delete cluster --name dev-cluster"
```
