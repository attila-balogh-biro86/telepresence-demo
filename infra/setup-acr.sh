#!/usr/bin/env bash
set -euo pipefail

# Configuration — edit these for your environment
RESOURCE_GROUP="${RESOURCE_GROUP:?Set RESOURCE_GROUP env var (e.g. export RESOURCE_GROUP=mygroup)}"
ACR_NAME="${ACR_NAME:?Set ACR_NAME env var (e.g. export ACR_NAME=myacr)}"
AKS_CLUSTER="${AKS_CLUSTER:?Set AKS_CLUSTER env var (e.g. export AKS_CLUSTER=myaks)}"
LOCATION="${LOCATION:-westeurope}"

echo "========================================="
echo " Setting up Azure Container Registry"
echo "========================================="
echo " Resource Group: $RESOURCE_GROUP"
echo " ACR Name:       $ACR_NAME"
echo " AKS Cluster:    $AKS_CLUSTER"
echo " Location:       $LOCATION"
echo "========================================="
echo ""

# Create ACR
echo "Creating ACR '$ACR_NAME'..."
az acr create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$ACR_NAME" \
    --sku Basic \
    --location "$LOCATION"

echo ""

# Attach ACR to AKS (grants AKS pull access)
echo "Attaching ACR to AKS cluster '$AKS_CLUSTER'..."
az aks update \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER" \
    --attach-acr "$ACR_NAME"

echo ""
echo "ACR setup complete. Login server: ${ACR_NAME}.azurecr.io"
