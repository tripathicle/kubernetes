#!/bin/bash

kubectl config set-credentials tripathicle \
  --client-certificate=/home/tripathicle/kubernetes/tripathicle.crt \
  --client-key=/home/tripathicle/kubernetes/tripathicle.key

kubectl config set-context tripathicle-context \
  --cluster=kind-tripathicle-dev-cluster \
  --namespace=dev \
  --user=tripathicle

kubectl config use-context tripathicle-context

kubectl config get-contexts

kubectl config current-context

kubectl get pods



# Check the current Kubernetes context
kubectl config current-context

# List all available Kubernetes contexts
kubectl config get-contexts

# Check pods using the active context
kubectl get pods

# Check nodes using the active context
kubectl get nodes

# Check the kubeconfig file explicitly
kubectl get nodes --kubeconfig ~/.kube/config

# Verify the kubeconfig file exists
ls ~/.kube/config

# Check the KUBECONFIG environment variable
echo $KUBECONFIG