#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

check_command() {
    local cmd="$1"
    local name="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        local version
        version=$("$cmd" --version 2>/dev/null | head -1 || echo "installed")
        echo -e "${GREEN}[OK]${NC} $name: $version"
    else
        echo -e "${RED}[MISSING]${NC} $name is not installed"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "========================================="
echo " Telepresence Workshop - Prerequisite Check"
echo "========================================="
echo ""

echo "--- Required Tools ---"
check_command "az" "Azure CLI"
check_command "kubectl" "kubectl"
check_command "telepresence" "Telepresence"
check_command "docker" "Docker"
check_command "mvn" "Maven"
check_command "java" "Java"
check_command "helm" "Helm"

echo ""
echo "--- Docker Daemon ---"
if docker info &>/dev/null; then
    echo -e "${GREEN}[OK]${NC} Docker daemon is running"
else
    echo -e "${RED}[FAIL]${NC} Docker daemon is not running — start Docker Desktop"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "--- Azure Login ---"
if az account show &>/dev/null; then
    ACCOUNT=$(az account show --query '{name:name, id:id}' -o tsv 2>/dev/null)
    echo -e "${GREEN}[OK]${NC} Logged in to Azure: $ACCOUNT"
else
    echo -e "${RED}[FAIL]${NC} Not logged in to Azure — run 'az login'"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "--- Kubernetes Cluster ---"
if kubectl cluster-info &>/dev/null; then
    CONTEXT=$(kubectl config current-context 2>/dev/null)
    echo -e "${GREEN}[OK]${NC} Connected to cluster: $CONTEXT"
else
    echo -e "${RED}[FAIL]${NC} Cannot reach Kubernetes cluster — check VPN and kubeconfig"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "--- VPN Connectivity (optional check) ---"
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || echo "")
if [ -n "$CLUSTER_SERVER" ]; then
    HOST=$(echo "$CLUSTER_SERVER" | sed -e 's|https\?://||' -e 's|:.*||')
    if curl -sk --connect-timeout 3 "$CLUSTER_SERVER/healthz" &>/dev/null; then
        echo -e "${GREEN}[OK]${NC} API server reachable: $HOST"
    else
        echo -e "${YELLOW}[WARN]${NC} API server may not be reachable: $HOST (VPN connected?)"
    fi
else
    echo -e "${YELLOW}[WARN]${NC} Could not determine cluster API server"
fi

echo ""
echo "========================================="
if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}$ERRORS issue(s) found. Please resolve before proceeding.${NC}"
    exit 1
else
    echo -e "${GREEN}All prerequisites met. Ready to go!${NC}"
fi
