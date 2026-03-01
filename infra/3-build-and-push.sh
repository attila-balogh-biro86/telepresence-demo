#!/usr/bin/env bash
set -euo pipefail

ACR_NAME="${ACR_NAME:?Set ACR_NAME env var (e.g. export ACR_NAME=myacr)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TAG="${TAG:-latest}"

echo "========================================="
echo " Building and Pushing Docker Images"
echo "========================================="
echo " ACR: ${ACR_NAME}.azurecr.io"
echo " Tag: $TAG"
echo "========================================="
echo ""

# Log in to ACR
echo "Logging in to ACR..."
az acr login --name "$ACR_NAME"
echo ""

SERVICES=("store-front" "product-api" "order-api")

for SERVICE in "${SERVICES[@]}"; do
    echo "--- Building $SERVICE ---"
    docker build \
        --platform linux/amd64 \
        -t "${ACR_NAME}.azurecr.io/${SERVICE}:${TAG}" \
        "${PROJECT_DIR}/services/${SERVICE}"

    echo "--- Pushing $SERVICE ---"
    docker push "${ACR_NAME}.azurecr.io/${SERVICE}:${TAG}"
    echo ""
done

echo "All images built and pushed successfully."
