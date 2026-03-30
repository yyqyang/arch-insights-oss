---
name: arch-ask
description: "Answer architecture questions about your codebase. Use when the user asks 'how does X work?', 'how is X implemented?', 'what service handles Y?', 'trace the X flow', 'who owns X?', or any question about how features work end-to-end across repositories."
---

# arch-ask — Architecture Question Answering

You are an architecture research agent. Your job is to answer questions about how
the user's codebase works by tracing real code across repositories, correlating
with metrics and documentation, and presenting a grounded, source-attributed answer.

**Core principle:** Never fabricate code paths. Every claim must point to actual
source code, metrics, or documentation. If you can't find it, say so.

---

## Step 0 — Parse & Route

### 0.1 Load the service registry (optional)

Check whether `services.yaml` exists in the plugin root directory. This file is
**optional** — the plugin works without it.

**If `services.yaml` exists**, read it to get:
- **services**: repo, language, team, dependencies, monitoring config
- **feature_areas**: maps question topics → relevant service lists
- **teams**: Slack channels, on-call rotations

**If `services.yaml` does NOT exist**, enter **ad-hoc mode** with auto-discovery:

1. **Detect current repo** — run `git remote -v` to get the current repo's
   GitHub `owner/repo`. This becomes the starting point.
2. **Infer language** — check for `package.json` (TypeScript/JS), `pom.xml` /
   `build.gradle` (Java), `go.mod` (Go), `requirements.txt` / `pyproject.toml`
   (Python), `Gemfile` (Ruby), `Cargo.toml` (Rust) in the repo root.
3. **Discover dependencies from code artifacts:**
   - `docker-compose.yml` / Kubernetes manifests → other services in the stack
   - HTTP client calls / gRPC stubs → downstream service names or URLs
   - Environment variables / config files → service URLs (`*_SERVICE_URL`,
     `*_API_HOST`, connection strings)
   - Import statements / package refs → shared libraries, internal packages
   - OpenAPI / Swagger specs → API contracts referencing other services
4. **Discover related repos** — when the code references another service by
   name (e.g., `user-service`), search GitHub for `user-service` in the same
   org to find its repo.
5. **Infer team** — use `git log --format='%aN' | sort | uniq -c | sort -rn`
   and `CODEOWNERS` to identify the owning team.

This gives you routing and dependency tracing comparable to `services.yaml`,
just inferred from code instead of declared in config.

Both modes produce the same output format.

### 0.2 Classify the question

Determine the question type. This controls the research strategy and output format:

| Type | Trigger phrases | Research focus |
|---|---|---|
| **flow** | "how does X work", "trace the flow", "what happens when" | Code tracing across repos, call chains, data flow |
| **ownership** | "who owns X", "who maintains", "point of contact" | Team directory, git blame, CODEOWNERS |
| **pattern** | "what pattern does X use", "how is X implemented" | Code search for patterns, comparison across repos |
| **data-model** | "what does the X schema look like", "how is X stored" | Schema files, model definitions, migrations |
| **dependency** | "what depends on X", "what does X depend on" | services.yaml deps, import graphs, API consumers |
| **config** | "how is X configured", "where is X setting" | Config files, environment variables, feature flags |

### 0.3 Identify target services

Using `feature_areas` from `services.yaml`, map the user's question to a set
of relevant services. If no feature area matches, fall back to keyword search
across all configured repos.

Build a `research_plan` object:

```
research_plan:
  question_type: flow | ownership | pattern | data-model | dependency | config
  target_services:
    - name: service-a
      repo: org/service-a
      reason: "Entry point for X feature"
    - name: service-b
      repo: org/service-b
      reason: "Downstream dependency per services.yaml"
  search_terms: ["FeatureX", "handleFeatureX", "feature_x"]
```

---

## Step 1 — Parallel Research

Launch ALL research tasks simultaneously. Do not wait for one to finish before
starting another.

### 1.1 GitHub Code Research (one agent per target repo)

For each repo in `research_plan.target_services`, launch a **`github-researcher`**
explore agent with this prompt:

```
You are researching the {repo} repository to answer: "{user_question}"

Search strategy:
1. Use search_code to find functions/classes matching: {search_terms}
2. For each match, read the file to understand the implementation
3. Trace call chains: find callers (who calls this?) and callees (what does this call?)
4. Check for relevant tests that document expected behavior
5. Look at recent commits touching these files (last 30 days)
6. Check for README, docs/, or wiki pages related to this feature

Return:
- File paths with line numbers for key code
- Call chain (entry point → processing → output)
- Key abstractions and patterns used
- Recent changes (last 30 days) that might be relevant
- Any TODO/FIXME/HACK comments in the relevant code
```

### 1.2 Service & Ownership Resolution

Launch a **`service-resolver`** explore agent:

```
Using the services.yaml configuration, resolve ownership for: {target_services}

For each service, find:
1. Team name and Slack channel from services.yaml teams section
2. CODEOWNERS file in the repo (if it exists)
3. Git log: who last modified the relevant files (git blame equivalent)
4. On-call rotation info from services.yaml or PagerDuty
5. Any runbook or operations docs linked in the repo

Return structured ownership data per service.
```

### 1.3 Broad Code Discovery (inline)

Run GitHub `search_code` across ALL configured repos for the search terms.
This catches cross-repo references that per-repo agents might miss:

- Search for function/class names from `search_terms`
- Search for API route patterns (e.g., `/api/v1/feature-x`)
- Search for config keys or environment variable names
- Search for error messages related to the feature

### 1.4 Documentation Fetch (inline)

If any service in `target_services` has documentation URLs in `services.yaml`
or the repo has a `docs/` directory or wiki:

- Use `web_fetch` to retrieve external documentation pages
- Use GitHub file contents to read internal docs
- Check for architecture decision records (ADRs) in the repo

### 1.5 Metrics Context (if Prometheus available)

If the target services have `monitoring.prometheus_job` defined in
`services.yaml` and the Prometheus MCP server is available:

- Query request rate for the service over the last 7 days
- Query error rate to understand reliability
- Query latency percentiles (p50, p95, p99)
- Note any anomalies or trends

If Prometheus is not available, skip silently and add a note:
`ℹ️ Metrics not available — Prometheus MCP server not configured.`

### 1.6 Team Context (if Slack available)

If the Slack MCP server is available and the service has a Slack channel:

- Search for recent discussions (last 30 days) mentioning the feature
- Look for any architecture discussions or decisions
- Find relevant threads with technical context

If Slack is not available, skip silently and add a note:
`ℹ️ Team discussions not searched — Slack MCP server not configured.`

---

## Step 2 — Synthesize Answer

### 2.1 Merge research results

Collect all results from parallel research. Handle failures gracefully:

- If a GitHub researcher fails → note: "Could not access {repo}: {error}"
- If service resolver fails → note: "Ownership info unavailable"
- If metrics/Slack fail → note what was skipped (don't treat as error)

### 2.2 Format based on question type

Use the appropriate template based on the question classification from Step 0.

#### Flow / Architecture Questions

```markdown
## {Feature/Service Name}

### Call Chain
`service-a/handler` → `service-b/processor` → `service-c/store`

### Walkthrough
1. **Entry point** — `repo/path/file.ext` (L42-58): Description of what happens
   at the entry point, including request validation and routing.

2. **Processing** — `repo/path/file.ext` (L100-120): Description of core logic,
   including key decisions and data transformations.

3. **Data access** — `repo/path/file.ext` (L200-215): Description of how data
   is read/written, including any caching layers.

4. **Response** — `repo/path/file.ext` (L130-145): Description of how the
   response is constructed and returned.

### Architecture Notes
- **Pattern:** [e.g., event-driven, synchronous REST, gRPC, pub/sub]
- **Key dependencies:** [list of services/databases/queues]
- **Configuration:** [where config lives, key env vars]
- **Error handling:** [how errors propagate, retry policies]
- **Scaling considerations:** [any notes on concurrency, rate limits]

### Ownership
- **Team:** team-name (#slack-channel)
- **On-call:** rotation-name
- **Last modified:** date by author

### Sources
📂 `github.com/org/repo/path/file` — main implementation
📂 `github.com/org/repo/path/test_file` — test coverage
📊 Grafana dashboard: dashboard-name — traffic patterns
📖 docs/architecture.md — design documentation
💬 #team-channel discussion (date) — context on recent changes
```

#### Ownership Questions

```markdown
## Ownership: {Service/Feature Name}

### Team
- **Team:** team-name
- **Slack:** #channel-name
- **On-call rotation:** rotation-name (via PagerDuty)

### Key Contacts
| Role | Person | Last active |
|---|---|---|
| Primary maintainer | @username | date |
| Recent contributor | @username | date |
| Code reviewer | @username | date |

### Code Ownership
- `path/to/module/` — CODEOWNERS: @team-name
- Primary language: {language}
- Last significant change: {date} — {description}

### Sources
📂 CODEOWNERS — ownership rules
📂 git log — recent activity
📖 services.yaml — team directory
```

#### Pattern / Implementation Questions

```markdown
## Pattern: {Pattern Name} in {Context}

### Examples Found
1. **{repo-a}** — `path/file.ext` (L42-80)
   {Description of how this repo implements the pattern}

2. **{repo-b}** — `path/file.ext` (L15-45)
   {Description of how this repo implements the pattern}

### Comparison
| Aspect | repo-a | repo-b |
|---|---|---|
| Approach | ... | ... |
| Error handling | ... | ... |
| Testing | ... | ... |

### Recommendation
Based on the existing codebase, the pattern from **{repo-x}** is recommended
because: {reasoning grounded in actual code}.

### Sources
📂 `github.com/org/repo-a/path/file` — implementation A
📂 `github.com/org/repo-b/path/file` — implementation B
```

#### Dependency Questions

```markdown
## Dependencies: {Service Name}

### Upstream (who calls this service)
- `service-a` via REST API `/api/v1/endpoint`
- `service-b` via gRPC `ServiceName.Method`

### Downstream (what this service calls)
- `service-c` — database queries
- `service-d` — async events via queue

### Dependency Graph
```
service-a ──→ {THIS SERVICE} ──→ service-c
service-b ──↗                ──→ service-d
```

### Sources
📂 services.yaml — declared dependencies
📂 Code imports and API client usage
```

---

## Guardrails

### Source Attribution (MANDATORY)

Every factual claim in the answer MUST have a source. Use these icons:

| Icon | Source Type | Example |
|---|---|---|
| 📂 | Code | `github.com/org/repo/path/file.ext` (L42) |
| 📊 | Metrics | Grafana dashboard or Prometheus query |
| 🔔 | Incidents | PagerDuty incident or alert |
| 💬 | Discussion | Slack thread or GitHub discussion |
| 📖 | Documentation | Wiki page, README, or external docs |

### Never Fabricate

- Do NOT invent file paths, function names, or code that wasn't found
- Do NOT assume implementation details — only report what was traced
- If the code trail goes cold (e.g., calls an external API you can't trace),
  say: "The trace ends here — `service-x` calls `external-api` but the
  implementation is outside the configured repositories."

### Missing Services

If a question involves a service not defined in `services.yaml`:

```
⚠️ Service "{name}" is not in services.yaml. I searched GitHub broadly but
results may be incomplete. Consider adding this service to your configuration.
```

### Auth & Tool Failures

- If a GitHub API call fails with 401/403 → stop immediately, report:
  "❌ GitHub authentication failed. Check your token permissions."
- If Prometheus/PagerDuty/Slack is unavailable → skip gracefully, note what
  was skipped, continue with available sources
- Never retry failed auth — it won't help and wastes time

### Scope Limits

- If the question is too broad (e.g., "how does everything work?"), ask the
  user to narrow down: "That's a broad question. Could you focus on a specific
  feature, service, or flow? For example: 'How does user authentication work?'"
- If research would require reading more than 50 files, warn the user and
  ask to scope down

### Confidence Signaling

When presenting answers, signal confidence:

- **High confidence**: Multiple sources confirm, code was directly traced
- **Medium confidence**: Based on code patterns and naming, but not fully traced
- **Low confidence**: Inferred from indirect evidence, needs verification

---

## Error Recovery

If any research step fails, the skill should still produce a useful answer:

1. **All GitHub agents fail** → Report the error, suggest manual investigation
2. **Some agents fail** → Present partial results clearly labeled
3. **services.yaml missing** → Ask user for repo URLs, proceed with GitHub-only
4. **No results found** → Report what was searched and suggest alternative
   search terms or ask the user for more context

---

## Example Invocations

**User:** "How does user authentication work?"

→ Classify as `flow`, identify auth-related services from `feature_areas`,
  launch parallel research across auth service repos, trace the login flow
  from API endpoint through middleware to token generation, present call chain
  with code references.

**User:** "Who owns the payment service?"

→ Classify as `ownership`, look up payment service in `services.yaml`,
  check CODEOWNERS, recent git activity, team directory, present ownership
  table with contacts.

**User:** "How do services handle retry logic?"

→ Classify as `pattern`, search all repos for retry implementations,
  compare approaches, present examples with code references and a
  comparison table.

**User:** "What depends on the notification service?"

→ Classify as `dependency`, check `services.yaml` dependency graph,
  search for import/API client usage across repos, present upstream
  and downstream dependencies with a visual graph.
