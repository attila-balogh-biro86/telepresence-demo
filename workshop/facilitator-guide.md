# Telepresence Workshop — Facilitator Guide

**Duration:** 30 minutes
**Format:** Facilitator-led live demo (audience watches)
**Goal:** Show the team how Telepresence eliminates the build-push-deploy inner loop

---

## Prerequisites

All infrastructure and tooling must be set up **before** the workshop. Follow the [Pre-Workshop Setup Guide](../infra/README.md) to complete these steps:

1. **Azure infrastructure pre-provisioned:** Resource Group, AKS cluster, and ACR
2. **Tools installed on facilitator machine:** Azure CLI, kubectl, Telepresence client, Docker Desktop, Java 17+, Maven, Helm
3. **Connected to Azure and AKS:** `az login` done, kubeconfig merged
4. **Service images built and pushed** to ACR
5. **Telepresence traffic manager installed** into the AKS cluster
6. **Demo services deployed** to the `telepresence-demo` namespace

---

## Pre-Workshop Checklist (do this 30 min before)

- [ ] VPN connected, `kubectl get nodes` works
- [ ] Run `infra/1-verify-prereqs.sh` — all green
- [ ] Demo app deployed: `kubectl get pods -n telepresence-demo` — all Running (including `traffic-manager`)
- [ ] `store-front` accessible via port-forward: `kubectl port-forward svc/store-front 9090:80 -n telepresence-demo` — open browser to `http://localhost:9090`, confirm product list loads
- [ ] Stop the port-forward (you'll use Telepresence instead during the demo)
- [ ] Terminal font size large enough for audience to read
- [ ] `services/store-front/` open in your IDE, ready to edit `index.html`
- [ ] Maven dependencies pre-downloaded: `cd services/store-front && mvn dependency:resolve`
- [ ] Docker Desktop running

---

## Section 1 — The Problem (0:00 – 5:00)

### Talk Track

> "Raise your hand if you've ever waited 5+ minutes for a code change to reach the cluster.
>
> Here's the typical inner loop for our private AKS setup:
> 1. Edit code
> 2. `mvn package` — 30 seconds
> 3. `docker build` — 1 minute
> 4. `docker push` to ACR — 1 minute
> 5. `kubectl rollout restart` — 2 minutes to pull and start
>
> That's ~5 minutes per iteration. If you do this 20 times a day, that's nearly **2 hours** just waiting. And that's the optimistic scenario.
>
> Today I'll show you how to cut that to **zero** with Telepresence."

### Demo: Show the running app

```bash
kubectl get pods -n telepresence-demo
```

> "Here are our three microservices running in the cluster — store-front, product-api, and order-api."

```bash
kubectl port-forward svc/store-front 9090:80 -n telepresence-demo &
```

Open browser to `http://localhost:9090`.

> "This is the store-front. It fetches products from product-api and lets you place orders via order-api. Standard microservices setup."

Stop the port-forward:

```bash
kill %1
```

---

## Section 2 — Connect & Explore (5:00 – 13:00)

### Talk Track

> "Telepresence creates a two-way network tunnel between your laptop and the cluster. Let me show you."

### Demo: Connect

```bash
telepresence connect --docker
```

> "The `--docker` flag is important — it runs the networking inside a Docker container, so there's no conflict with our VPN. This is the recommended mode for private clusters."

Wait for "Connected to context ..." message.

### Demo: Cluster DNS from your laptop

```bash
curl http://product-api.telepresence-demo/api/products
```

> "I just curled a Kubernetes service name — from my laptop terminal. No port-forward, no ingress. Telepresence gives my laptop direct access to the cluster network."

```bash
curl http://product-api.telepresence-demo.svc.cluster.local/api/products
```

> "Full DNS names work too. This means your local code can call cluster services using the same URLs it uses when deployed — no config changes needed."

### If it fails

> If DNS doesn't resolve, try:
> ```bash
> telepresence status
> ```
> Check that the connection is active. If not, `telepresence quit` and retry without `--docker` as a fallback.

---

## Section 3 — Live Intercept Demo (13:00 – 25:00)

### Talk Track

> "Now for the powerful part. I want to make a change to the store-front and see it live — without building or pushing anything."

### Step 1: Start the intercept

```bash
telepresence intercept store-front --namespace telepresence-demo --port 8080:8080
```

> "This tells Telepresence: take all traffic that would go to the store-front pod, and send it to port 8080 on my laptop instead."

### Step 2: Run store-front locally

Open a **new terminal tab**.

```bash
cd services/store-front
mvn spring-boot:run
```

> "I'm running the store-front locally with `mvn spring-boot:run`. Spring DevTools is included, so any file change triggers an automatic reload."

Wait for "Started StoreFrontApplication" in the log.

### Step 3: Show it works via the intercept

Open browser to `http://localhost:8080`.

> "My local store-front is now serving traffic. It talks to product-api and order-api in the cluster — because Telepresence gives it network access. Let me prove it: here are the products, loaded from the cluster's product-api."

### Step 4: Make a visible change

Open `services/store-front/src/main/resources/templates/index.html` in your IDE.

Find the banner section:
```html
<h1>Product Store</h1>
<p>Browse our selection of developer accessories</p>
```

Change it to:
```html
<h1>Product Store v2 — Live from my laptop!</h1>
<p>Changed in real-time with Telepresence</p>
```

> "I've changed the banner text. Watch what happens..."

Wait 2-3 seconds for Spring DevTools to reload, then refresh the browser.

> "And there it is. The banner changed instantly. No `mvn package`, no `docker build`, no `docker push`, no waiting for the pod to restart. This is the power of Telepresence."

### Step 5: (Optional) Change the banner style

For extra impact, also change the banner background color:

```html
<div class="banner" style="background: linear-gradient(135deg, #e74c3c, #f39c12);">
```

> "I can also change the styling — this is now a red/orange gradient instead of blue. Refresh... instant."

### If `mvn spring-boot:run` fails

> Pre-warm: before the demo, run `mvn dependency:resolve` in the store-front directory.
> If port 8080 is busy: `SERVER_PORT=8080 mvn spring-boot:run` or check for leftover processes.

### If the intercept doesn't work

> Check:
> ```bash
> telepresence list --namespace telepresence-demo
> ```
> The store-front should show as "intercepted". If not, `telepresence leave store-front` and retry.

---

## Section 4 — Cleanup & Q&A (25:00 – 30:00)

### Demo: Clean up

```bash
telepresence leave store-front
```

> "I've released the intercept. Traffic goes back to the cluster version."

Refresh browser — original "Product Store" banner is back.

```bash
telepresence quit
```

> "And now I've fully disconnected. My laptop is back to normal."

Stop `mvn spring-boot:run` with Ctrl+C.

### Talk Track: Adoption Paths

> "So what can you do with this?
>
> 1. **`telepresence connect --docker`** — Just network access. Curl cluster services, run integration tests against real dependencies.
> 2. **`telepresence intercept <service>`** — Route live traffic to your laptop. Develop and debug with real cluster data.
>
> The `--docker` flag avoids VPN conflicts, which is key for our private AKS setup.
>
> You have a handout with install instructions, key commands, and troubleshooting tips. Try it yourself!"

### Anticipated Questions

**Q: Does this work with our VPN?**
> Yes — the `--docker` flag isolates Telepresence networking in a Docker container, avoiding VPN subnet conflicts.

**Q: Can multiple developers intercept the same service?**
> Yes, with personal intercepts. Each developer gets a unique intercept filtered by a header. This requires the Ambassador extension but is supported.

**Q: Does this affect other team members?**
> A basic intercept routes ALL traffic to your laptop — during the demo, others would see your version. Personal intercepts (header-based) avoid this. For development, coordinate with your team.

**Q: What about environment variables and secrets?**
> Telepresence can inject the pod's environment variables into your local process. Use `telepresence intercept --env-file=.env` to capture them.

**Q: Performance impact?**
> Minimal. The traffic manager is lightweight. Your service handles requests at local speed. Network latency depends on VPN but is typically <50ms.

---

## Telepresence Command Reference

### Installation & Setup

```bash
# Install Telepresence on macOS
brew install datawire/blackbird/telepresence-oss

# Install Telepresence on Linux (amd64)
sudo curl -fL https://app.getambassador.io/download/tel2oss/releases/download/v2.27.0/telepresence-linux-amd64 \
  -o /usr/local/bin/telepresence && sudo chmod +x /usr/local/bin/telepresence

# Verify installation
telepresence version
```

### Starting the Daemon & Connecting

```bash
# Start Telepresence and connect to the current kubectl context
telepresence connect

# Connect in Docker mode (recommended for VPN/corporate networks)
telepresence connect --docker

# Connect to a specific namespace
telepresence connect --namespace telepresence-demo

# Check connection status
telepresence status

# Check the cluster-side traffic manager
telepresence helm install              # install traffic manager
telepresence helm upgrade              # upgrade traffic manager
telepresence helm uninstall            # remove traffic manager
```

### Listing & Inspecting Services

```bash
# List all interceptable services in the connected namespace
telepresence list

# Access a cluster service directly from your laptop
curl http://product-api.telepresence-demo/api/products

# Full DNS also works
curl http://product-api.telepresence-demo.svc.cluster.local/api/products
```

### Intercepting Services

```bash
# Intercept a service — route cluster traffic to your local port
telepresence intercept store-front --port 8080:80

# Intercept with environment variable export
telepresence intercept store-front --port 8080:80 --env-file store-front.env

# Intercept with Docker run (runs your local container with cluster networking)
telepresence intercept store-front --port 8080:80 --docker-run -- -it myimage:latest

# Check active intercepts
telepresence list

# Leave (stop) an intercept
telepresence leave store-front
```

### Debugging & Logs

```bash
# Check Telepresence daemon status and connection details
telepresence status

# View Telepresence daemon logs
telepresence gather-logs          # creates a zip file with all logs

# Check traffic manager logs in the cluster
kubectl logs deployment/traffic-manager -n telepresence-demo

# Check traffic agent sidecar logs on an intercepted pod
kubectl logs deployment/store-front -c traffic-agent -n telepresence-demo

# Verify the traffic agent was injected into a pod
kubectl describe pod -l app=store-front -n telepresence-demo | grep traffic-agent

# Test DNS resolution (macOS — do NOT use dig, it bypasses Telepresence DNS)
dscacheutil -q host -a name product-api.telepresence-demo

# Test DNS resolution (Linux)
curl -s http://product-api.telepresence-demo/api/products
```

### Disconnecting & Cleanup

```bash
# Stop all intercepts and disconnect
telepresence quit

# Force quit (if daemon is unresponsive)
telepresence quit --force

# Uninstall traffic agent from a workload
telepresence uninstall store-front

# Uninstall all traffic agents
telepresence uninstall --all-agents
```

### Quick Reference Table

| Command | What it does |
|---------|-------------|
| `telepresence connect --docker` | Connect to cluster (VPN-safe) |
| `telepresence connect` | Connect to cluster (direct mode) |
| `telepresence status` | Show connection status |
| `curl http://svc.namespace/path` | Access cluster services from laptop |
| `telepresence intercept <svc> --port <local>:<remote>` | Route traffic to laptop |
| `telepresence intercept <svc> --env-file .env` | Intercept and capture env vars |
| `telepresence list` | Show available/intercepted services |
| `telepresence leave <svc>` | Stop intercepting a service |
| `telepresence quit` | Full disconnect |
| `telepresence gather-logs` | Collect all logs for debugging |
| `telepresence helm install` | Install traffic manager in cluster |

---

## Q&A: Common Technical Questions

### General

**Q: What exactly does Telepresence install in my cluster?**
> It installs a **Traffic Manager** deployment in your namespace. When you intercept a service, it also injects a **traffic-agent** sidecar container into the target pod. The traffic-agent intercepts incoming traffic and routes it to your laptop via the Traffic Manager. When you leave the intercept, the sidecar is removed automatically.

**Q: Does Telepresence modify my deployments permanently?**
> No. The traffic-agent sidecar is injected dynamically and removed when you leave the intercept or run `telepresence uninstall`. Your original deployment YAML is not modified.

**Q: Can I intercept multiple services at the same time?**
> Yes. You can run multiple `telepresence intercept` commands for different services. Each will route to a different local port. This is useful when you're working on a service that depends on another service you also want to run locally.

**Q: Does this work with any language/framework?**
> Yes. Telepresence operates at the network level. It doesn't care what language or framework your service uses. If it listens on a TCP port, it can be intercepted.

**Q: What is the `--docker` flag and when should I use it?**
> `--docker` runs the Telepresence daemon inside a Docker container with its own network namespace. This completely isolates Telepresence networking from your host, preventing conflicts with VPNs, corporate proxies, or other network tools. Use it whenever you're on a corporate network or VPN.

---

### VPN & Corporate Network

**Q: Our cluster is only accessible via VPN. Will Telepresence work?**
> Yes, but you need to handle potential subnet conflicts. When your VPN and cluster use overlapping IP ranges (common with RFC 1918 addresses like 10.x.x.x), Telepresence may fail to route correctly. Three solutions:
>
> 1. **Docker mode (recommended):** `telepresence connect --docker` — isolates all Telepresence networking in a container, avoiding VPN conflicts entirely.
> 2. **VNAT (automatic):** Telepresence 2.21+ automatically resolves conflicts by translating cluster IPs to non-conflicting virtual addresses. Use `telepresence connect --vnat all` to enable for all subnets.
> 3. **Allow conflicting subnets:** If you understand your network topology, configure `allowConflictingSubnets` in `~/.config/telepresence/config.yml` to explicitly allow overlapping ranges.

**Q: I connected but DNS resolution doesn't work. Services are unreachable.**
> Common causes:
> - **VPN intercepts DNS:** Your VPN may be capturing all DNS queries. Use `--docker` mode to isolate DNS.
> - **Missing namespace in URL:** Without an active intercept, you must use fully qualified names: `service-name.namespace` (e.g., `product-api.telepresence-demo`), not just `product-api`.
> - **macOS dig doesn't work:** On macOS, `dig` and `nslookup` bypass Telepresence DNS. Use `curl` or `dscacheutil -q host -a name <service>` instead.

**Q: My VPN drops when I run `telepresence connect`. What do I do?**
> This happens when Telepresence modifies your routing table in a way that conflicts with the VPN. Solutions:
> - Use `telepresence connect --docker` to avoid modifying host routes entirely.
> - If you can't use Docker mode, use `--proxy-via CIDR=WORKLOAD` to route specific subnets through a cluster workload instead of modifying host routes.

**Q: Can I use Telepresence if the cluster API server is only reachable via VPN?**
> Yes. Keep your VPN connected and ensure `kubectl` works first. Then run `telepresence connect --docker`. The Docker container will use your host's network (including VPN) to reach the API server, while keeping Telepresence's virtual network isolated.

**Q: Does Telepresence work behind a corporate HTTP proxy?**
> Telepresence uses gRPC and direct TCP connections to the cluster, not HTTP. Corporate HTTP proxies typically don't interfere because `kubectl` access (which must already work) handles the API server connection. If your proxy blocks non-HTTP traffic on certain ports, you may need proxy exceptions for the Telepresence port ranges.

---

### Developer Workflow Scenarios

**Q: I changed my code but the intercept still shows the old version. Why?**
> The intercept routes traffic to your local port — you need a local process running. Make sure:
> 1. Your service is actually running locally (e.g., `mvn spring-boot:run`).
> 2. It's listening on the correct port (the `--port` local port you specified).
> 3. If using Spring DevTools or hot-reload, wait a few seconds for the reload to complete.
> 4. Hard-refresh your browser (`Ctrl+Shift+R`) to bypass caching.

**Q: My local service can't reach other services in the cluster.**
> Check that `telepresence status` shows "Connected". Your local process should be able to reach cluster services via their Kubernetes DNS names (e.g., `http://product-api.telepresence-demo/api/products`). If DNS fails, try the full FQDN: `http://product-api.telepresence-demo.svc.cluster.local`.

**Q: Can I debug my intercepted service with a debugger (IntelliJ, VS Code)?**
> Absolutely — this is one of the biggest benefits. Start your service locally in debug mode:
> - **IntelliJ:** Run your Spring Boot app with the Debug button.
> - **VS Code:** Use your language's debug launch configuration.
>
> Set breakpoints, and when traffic from the cluster hits your intercepted service, the debugger will pause on them. You're debugging with real cluster traffic and dependencies.

**Q: How do I get the environment variables and secrets that the pod has?**
> Use the `--env-file` flag when intercepting:
> ```bash
> telepresence intercept store-front --port 8080:80 --env-file store-front.env
> ```
> This writes all pod environment variables to `store-front.env`. You can then source them:
> ```bash
> export $(cat store-front.env | xargs)
> mvn spring-boot:run
> ```
> Or configure your IDE to load the env file.

**Q: My intercept works but the app crashes because it can't find mounted volumes or ConfigMaps.**
> Telepresence can mount remote volumes locally. By default it tries to mount them using `sshfs`. Ensure `sshfs` is installed:
> - **macOS:** `brew install gromgit/fuse/sshfs-mac`
> - **Linux:** `sudo apt install sshfs` and uncomment `user_allow_other` in `/etc/fuse.conf`
>
> If volume mounting isn't needed, disable it: `telepresence intercept store-front --port 8080:80 --mount=false`.

**Q: Two developers want to work on the same service simultaneously. Is that possible?**
> A standard intercept routes **all** traffic to one developer's laptop, which blocks others. Options:
> - **Coordinate:** Only one developer intercepts at a time. Others work on different services.
> - **Personal intercepts (header-based):** Route only requests with a specific HTTP header to your laptop. Other traffic continues to the cluster. This requires a paid Telepresence license.
> - **Use separate namespaces:** Deploy the service to a personal namespace and intercept there.

**Q: I accidentally left an intercept running. How do I clean up?**
> ```bash
> telepresence leave store-front     # leave specific intercept
> telepresence quit                  # disconnect entirely
> ```
> If the daemon is stuck:
> ```bash
> telepresence quit --force
> ```
> If the traffic-agent sidecar is stuck in a pod:
> ```bash
> telepresence uninstall store-front
> kubectl rollout restart deployment/store-front -n telepresence-demo
> ```

**Q: Will my intercept survive a VPN reconnection?**
> Usually no. If your VPN drops and reconnects, the Telepresence connection often breaks. You'll need to:
> ```bash
> telepresence quit
> telepresence connect --docker
> telepresence intercept store-front --port 8080:80
> ```
> Your local service can keep running — you just need to re-establish the tunnel.

**Q: Can I use Telepresence in CI/CD pipelines for integration testing?**
> Yes, but with caveats. In CI environments (GitHub Actions, GitLab CI):
> - DNS may require manual configuration. In Docker-based CI, replace `/etc/resolv.conf` contents with `nameserver 127.0.0.1`.
> - Use `telepresence connect` (not `--docker`) since you're already in a container.
> - Ensure the CI runner has `kubectl` access to the cluster.
> - Clean up intercepts in your pipeline's teardown step.

**Q: What happens to other users' traffic when I intercept a service?**
> With a **global intercept** (the default), **all traffic** to that service routes to your laptop. Other team members hitting that service will see your local version. This is fine for development clusters but dangerous for shared/staging environments. Coordinate with your team, or use personal intercepts with header-based routing.

**Q: I'm getting "traffic-manager not found" errors.**
> The traffic manager needs to be installed in the cluster:
> ```bash
> telepresence helm install
> ```
> If it's already installed but in a different namespace, specify it:
> ```bash
> telepresence helm install --namespace telepresence-demo
> ```
> Verify it's running:
> ```bash
> kubectl get pods -n telepresence-demo | grep traffic-manager
> ```

**Q: My service uses gRPC/WebSockets, not HTTP. Does Telepresence support that?**
> Yes. The default intercept mechanism is TCP-based, so it works with any protocol: HTTP, gRPC, WebSockets, raw TCP, etc. Protocol-specific features like header-based routing (personal intercepts) only work with HTTP/gRPC, but basic intercepts work with everything.
