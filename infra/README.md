# Pre-Workshop Setup Guide

This guide walks through everything needed **before** the workshop. All Azure infrastructure and service deployment must be completed ahead of time so the workshop can focus on demonstrating Telepresence.

---

## 1. Azure Infrastructure Prerequisites

The following Azure resources must be **pre-provisioned** before any workshop setup:

- **Azure Resource Group** — a resource group to contain all workshop resources
- **Azure Kubernetes Service (AKS)** — a running AKS cluster with at least 2 nodes
- **Azure Container Registry (ACR)** — a container registry for storing service images

> If these resources do not exist yet, create them using the Azure Portal or CLI:
>
> ```bash
> # Set your variables
> export RESOURCE_GROUP="my-resource-group"
> export LOCATION="westeurope"
> export AKS_CLUSTER="my-aks-cluster"
> export ACR_NAME="myacr"
>
> # Create resource group
> az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
>
> # Create AKS cluster
> az aks create \
>     --resource-group "$RESOURCE_GROUP" \
>     --name "$AKS_CLUSTER" \
>     --node-count 2 \
>     --generate-ssh-keys \
>     --location "$LOCATION"
>
> # Create ACR
> az acr create \
>     --resource-group "$RESOURCE_GROUP" \
>     --name "$ACR_NAME" \
>     --sku Basic \
>     --location "$LOCATION"
>
> # Grant AKS pull access to ACR
> az aks update \
>     --resource-group "$RESOURCE_GROUP" \
>     --name "$AKS_CLUSTER" \
>     --attach-acr "$ACR_NAME"
> ```

---

## 2. Facilitator Machine — Tool Installation

Install all required tools on the machine that will run the workshop demo.

### Azure CLI

```bash
# macOS
brew install azure-cli

# Verify
az version
```

### kubectl

```bash
# macOS
brew install kubernetes-cli

# Verify
kubectl version --client
```

### Telepresence Client

```bash
# macOS (Homebrew)
brew install datawire/blackbird/telepresence-oss

# Verify
telepresence version
```

> **Apple Silicon note:** If upgrading from a previous install, remove the old binary first:
> ```bash
> sudo rm -f /usr/local/bin/telepresence
> ```

### Docker Desktop

Download and install from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/). Ensure the Docker daemon is running.

```bash
# Verify
docker info
```

### Java 17+ and Maven

```bash
# macOS
brew install openjdk@17 maven

# Verify
java -version
mvn -version
```

### Helm

```bash
# macOS
brew install helm

# Verify
helm version
```

---

## 3. Connect to Azure and AKS

```bash
# Log in to Azure
az login

# Get AKS credentials (merges into ~/.kube/config)
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_CLUSTER"

# Verify cluster connectivity
kubectl get nodes
```

If using a private AKS cluster, ensure your VPN is connected before running `kubectl`.

---

## 4. Set Environment Variables

All subsequent scripts require these variables:

```bash
export RESOURCE_GROUP="my-resource-group"
export ACR_NAME="myacr"
export AKS_CLUSTER="my-aks-cluster"
export LOCATION="westeurope"            # optional, default: westeurope
export TAG="latest"                     # optional, default: latest
```

---

## 5. Verify Prerequisites

Run the verification script to confirm all tools and connectivity:

```bash
./1-verify-prereqs.sh
```

All checks should show `[OK]`. Resolve any `[MISSING]` or `[FAIL]` items before continuing.

---

## 6. Set Up ACR (if not already created)

If ACR was not created in step 1, this script creates it and attaches it to AKS:

```bash
./2-setup-acr.sh
```

> Skip this step if ACR already exists and is attached to AKS.

---

## 7. Build and Push Service Images

Build Docker images for all three services and push them to ACR:

```bash
./3-build-and-push.sh
```

This builds and pushes:
- `store-front` — web UI (Thymeleaf)
- `product-api` — product catalog REST API
- `order-api` — order processing REST API

---

## 8. Install Telepresence Traffic Manager into AKS

The Telepresence Traffic Manager is a cluster-side component that manages intercepts. It must be installed before Telepresence can route traffic to the facilitator's laptop.

```bash
# Install traffic manager into the demo namespace
telepresence helm install --namespace telepresence-demo
```

Verify it is running:

```bash
kubectl get pods -n telepresence-demo | grep traffic-manager
```

You should see a `traffic-manager` pod in `Running` state.

> **Troubleshooting:**
> - If `telepresence helm install` fails, you can install via Helm directly:
>   ```bash
>   helm repo add datawire https://app.getambassador.io
>   helm repo update
>   helm install traffic-manager datawire/telepresence-oss \
>       --namespace telepresence-demo \
>       --create-namespace
>   ```
> - To reinstall, first uninstall: `telepresence helm uninstall --namespace telepresence-demo`

---

## 9. Deploy Services to AKS

Deploy the three microservices into the cluster:

```bash
./4-deploy.sh
```

This script:
1. Creates the `telepresence-demo` namespace
2. Deploys `product-api`, `order-api`, and `store-front`
3. Installs the Telepresence traffic manager (if not already installed)
4. Waits for all deployments to become ready

---

## 10. Verify Deployment

Confirm all pods are running:

```bash
kubectl get pods -n telepresence-demo
```

Expected output — all pods should be `Running` with `1/1` ready:

```
NAME                              READY   STATUS    RESTARTS   AGE
order-api-xxx                     1/1     Running   0          1m
product-api-xxx                   1/1     Running   0          1m
store-front-xxx                   1/1     Running   0          1m
traffic-manager-xxx               1/1     Running   0          1m
```

Test the application via port-forward:

```bash
kubectl port-forward svc/store-front 9090:80 -n telepresence-demo
```

Open `http://localhost:9090` in your browser — you should see the Product Store with a list of products. Stop the port-forward with `Ctrl+C` once verified.

---

## 11. Pre-Cache Maven Dependencies

To avoid slow downloads during the live demo:

```bash
cd services/store-front && mvn dependency:resolve && cd -
```

---

## Summary Checklist

| Step | Action | Verification |
|------|--------|-------------|
| 1 | Azure infra exists (RG, AKS, ACR) | `az aks show`, `az acr show` |
| 2 | Tools installed | `./1-verify-prereqs.sh` — all green |
| 3 | Connected to Azure and AKS | `kubectl get nodes` |
| 4 | Environment variables set | `echo $ACR_NAME $AKS_CLUSTER` |
| 5 | Images built and pushed | `az acr repository list --name $ACR_NAME` |
| 6 | Traffic manager installed | `kubectl get pods -n telepresence-demo \| grep traffic-manager` |
| 7 | Services deployed and running | `kubectl get pods -n telepresence-demo` — all Running |
| 8 | App accessible | Port-forward to `store-front`, products load in browser |
| 9 | Maven deps cached | `mvn dependency:resolve` in `store-front` |

Once all items are green, you are ready to run the workshop using the [Facilitator Guide](../workshop/facilitator-guide.md).

---

## Teardown

After the workshop:

```bash
./5-teardown.sh
```

This removes the demo namespace, all services, and the traffic manager. To also delete the ACR:

```bash
DELETE_ACR=true ./5-teardown.sh
```
