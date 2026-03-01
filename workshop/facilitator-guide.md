# Telepresence Workshop — Facilitator Guide

**Duration:** 30 minutes
**Format:** Facilitator-led live demo (audience watches)
**Goal:** Show the team how Telepresence eliminates the build-push-deploy inner loop

---

## Pre-Workshop Checklist (do this 30 min before)

- [ ] VPN connected, `kubectl get nodes` works
- [ ] Run `infra/1-verify-prereqs.sh` — all green
- [ ] Demo app deployed: `kubectl get pods -n telepresence-demo` — all Running
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

## Quick Reference

| Command | What it does |
|---------|-------------|
| `telepresence connect --docker` | Connect to cluster (VPN-safe) |
| `telepresence status` | Show connection status |
| `curl http://svc.namespace/path` | Access cluster services |
| `telepresence intercept <svc> --port <local>:<remote>` | Route traffic to laptop |
| `telepresence list -n <ns>` | Show available services |
| `telepresence leave <svc>` | Stop intercepting |
| `telepresence quit` | Full disconnect |
