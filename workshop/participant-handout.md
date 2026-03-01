# Telepresence Quick Reference

## What is Telepresence?

Telepresence connects your local dev machine to a remote Kubernetes cluster. You can:

- **Access cluster services** from your laptop (no port-forward needed)
- **Intercept traffic** — route requests from a cluster service to your locally running code
- **Skip the build-push-deploy loop** — edit code, see changes instantly

## Install Prerequisites

### Azure CLI

```bash
brew install azure-cli
az version
```

### kubectl

```bash
brew install kubernetes-cli
kubectl version --client
```

### Telepresence Client

```bash
brew install datawire/blackbird/telepresence-oss
telepresence version
```

### Docker Desktop

Download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) and start the application.

```bash
docker info    # Verify daemon is running
```

### Java 17+ and Maven

```bash
brew install openjdk@17 maven
java -version
mvn -version
```

### Connect to AKS

```bash
az login
az aks get-credentials --resource-group <RESOURCE_GROUP> --name <AKS_CLUSTER>
kubectl get nodes   # Verify connectivity
```

## Key Commands

### 1. Connect to the cluster

```bash
telepresence connect --docker
```

The `--docker` flag avoids VPN/subnet conflicts (recommended for private AKS).

### 2. Access cluster services

```bash
# Short name (within namespace)
curl http://product-api.telepresence-demo/api/products

# Full cluster DNS
curl http://product-api.telepresence-demo.svc.cluster.local/api/products
```

### 3. Intercept a service

```bash
telepresence intercept store-front \
    --namespace telepresence-demo \
    --port 8080:8080
```

Then run the service locally:

```bash
cd services/store-front
mvn spring-boot:run
```

All traffic to `store-front` in the cluster now goes to your local instance.

### 4. Capture environment variables

```bash
telepresence intercept store-front \
    --namespace telepresence-demo \
    --port 8080:8080 \
    --env-file=store-front.env
```

### 5. Clean up

```bash
telepresence leave store-front   # Stop intercept
telepresence quit                # Disconnect entirely
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| DNS not resolving cluster services | Ensure Telepresence connected: `telepresence status`. Try `telepresence quit` then reconnect. |
| VPN conflicts / route errors | Use `--docker` mode. If already using it, restart Docker Desktop. |
| Port already in use | Check `lsof -i :8080` and kill the process, or use a different port. |
| Intercept not receiving traffic | Verify with `telepresence list -n telepresence-demo`. Ensure local service is running on the correct port. |
| `mvn spring-boot:run` fails | Run `mvn dependency:resolve` first. Check Java version: `java -version` (need 17+). |
| Connection timeout | Check VPN is connected: `kubectl get nodes` should work first. |

## How It Works (simplified)

```
Your Laptop                         AKS Cluster
┌──────────────┐                   ┌──────────────────┐
│ Your IDE     │                   │ product-api pod   │
│   + code     │                   │ order-api pod     │
│              │   Telepresence    │                   │
│ store-front  │◄──── tunnel ─────►│ Traffic Manager   │
│ (local)      │                   │   ↕               │
│              │                   │ store-front pod   │
└──────────────┘                   │ (traffic diverted)│
                                   └──────────────────┘
```

1. `telepresence connect` creates a network tunnel to the cluster
2. `telepresence intercept` tells the Traffic Manager to redirect traffic
3. Your local service receives requests as if it were running in the cluster
4. Your local code can call other cluster services by their DNS names

## Links

- [Telepresence Docs](https://www.getambassador.io/docs/telepresence)
- [Quick Start Guide](https://www.getambassador.io/docs/telepresence/latest/quick-start)
- [Telepresence with Docker](https://www.getambassador.io/docs/telepresence/latest/reference/docker-run)

## Demo App Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│ store-front │────►│ product-api  │     │  order-api  │
│   :8080     │     │   :8081      │     │   :8082     │
│ (Thymeleaf) │────────────────────────►│  (REST)     │
└─────────────┘     └──────────────┘     └─────────────┘
     HTML              GET /api/products    POST /api/orders
```

All services are Java Spring Boot. Source code is in `services/`.
