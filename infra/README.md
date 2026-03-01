# Infrastructure Scripts

## Execution Order

Run the scripts in this order:

```
./1-verify-prereqs.sh          # Check all tools and connectivity
./2-setup-acr.sh               # Create Azure Container Registry (one-time)
./3-build-and-push.sh          # Build Docker images and push to ACR
./4-deploy.sh                  # Deploy to AKS + install Telepresence traffic manager
```

To tear everything down:

```
./5-teardown.sh                # Remove demo app, traffic manager, optionally ACR
```

## Required Environment Variables

Set these before running scripts 2–5:

```bash
export RESOURCE_GROUP="my-resource-group"   # Azure resource group
export ACR_NAME="myacr"                     # Azure Container Registry name
export AKS_CLUSTER="my-aks-cluster"         # AKS cluster name
export LOCATION="westeurope"                # Azure region (default: westeurope)
```

Optional:

```bash
export TAG="latest"            # Docker image tag (default: latest)
export DELETE_ACR="true"       # Pass to teardown.sh to also delete ACR
```
