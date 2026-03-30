# 🏗️ Architecture Insights (Open Source)

An open-source [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that helps you understand multi-repo codebases. Trace code paths, investigate production issues, and get design recommendations — all grounded in your actual code, metrics, and incidents.

> Inspired by an internal Microsoft FHL project. This version uses only open-source MCP servers.

## What It Does

| Skill | Trigger | Description |
|-------|---------|-------------|
| **arch-ask** | "How does X work?" | Traces actual code paths across repos, returns call chains with file references |
| **arch-investigate** | "Why is X failing?" | Correlates metrics, code changes, incidents, and deployment history |
| **arch-design** | "How should I design X?" | Finds existing patterns in your codebase and recommends approaches with real code examples |

## Architecture

```
User Question
    │
    ▼
┌──────────────────┐
│ Skill (markdown) │  ← Orchestrator: classifies, routes, synthesizes
└────────┬─────────┘
         │ launches in ONE parallel batch:
    ┌────┴────┬──────────────┬─────────────┐
    ▼         ▼              ▼             ▼
 github-   observability- service-     Inline:
 researcher investigator  resolver     web fetch,
 (code)     (metrics)     (ownership)  GitHub search
    │         │              │             │
    └─────────┴──────────────┴─────────────┘
                      │
               Skill merges results
                      │
                      ▼
                    User
                   Response
```

### MCP Server Stack

| Server | Purpose | Required? |
|--------|---------|-----------|
| **GitHub** (built-in) | Code search, PRs, issues, commits, wiki | ✅ Required |
| **Prometheus/Grafana** | Metrics, dashboards, alerts | ⬜ Optional |
| **PagerDuty** | Incidents, on-call, services | ⬜ Optional |
| **Slack** | Team communication search | ⬜ Optional |
| **Web fetch** (built-in) | External documentation | ✅ Built-in |

The plugin degrades gracefully — if optional servers aren't configured, skills skip those data sources and note what couldn't be checked.

## Quick Start

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- Node.js 18+ (for optional MCP servers)

### 1. Clone

```bash
git clone https://github.com/yyqyang/arch-insights-oss.git ~/.claude/arch-insights-oss
```

### 2. (Optional) Configure Your Services

Edit `services.yaml` to define your organization's services. This enables
smart routing, dependency tracing, and team lookups — but it's **not required**.

Without `services.yaml`, the plugin works in **ad-hoc mode** — it auto-detects
your current repo from `git remote`, infers the language from build files
(`package.json`, `pom.xml`, `go.mod`, etc.), and discovers dependencies from
code artifacts (`docker-compose.yml`, HTTP clients, env vars, import statements).
You get smart routing and dependency tracing either way.

> ⚠️ If you do use `services.yaml`, **replace all instances of `acme-corp`** with your actual GitHub organization name.

```yaml
organization: "acme-corp"  # ← replace with your GitHub org

services:
  api-gateway:
    description: "API gateway / BFF layer"
    language: typescript
    repo: "acme-corp/api-gateway"
    team: "platform"
    dependencies:
      - user-service
      - order-service

  user-service:
    description: "User auth and profiles"
    language: java
    repo: "acme-corp/user-service"
    team: "identity"

feature_areas:
  authentication:
    - user-service
    - api-gateway
  checkout:
    - order-service
    - payment-service
```

### 3. Load the Plugin

```bash
# Load for current session
claude --plugin-dir ~/.claude/arch-insights-oss

# Or install permanently
claude plugin install ~/.claude/arch-insights-oss
```

### 4. (Optional) Configure Additional MCP Servers

Set environment variables for optional integrations:

```bash
# Prometheus / Grafana
export PROMETHEUS_URL="http://localhost:9090"
export GRAFANA_URL="http://localhost:3000"
export GRAFANA_API_KEY="your-api-key"

# PagerDuty
export PAGERDUTY_API_KEY="your-api-key"

# Slack
export SLACK_BOT_TOKEN="xoxb-your-bot-token"
```

## Usage Examples

### Ask Architecture Questions

```
> How does user authentication work?

## User Authentication

### Call Chain
`api-gateway/middleware/auth` → `user-service/auth/validateToken` → `user-service/store/tokenStore`

### Walkthrough
1. **Entry point** — `api-gateway/src/middleware/auth.ts` (L42-58): Extracts JWT from header
2. **Validation** — `user-service/src/auth/TokenValidator.java` (L100-120): Verifies signature
3. **Storage** — `user-service/src/store/TokenStore.java` (L30-45): Checks Redis cache

### Sources
📂 github.com/acme-corp/api-gateway/src/middleware/auth.ts
📂 github.com/acme-corp/user-service/src/auth/TokenValidator.java
```

### Investigate Issues

```
> Why is the order service returning 500 errors?

## Investigation: order-service Error Spike

### Timeline
| Time | Source | Event |
|------|--------|-------|
| 14:00 | GitHub | PR #456 merged: "Update DB connection pool" |
| 14:15 | Prometheus | Error rate spike: 0.1% → 3.2% |
| 14:20 | PagerDuty | Incident triggered: "order-service high error rate" |

### Root Cause Analysis
**Category:** deployment (confidence: High)
**Evidence:** Connection pool change reduced max connections from 50 to 10
```

### Get Design Recommendations

```
> How do other services handle retry logic?

## Retry Patterns in Your Codebase

### Pattern 1: Exponential Backoff (user-service)
📂 `user-service/src/http/RetryPolicy.java` (L15-40)
- Base delay: 100ms, max: 30s, max retries: 3
- Used for: external API calls

### Pattern 2: Circuit Breaker (api-gateway)
📂 `api-gateway/src/resilience/circuitBreaker.ts` (L22-55)
- Failure threshold: 5, reset timeout: 60s
- Used for: downstream service calls

### Recommendation
Use Pattern 1 (exponential backoff) for your use case because...
```

## Plugin Structure

```
arch-insights-oss/
├── .claude-plugin/plugin.json    ← Plugin identity
├── .mcp.json                     ← MCP server wiring (GitHub, Prometheus, PagerDuty, Slack)
├── services.yaml                 ← Your service registry (edit this!)
├── hooks/hooks.json              ← Session startup checks
├── scripts/check-prereqs.sh      ← Prerequisite validator
├── skills/                       ← 3 skills (core AI behaviors)
│   ├── arch-ask/SKILL.md         ← Architecture Q&A
│   ├── arch-investigate/SKILL.md ← Production issue investigation
│   └── arch-design/SKILL.md      ← Design recommendations
├── agents/                       ← 3 sub-agents (parallel data gatherers)
│   ├── github-researcher.md      ← Code search across repos
│   ├── observability-investigator.md ← Metrics & monitoring
│   └── service-resolver.md       ← Ownership & contacts
└── assets/
    └── diagram-templates.md      ← Mermaid diagram templates
```

## Key Design Patterns

| Pattern | Description |
|---------|-------------|
| **Parallel agents** | Launch github-researcher + observability-investigator + service-resolver simultaneously |
| **Graceful degradation** | Skip unavailable MCP servers; always produce partial results |
| **Code-first recommendations** | Never suggest abstract patterns — always point to actual code in the codebase |
| **Structured output** | Source-attributed findings with 📂📊🔔💬📖 icons |
| **Fail-fast** | Auth failures → no retry. 2-3 failed searches → move on |

## Compared to the Internal Version

| Feature | Internal (Viva Engage) | Open Source |
|---------|----------------------|-------------|
| Code search | Bluebird (3 instances) | GitHub MCP Server |
| Telemetry | Azure Data Explorer (Kusto) | Prometheus + Grafana |
| Incidents | ICM | PagerDuty |
| Service catalog | ServiceTree / EngHub | `services.yaml` config |
| Communication | Viva Engage + WorkIQ | Slack |
| Documentation | Microsoft Learn | Web fetch (any URL) |

## Contributing

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Test with `claude --plugin-dir /path/to/your-fork`
5. Submit a PR

### Adding New MCP Integrations

To add a new data source:
1. Add the server config to `.mcp.json`
2. Update the relevant skill SKILL.md to use the new tools
3. Create/update an agent if the new source needs a focused specialist
4. Update `services.yaml` schema if the new source needs per-service config

## License

MIT
