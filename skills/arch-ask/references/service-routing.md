# Service Routing Guide

This plugin uses `services.yaml` at the plugin root to route architecture
questions to the right services and repositories.

## How Routing Works

1. When a question arrives, the skill reads `services.yaml`.
2. It tokenizes the question and matches keywords against each service's
   `feature_areas` list.
3. It ranks services by relevance — a service is relevant when multiple
   feature-area keywords match, or when the user mentions it by name.
4. For each relevant service, it looks up `repo`, `language`, and
   `dependencies`.
5. It launches **github-researcher** explore agents scoped to those repos,
   using the `language` field to add search filters (e.g.,
   `language:java`).
6. If the question spans multiple services, the skill traces the call chain
   through `dependencies` to find related repos automatically.

## Configuring services.yaml

The file lives at the plugin root (`services.yaml`). It has three top-level sections:

```yaml
organization: "your-github-org"    # your GitHub org name

services:
  <service-name>:                  # kebab-case identifier
    description: "What this service does"
    language: java | go | typescript | python | ruby | rust  # primary language
    repo: "your-org/repo-name"     # required — GitHub org/repo
    team: "team-name"              # must match a key in `teams` below
    dependencies:                  # downstream services this one calls
      - other-service
    docs_url: "https://..."        # optional — link to docs
    monitoring:                    # optional — observability config
      prometheus_job: "job-name"
      grafana_dashboard: "dashboard-id"
      pagerduty_service: "PABC123"

feature_areas:                     # maps features → service lists
  authentication:
    - user-service
    - api-gateway
  checkout:
    - order-service
    - payment-service

teams:
  team-name:
    slack_channel: "#channel-name"
    oncall_rotation: "rotation-name"
```

### Minimal Example

```yaml
organization: "my-startup"

services:
  payments-api:
    repo: "my-startup/payments-api"
    language: java
    team: payments

feature_areas:
  checkout:
    - payments-api

teams:
  payments:
    slack_channel: "#payments"
```

### Full Example

```yaml
organization: "my-startup"

services:
  payments-api:
    description: "Payment processing and billing"
    language: java
    repo: "my-startup/payments-api"
    team: payments
    dependencies: [inventory-service, notification-service]
    docs_url: "https://github.com/my-startup/payments-api/wiki"
    monitoring:
      prometheus_job: payments_api
      grafana_dashboard: payments-overview
      pagerduty_service: P1A2B3C

  inventory-service:
    description: "Stock and warehouse management"
    language: go
    repo: "my-startup/inventory-service"
    team: supply-chain
    dependencies: [warehouse-adapter]
    monitoring:
      prometheus_job: inventory_svc

  notification-service:
    description: "Email, SMS, and push notifications"
    language: typescript
    repo: "my-startup/notification-service"
    team: platform
    dependencies: []

feature_areas:
  checkout:
    - payments-api
    - inventory-service
  notifications:
    - notification-service
  inventory:
    - inventory-service

teams:
  payments:
    slack_channel: "#payments-team"
    oncall_rotation: "payments-oncall"
  supply-chain:
    slack_channel: "#supply-chain"
    oncall_rotation: "supply-chain-oncall"
  platform:
    slack_channel: "#platform"
    oncall_rotation: "platform-oncall"
```

## Routing Algorithm

The skill uses a simple scoring algorithm:

1. **Exact name match** — If the user mentions a service name verbatim,
   that service gets highest priority (score = 100).
2. **Feature-area match** — Each matching keyword in `feature_areas` adds
   10 points.
3. **Dependency fan-out** — If a matched service lists dependencies, those
   downstream services get a bonus score of 5 (so the skill also searches
   them).
4. **Threshold** — Only services scoring ≥10 are included in the research
   scope.

## Tips for Good Routing

- **Map feature areas broadly.** Include both the entry-point service and
  downstream services. For example, if `payments-api` calls
  `fraud-detection` on every checkout, add `fraud` to the payments
  feature areas too.
- **Include the language field.** It dramatically improves code search
  accuracy. Without it, searches return irrelevant results from config
  files, tests, and vendored code.
- **List dependencies.** This enables the skill to trace multi-hop call
  chains. If Service A calls Service B which calls Service C, listing
  `[B]` as a dependency of A and `[C]` as a dependency of B lets the
  skill traverse the full chain.
- **Keep the registry updated.** When a team renames a repo, splits a
  service, or deprecates one, update `services.yaml`. Stale entries lead
  to searches in the wrong repos — which wastes time and produces
  misleading answers.
- **Use consistent naming.** The service name in `services.yaml` should
  match the service's identity in your deployment manifests, dashboards,
  and alert rules. This makes cross-referencing seamless.
