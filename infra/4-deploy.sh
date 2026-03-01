#!/usr/bin/env bash
set -euo pipefail

ACR_NAME="${ACR_NAME:?Set ACR_NAME env var (e.g. export ACR_NAME=myacr)}"
RESOURCE_GROUP="${RESOURCE_GROUP:?Set RESOURCE_GROUP env var (e.g. export RESOURCE_GROUP=mygroup)}"
AKS_CLUSTER="${AKS_CLUSTER:?Set AKS_CLUSTER env var (e.g. export AKS_CLUSTER=myaks)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TAG="${TAG:-latest}"
NAMESPACE="telepresence-demo"

echo "========================================="
echo " Deploying Telepresence Demo"
echo "========================================="
echo " ACR: ${ACR_NAME}.azurecr.io"
echo " AKS Cluster: $AKS_CLUSTER"
echo " Namespace: $NAMESPACE"
echo "========================================="
echo ""

# Ensure AKS can pull from ACR
echo "Verifying AKS-to-ACR pull access..."
ACR_ID=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query id -o tsv)
KUBELET_IDENTITY=$(az aks show --name "$AKS_CLUSTER" --resource-group "$RESOURCE_GROUP" \
    --query identityProfile.kubeletidentity.objectId -o tsv)

if [ -z "$KUBELET_IDENTITY" ]; then
    echo "WARNING: Could not determine kubelet identity. Attaching ACR to AKS..."
    az aks update --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --attach-acr "$ACR_NAME"
else
    # Check if AcrPull role is already assigned
    ROLE_EXISTS=$(az role assignment list --assignee "$KUBELET_IDENTITY" --scope "$ACR_ID" \
        --query "[?roleDefinitionName=='AcrPull']" -o tsv)
    if [ -z "$ROLE_EXISTS" ]; then
        echo "AcrPull role not found. Attaching ACR to AKS..."
        az aks update --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --attach-acr "$ACR_NAME"
        echo "Waiting for role assignment to propagate..."
        sleep 15
    else
        echo "AcrPull role confirmed."
    fi
fi
echo ""

# Create namespace
echo "Creating namespace..."
kubectl apply -f "${PROJECT_DIR}/k8s/namespace.yaml"
echo ""

# Apply manifests with ACR_NAME substituted
echo "Deploying services..."
for MANIFEST in product-api order-api store-front; do
    echo "  Applying $MANIFEST..."
    sed "s/\${ACR_NAME}/${ACR_NAME}/g" "${PROJECT_DIR}/k8s/${MANIFEST}.yaml" | kubectl apply -f -
done
echo ""

# Install Telepresence traffic manager
echo "Installing Telepresence traffic manager..."
if telepresence helm install --namespace "$NAMESPACE" 2>/dev/null; then
    echo "Traffic manager installed."
else
    echo "Traffic manager already installed or install via Helm:"
    echo "  telepresence helm install --namespace $NAMESPACE"
fi
echo ""

# Wait for rollout
echo "Waiting for deployments to be ready..."
for DEPLOY in product-api order-api store-front; do
    kubectl rollout status deployment/"$DEPLOY" -n "$NAMESPACE" --timeout=120s
done
echo ""

echo "Deployment complete. Check status:"
echo "  kubectl get pods -n $NAMESPACE"
