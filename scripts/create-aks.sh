#!/bin/bash
# Script to create AKS cluster for GitHub Runners

# Check if all required parameters are provided
if [ $# -ne 6 ]; then
    echo "Usage: $0 <resource-group> <cluster-name> <location> <k8s-version> <node-count> <node-size>"
    exit 1
fi

RESOURCE_GROUP=$1
CLUSTER_NAME=$2
LOCATION=$3
K8S_VERSION=$4
NODE_COUNT=$5
NODE_SIZE=$6

echo "Creating AKS cluster with the following parameters:"
echo "Resource Group: $RESOURCE_GROUP"
echo "Cluster Name: $CLUSTER_NAME"
echo "Location: $LOCATION"
echo "Kubernetes Version: $K8S_VERSION"
echo "Node Count: $NODE_COUNT"
echo "Node Size: $NODE_SIZE"

# Create AKS cluster
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --location $LOCATION \
    --kubernetes-version $K8S_VERSION \
    --node-count $NODE_COUNT \
    --node-vm-size $NODE_SIZE \
    --node-resource-group "${RESOURCE_GROUP}-npool" \
    --enable-managed-identity \
    --generate-ssh-keys \
    --network-plugin kubenet \
    --network-policy calico \
    --tags "purpose=github-runners" "environment=ci" "global.finops.company-code=110" "global.finops.cost-center=2023" "global.finops.cost-owner=Bartosz.Sajkowski@securitas.com" "global.finops.country=Global" "global.finops.project-code=90" "global.finops.project-name=Non-Project" "global.operation.environment=sandbox" "global.operation.governance=GITS‑E" "global.operation.managed-by=Jakub.Wdowiarek@securitas.com" "global.tagging-version=1.0" \
    --yes

# Check if cluster creation was successful
if [ $? -eq 0 ]; then
    echo "AKS cluster created successfully"
else
    echo "Error: Failed to create AKS cluster"
    exit 1
fi

# Get AKS credentials
echo "Getting AKS credentials..."
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --admin

# Verify cluster is accessible
echo "Verifying cluster access..."
kubectl get nodes

echo "AKS cluster setup completed successfully!"
