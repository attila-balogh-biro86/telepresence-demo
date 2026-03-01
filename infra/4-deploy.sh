#!/usr/bin/env bash
set -euo pipefail

ACR_NAME="${ACR_NAME:?Set ACR_NAME env var (e.g. export ACR_NAME=myacr)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TAG="${TAG:-latest}"
NAMESPACE="telepresence-demo"

echo "========================================="
echo " Deploying Telepresence Demo"
echo "========================================="
echo " ACR: ${ACR_NAME}.azurecr.io"
echo " Namespace: $NAMESPACE"
echo "========================================="
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
