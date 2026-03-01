#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="telepresence-demo"

echo "========================================="
echo " Tearing Down Telepresence Demo"
echo "========================================="
echo ""

# Disconnect Telepresence if connected
echo "Disconnecting Telepresence..."
telepresence quit 2>/dev/null || true
echo ""

# Uninstall traffic manager
echo "Removing Telepresence traffic manager..."
telepresence helm uninstall --namespace "$NAMESPACE" 2>/dev/null || true
echo ""

# Delete namespace (removes all demo resources)
echo "Deleting namespace '$NAMESPACE'..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found
echo ""

# Optionally delete ACR
if [ "${DELETE_ACR:-false}" = "true" ]; then
    RESOURCE_GROUP="${RESOURCE_GROUP:?Set RESOURCE_GROUP to delete ACR}"
    ACR_NAME="${ACR_NAME:?Set ACR_NAME to delete ACR}"
    echo "Deleting ACR '$ACR_NAME'..."
    az acr delete --resource-group "$RESOURCE_GROUP" --name "$ACR_NAME" --yes
    echo ""
fi

echo "Teardown complete."
