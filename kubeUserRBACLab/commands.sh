#!/bin/bash

# ============================================================
# 1. CREATE WORKING DIRECTORY
# ============================================================

mkdir kubernetes
cd kubernetes

# ============================================================
# 2. CREATE KIND KUBERNETES CLUSTER
# ============================================================

# Check the current directory
pwd

# Create the Kubernetes cluster using the Kind configuration file
kind create cluster \
  --name tripathicle-dev-cluster \
  --config config.yaml

# Verify that the cluster was created
kind get clusters

# Check the current Kubernetes context
kubectl config current-context

# Check all configured Kubernetes contexts
kubectl config get-contexts

# ============================================================
# 3. VERIFY KUBERNETES CLUSTER
# ============================================================

# Check control-plane and worker nodes
kubectl get nodes

# Check Kubernetes control-plane information
kubectl cluster-info

# Check all pods running across all namespaces
kubectl get pods -A

# Check all namespaces
kubectl get namespaces

# Check all services across all namespaces
kubectl get services -A

# ============================================================
# 4. CREATE A TEST NGINX POD
# ============================================================

# Create a simple nginx pod in the default namespace
kubectl run nginx --image=nginx

# Verify the pod
kubectl get pods

# Show detailed pod information including the node and pod IP
kubectl get pods -o wide

# Show detailed information about the nginx pod
kubectl describe pod nginx

# ============================================================
# 5. CREATE KUBERNETES USER: TRIPATHICLE
# ============================================================

# Generate a private key for the Kubernetes user
openssl genrsa -out tripathicle.key 2048

# Generate a Certificate Signing Request (CSR)
# CN = username
# O  = group name
openssl req -new \
  -key tripathicle.key \
  -out tripathicle.csr \
  -subj "/CN=tripathicle/O=developers"

# Convert the CSR into Base64 so it can be placed
# inside the Kubernetes CertificateSigningRequest YAML
cat tripathicle.csr | base64 | tr -d '\n'

# Apply the Kubernetes CSR manifest
kubectl apply -f csr.yaml

# Check the CSR status
kubectl get csr tripathicle

# Approve the user's certificate request
kubectl certificate approve tripathicle

# Verify that the certificate was approved and issued
kubectl get csr tripathicle

# Extract the issued certificate from the CSR
kubectl get csr tripathicle \
  -o jsonpath='{.status.certificate}' \
  | base64 --decode > tripathicle.crt

# Verify the generated user certificate files
ls -l tripathicle.*

# ============================================================
# 6. CREATE A READ-ONLY ROLE FOR PODS
# ============================================================

# Apply the Role that allows:
# get    = view a specific pod
# list   = list pods
# watch  = watch pod changes
kubectl apply -f role.yaml

# Verify the Role
kubectl get role

# ============================================================
# 7. BIND THE READ-ONLY ROLE TO TRIPATHICLE
# ============================================================

# Connect the pod-reader Role to the tripathicle user
kubectl apply -f rolebinding.yaml

# Verify the RoleBinding
kubectl get rolebinding

# ============================================================
# 8. TEST TRIPATHICLE'S PERMISSIONS
# ============================================================

# Check whether tripathicle can view pods
kubectl auth can-i get pods --as=tripathicle

# Check whether tripathicle can list pods
kubectl auth can-i list pods --as=tripathicle

# Check whether tripathicle can delete pods
# Expected result: no
kubectl auth can-i delete pods --as=tripathicle

# Check access to the default namespace
kubectl auth can-i get pods \
  --as=tripathicle \
  -n default

# Check access to kube-system
# Expected result: no because the Role is namespace-scoped
kubectl auth can-i get pods \
  --as=tripathicle \
  -n kube-system

# ============================================================
# 9. TEST THAT TRIPATHICLE CANNOT CREATE DEPLOYMENTS
# ============================================================

# Attempt to create a Deployment as tripathicle
# Expected result: forbidden
kubectl create deployment nginx \
  --image=nginx \
  --as=tripathicle

# ============================================================
# 10. CREATE ENVIRONMENT NAMESPACES
# ============================================================

# Create separate namespaces for each environment
kubectl create namespace dev
kubectl create namespace test
kubectl create namespace prod

# Verify the environments
kubectl get namespaces

# ============================================================
# 11. CREATE DEVELOPER ROLE IN DEV
# ============================================================

# Apply the developer Role in the dev namespace
# Permissions:
# get, list, watch, create, update, delete pods
kubectl apply -f developer-role.yaml

# Verify the Role
kubectl get role -n dev

# View the exact permissions assigned to the Role
kubectl describe role developer -n dev

# ============================================================
# 12. BIND DEVELOPER ROLE TO TRIPATHICLE IN DEV
# ============================================================

# Give tripathicle the developer Role in the dev namespace
kubectl apply -f developer-rolebinding.yaml

# Verify the RoleBinding
kubectl get rolebinding -n dev

# View which user is connected to which Role
kubectl describe rolebinding developer-binding -n dev

# ============================================================
# 13. TEST DEV PERMISSIONS
# ============================================================

# tripathicle should be able to create pods in dev
kubectl auth can-i create pods \
  --as=tripathicle \
  -n dev

# tripathicle should be able to delete pods in dev
kubectl auth can-i delete pods \
  --as=tripathicle \
  -n dev

# tripathicle should be able to view pods in dev
kubectl auth can-i get pods \
  --as=tripathicle \
  -n dev

# ============================================================
# 14. VERIFY THAT DEV PERMISSIONS DO NOT APPLY TO TEST/PROD
# ============================================================

# Expected result: no
kubectl auth can-i create pods \
  --as=tripathicle \
  -n test

# Expected result: no
kubectl auth can-i create pods \
  --as=tripathicle \
  -n prod

# ============================================================
# 15. CREATE A POD IN DEV
# ============================================================

# Verify that tripathicle has permission to create pods
kubectl auth can-i create pods \
  --as=tripathicle \
  -n dev

# Create an nginx pod in the dev namespace
kubectl apply -f nginx-dev.yaml

# Create another nginx pod directly from the command line
kubectl run tripathicle-in-dev-nginx \
  --image=nginx \
  --namespace=dev

# Verify pods in the dev namespace
kubectl get pods -n dev

# Verify pods across all namespaces
kubectl get pods -A

# ============================================================
# 16. CREATE VIEW-ONLY ROLE IN PROD
# ============================================================

# Apply the production viewer Role
kubectl apply -f prod-viewer-role.yaml

# Verify the production Role
kubectl get role -n prod

# ============================================================
# 17. BIND PROD VIEWER ROLE TO TRIPATHICLE
# ============================================================

# Give tripathicle read-only access to pods in prod
kubectl apply -f prod-viewer-rolebinding.yaml

# Verify the RoleBinding
kubectl get rolebinding -n prod

# ============================================================
# 18. TEST PROD PERMISSIONS
# ============================================================

# tripathicle can view pods in prod
kubectl auth can-i get pods \
  --as=tripathicle \
  -n prod

# tripathicle can list pods in prod
kubectl auth can-i list pods \
  --as=tripathicle \
  -n prod

# tripathicle cannot create pods in prod
kubectl auth can-i create pods \
  --as=tripathicle \
  -n prod

# tripathicle cannot update pods in prod
kubectl auth can-i update pods \
  --as=tripathicle \
  -n prod

# tripathicle cannot delete pods in prod
kubectl auth can-i delete pods \
  --as=tripathicle \
  -n prod

# ============================================================
# 19. FINAL RBAC VALIDATION
# ============================================================

# DEV:
# Full pod permissions
kubectl auth can-i create pods --as=tripathicle -n dev
kubectl auth can-i get pods --as=tripathicle -n dev
kubectl auth can-i update pods --as=tripathicle -n dev
kubectl auth can-i delete pods --as=tripathicle -n dev

# TEST:
# No pod creation permission
kubectl auth can-i create pods --as=tripathicle -n test

# PROD:
# Read-only pod access
kubectl auth can-i get pods --as=tripathicle -n prod
kubectl auth can-i list pods --as=tripathicle -n prod
kubectl auth can-i create pods --as=tripathicle -n prod
kubectl auth can-i update pods --as=tripathicle -n prod
kubectl auth can-i delete pods --as=tripathicle -n prod