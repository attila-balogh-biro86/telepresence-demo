# Claude Code Multi-Agent Workshop

**Duration:** 30 minutes | **Format:** Instructor-led live demo | **Audience:** Software engineers

## Overview

This workshop demonstrates how Claude Code's multi-agent team feature can parallelize real software engineering work across a microservices codebase. Using a live Spring Boot e-commerce application (3 services), the instructor will show how a team of AI agents can collaboratively implement a cross-cutting feature — working simultaneously on different services, coordinating through a shared task list, and producing a cohesive result.

### What the Audience Will See

- Claude Code spawning a team of specialized agents that work in parallel
- Agents autonomously reading code, making changes, and coordinating with each other
- A cross-cutting feature implemented across 3 microservices in minutes
- Real-time task tracking showing agent progress and dependencies

### The Codebase

| Service | Role | Tech |
|---------|------|------|
| **store-front** | Web UI — displays products, handles orders | Spring Boot MVC + Thymeleaf |
| **product-api** | REST API — serves product catalog | Spring Boot REST |
| **order-api** | REST API — processes orders | Spring Boot REST |

---

## Agenda

| Time | Section | What Happens |
|------|---------|--------------|
| 0:00 | Introduction | Set the stage: the codebase, the problem, why multi-agent |
| 0:05 | Act 1 — Single Agent Baseline | Show Claude Code working on one task (quick context) |
| 0:10 | Act 2 — Multi-Agent Feature Build | Spawn a team to implement a feature across all 3 services |
| 0:22 | Act 3 — Review & Discussion | Walk through the changes, discuss what happened |
| 0:27 | Q&A | Open questions |

---

## Preparation (Before the Workshop)

1. Have the repo cloned and open in a terminal with Claude Code running
2. Ensure all 3 services compile (`mvn compile` in each service directory)
3. Have a second terminal ready to show file diffs (`git diff`)
4. Optional: have VS Code open on the repo so the audience can see file changes live
5. Run `git stash` or commit any pending changes so you start from a clean state

---

## Script

### Introduction (5 min)

**Talking points:**

> "Today I want to show you something that changes how we think about AI-assisted development. Most of you have used coding assistants — Copilot, ChatGPT, maybe Claude. They work on one thing at a time. But real engineering work often spans multiple services, multiple files, multiple concerns — all at once."

Walk through the codebase briefly:

```bash
# Show the project structure
ls services/

# Show what each service does (pick one controller to display)
cat services/product-api/src/main/java/com/example/productapi/controller/ProductController.java
```

> "This is a simple e-commerce app: a store-front that talks to a product-api and an order-api. Three Spring Boot services. Now imagine a real-world scenario: your team lead says 'we need to add product search/filtering across the stack by end of day.' That touches all three services. Let me show you how Claude Code handles this."

---

### Act 1 — Single Agent Baseline (5 min)

Demonstrate a simple single-agent task to establish context and show the audience what "normal" Claude Code looks like.

**Prompt to type:**

```
Look at the three microservices in the services/ folder. Give me a brief architecture summary — how do they communicate, what endpoints exist, what are the models?
```

**What to highlight:**
- Claude reads multiple files across services in parallel
- It understands the inter-service communication (RestTemplate calls, URL configuration)
- It produces a coherent summary of the full architecture

> "This is Claude working as a single agent. It's fast, it's thorough. But watch what happens when we give it a bigger job and let it use a team."

---

### Act 2 — Multi-Agent Feature Build (12 min)

This is the main event. Give Claude a cross-cutting task and instruct it to use a team.

**Prompt to type:**

```
I need you to add a product search feature across all three services. Use a team of agents to work on this in parallel.

Here's what I need:
1. product-api: Add a GET /api/products/search endpoint that accepts a "q" query parameter and filters products by name (case-insensitive contains match)
2. order-api: Add a GET /api/orders endpoint that returns a list of recent orders (just return a hardcoded list of 3 sample orders for now)
3. store-front: Add a search bar to the store page that calls the new product search endpoint, and add an "Order History" link/page that calls the new orders endpoint

Work on all three services simultaneously using a team.
```

**What to narrate while agents work:**

As Claude creates the team and spawns agents, explain what's happening:

> "Watch the top of the screen — Claude is creating a team with a task list. It's breaking down the work into independent tasks and assigning them to specialized agents."

> "Each agent works in its own context. They can read files, write code, run commands — all independently. The team lead coordinates through the shared task list."

> "Notice how the agents working on product-api and order-api don't need to wait for each other — they're truly parallel. But the store-front agent may need to wait for the API contracts to be defined first. Claude handles this dependency automatically."

**Key moments to call out:**
- **Team creation**: "It just created a team with a task list — this is the coordination backbone"
- **Parallel execution**: "Look — three agents are working simultaneously on different services"
- **Task dependencies**: "The store-front work depends on knowing the API shape, so it may read the other services first or wait for those tasks"
- **Completion**: "Each agent marks its task done, and the lead verifies the work"

---

### Act 3 — Review the Changes (5 min)

Once the agents finish, review what was produced.

```bash
# Show all changes made
git diff

# Or more structured:
git diff --stat
```

Walk through the changes service by service:

```bash
# Show the new search endpoint
git diff services/product-api/

# Show the new orders list endpoint
git diff services/order-api/

# Show the UI changes
git diff services/store-front/
```

**Talking points:**

> "In about 5 minutes, a team of agents implemented a feature that touches all three services. Each change is consistent — the store-front calls the exact endpoints that were created in the APIs."

> "Think about how this maps to real engineering work. When you have a feature that spans multiple microservices, you'd normally assign it to multiple developers, have a design meeting, agree on API contracts, then work in parallel with PRs. Claude's multi-agent team compresses that entire workflow."

**Bonus — verify compilation (if time permits):**

```bash
cd services/product-api && mvn compile -q && echo "product-api OK"
cd services/order-api && mvn compile -q && echo "order-api OK"
cd services/store-front && mvn compile -q && echo "store-front OK"
```

---

### Q&A (3 min)

**Anticipated questions and answers:**

**Q: How many agents can run in parallel?**
> There's no hard limit. Claude decides how many to spawn based on the task decomposition. For this demo it used around 3-4, but larger tasks could use more.

**Q: Do the agents share context?**
> Each agent has its own context window. They coordinate through a shared task list and can send messages to each other. The team lead orchestrates the work.

**Q: Can agents review each other's work?**
> Yes. You can set agents to "plan mode" where they must get approval before making changes. The team lead can also spawn reviewer agents.

**Q: How does this compare to running separate Claude sessions?**
> Separate sessions have no coordination — you'd be the integration layer. With teams, Claude manages dependencies, task ordering, and cross-agent communication automatically.

**Q: What about conflicts — can two agents edit the same file?**
> Agents can be isolated using git worktrees so they work on separate branches. For this demo we kept it simple, but in production use you'd enable worktree isolation.

**Q: Does this work with other languages?**
> Absolutely. Claude Code works with any language. The multi-agent feature is language-agnostic — it's about task decomposition and parallel execution.

---

## Backup Scenarios

If something goes wrong or you want to show additional capabilities, here are alternative prompts:

### Alternative 1: Security Audit (read-only, less risky)
```
Use a team to perform a security review of all three services simultaneously. Check for input validation issues, error handling gaps, and potential injection vulnerabilities. Each agent should review one service and report findings.
```

### Alternative 2: Testing Sprint
```
Use a team to add unit tests to all three services in parallel. Each agent should focus on one service and create comprehensive tests for the controllers and models.
```

### Alternative 3: Documentation
```
Use a team to generate API documentation for all three services. Each agent should create an OpenAPI/Swagger specification for one service, and a fourth agent should create a unified architecture document.
```

---

## Key Takeaways (for closing remarks)

1. **Parallel by default** — Multi-agent teams decompose work and execute in parallel, mirroring how real engineering teams operate
2. **Coordinated, not chaotic** — Shared task lists and inter-agent messaging ensure consistency across services
3. **Real code, real tools** — Agents read, write, compile, and test code using the same tools a developer would
4. **Scales with complexity** — The same pattern works for 3 services or 30; for a small feature or a major refactor
