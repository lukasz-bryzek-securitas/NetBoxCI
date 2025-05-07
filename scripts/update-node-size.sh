#!/bin/bash
# Script to update node size in AKS cluster

# Check if all required parameters are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <resource-group> <cluster-name> <new-node-size>"
    exit 1
fi

RESOURCE_GROUP=$1
CLUSTER_NAME=$2
NEW_NODE_SIZE=$3

echo "Updating node size in AKS cluster with the following parameters:"
echo "Resource Group: $RESOURCE_GROUP"
echo "Cluster Name: $CLUSTER_NAME"
echo "New Node Size: $NEW_NODE_SIZE"

# Get current node pool name
NODE_POOL_NAME=$(az aks nodepool list --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --query '[0].name' -o tsv)

if [ -z "$NODE_POOL_NAME" ]; then
    echo "Error: Failed to get node pool name"
    exit 1
fi

echo "Identified node pool: $NODE_POOL_NAME"

# Get current node count
NODE_COUNT=$(az aks nodepool show --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name $NODE_POOL_NAME --query count -o tsv)

if [ -z "$NODE_COUNT" ]; then
    echo "Error: Failed to get node count"
    exit 1
fi

echo "Current node count: $NODE_COUNT"

# Create a new node pool with the new VM size
echo "Creating new node pool with updated VM size..."
NEW_NODE_POOL_NAME="${NODE_POOL_NAME}new"

az aks nodepool add \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --name $NEW_NODE_POOL_NAME \
    --node-count $NODE_COUNT \
    --node-vm-size $NEW_NODE_SIZE \
    --mode System

if [ $? -ne 0 ]; then
    echo "Error: Failed to create new node pool"
    exit 1
fi

# Cordon and drain old node pool
echo "Cordoning and draining old node pool..."
OLD_NODES=$(kubectl get nodes -l agentpool=$NODE_POOL_NAME -o jsonpath='{.items[*].metadata.name}')

for NODE in $OLD_NODES; do
    echo "Cordoning $NODE..."
    kubectl cordon $NODE
    
    echo "Draining $NODE..."
    kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data --force
done

# Delete old node pool
echo "Deleting old node pool..."
az aks nodepool delete \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --name $NODE_POOL_NAME \
    --yes

if [ $? -ne 0 ]; then
    echo "Error: Failed to delete old node pool"
    exit 1
fi

# Rename new node pool to original name
echo "Renaming new node pool to $NODE_POOL_NAME..."
az aks nodepool update \
    --resource-group $RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --name $NEW_NODE_POOL_NAME \
    --tags "originalName=$NODE_POOL_NAME"

echo "Node size update completed successfully!"
echo "New node pool running with VM size: $NEW_NODE_SIZE"

# Verify new node pool
kubectl get nodes -l agentpool=$NEW_NODE_POOL_NAME
