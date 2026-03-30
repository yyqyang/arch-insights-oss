# Investigation Playbook

Step-by-step playbooks for the most common production investigation scenarios.
Each playbook defines the investigation type, data sources to consult, and a
structured sequence of steps.

---

## General Principles

Before diving into a specific playbook:

1. **Establish the timeline.** When did the problem start? What changed around
   that time? Correlate with deploys, config changes, and traffic patterns.
2. **Scope the blast radius.** Is it one user, one region, one service, or
   everything? This determines urgency and which playbook to follow.
3. **Preserve evidence.** Capture dashboards, log snippets, and metric
   screenshots before they rotate out. Include timestamps and links in your
   findings.
4. **Communicate early.** If the issue affects users, post a status update
   before you finish investigating. Don't wait for root cause.

---

## Investigation Type 1: Deployment Issue

**Trigger:** Errors or degradation started immediately after a deployment.

### Data Sources
- Git history / merged PRs
- CI/CD pipeline logs
- Application metrics (error rate, latency)
- Application logs
- Deployment history (Kubernetes rollout, GitHub Actions runs)

### Steps

1. **Confirm the correlation.**
   - Query recent commits and merged PRs:
     ```bash
     gh pr list --repo {org}/{repo} --state merged --limit 10
     ```
   - Check if the error spike timestamp matches the deploy timestamp.
   - If they don't correlate, this is NOT a deployment issue — switch to
     another playbook.

2. **Identify the change.**
   - Read the diff of the most recent deploy:
     ```bash
     gh pr view {pr_number} --repo {org}/{repo}
     ```
   - Focus on: database migrations, API contract changes, dependency version
     bumps, config/environment variable changes.

3. **Check the deployment pipeline.**
   - Did all CI checks pass? Were there test failures that were ignored?
   - Did the deploy complete cleanly, or did it stall mid-rollout (partial
     deploy)?
   - Check pod/container status — are new instances healthy?

4. **Compare metrics before and after.**
   - Error rate (by endpoint and error code)
   - Latency (p50, p95, p99)
   - Throughput (requests per second)
   - Resource usage (CPU, memory)

5. **Decide: fix forward or rollback.**
   - If the fix is obvious and small → fix forward with a hotfix PR.
   - If the root cause is unclear or the fix is complex → rollback
     immediately, then investigate offline.
   - Rollback command:
     ```bash
     kubectl rollout undo deployment/{service-name}
     ```

6. **Write up findings.**
   - Which PR caused the issue
   - What the specific code/config change was
   - Why existing tests didn't catch it
   - Action items to prevent recurrence

---

## Investigation Type 2: Error Spike

**Trigger:** Sudden increase in error rate without a corresponding deployment.

### Data Sources
- Application logs (error messages, stack traces)
- Metrics dashboards (error rate by endpoint, by status code)
- Dependency health dashboards
- PagerDuty / incident history for dependent services

### Steps

1. **Categorize the errors.**
   - Group errors by HTTP status code (4xx vs 5xx) and endpoint.
   - 4xx spike → likely a client-side issue (bad input, expired tokens, bot
     traffic).
   - 5xx spike → server-side issue — continue investigation.

2. **Check downstream dependencies.**
   - For each dependency, check its health dashboard.
   - If a downstream service is unhealthy, the error spike may be a
     cascading failure. Focus investigation there.

3. **Read the logs.**
   - Look for stack traces, timeout messages, connection refused errors.
   - Identify the specific code path that is failing.
   - Check if the error message is new or a known issue.

4. **Check for external factors.**
   - Traffic spike? Check request volume graphs.
   - Infrastructure issue? Check cloud provider status page.
   - Certificate expiry? DNS change? Network partition?

5. **Narrow the scope.**
   - Is the error happening for all users or a subset?
   - Is it specific to a region, tenant, or feature flag cohort?
   - Check if a feature flag was recently toggled.

6. **Mitigate first, root-cause second.**
   - If a dependency is down, enable circuit breaker or fallback.
   - If traffic is overwhelming, scale up or enable rate limiting.
   - If a specific endpoint is poisoned, disable it temporarily.

---

## Investigation Type 3: Latency Degradation

**Trigger:** p95/p99 latency has increased significantly without an error spike.

### Data Sources
- APM / distributed tracing (Jaeger, Datadog, New Relic)
- Database query performance metrics
- Cache hit/miss rates
- Network latency metrics
- Resource utilization (CPU, memory, I/O)

### Steps

1. **Identify the slow layer.**
   - Use distributed tracing to find which span is contributing the most
     latency.
   - Common culprits: database queries, external API calls, serialization,
     lock contention.

2. **Check database performance.**
   - Look for slow query logs.
   - Check if a new query was introduced (correlate with recent PRs).
   - Check table sizes — has a table grown significantly?
   - Check index usage — is a query doing a full table scan?
   - Check connection pool utilization — are connections exhausted?

3. **Check cache effectiveness.**
   - Cache hit rate drop → more requests hitting the database.
   - Was the cache recently flushed? Did a key pattern change?
   - Is the cache itself slow (check Redis/Memcached latency)?

4. **Check resource utilization.**
   - CPU throttling → containers hitting resource limits.
   - Memory pressure → garbage collection pauses (especially JVM services).
   - Disk I/O → log volume, temporary files, database writes.
   - Network → cross-zone traffic, DNS resolution latency.

5. **Check for contention.**
   - Thread pool exhaustion — all threads blocked on I/O.
   - Lock contention — concurrent requests fighting over shared state.
   - Connection pool exhaustion — waiting for available connections.

6. **Remediate.**
   - Short term: scale up, increase resource limits, increase pool sizes.
   - Medium term: optimize the slow query, add caching, add an index.
   - Long term: refactor the hot path, introduce async processing.

---

## Investigation Type 4: Data Inconsistency

**Trigger:** User reports incorrect data, or monitoring detects mismatched
counts between systems.

### Data Sources
- Database queries (direct inspection of affected records)
- Event logs / message queue consumer lag
- Audit logs
- Application logs around the time of the inconsistency
- Data pipeline monitoring

### Steps

1. **Confirm the inconsistency.**
   - Query both systems directly to verify the mismatch.
   - Document the expected state vs. actual state with specific record IDs.
   - Determine the scope: one record, a batch, or systemic?

2. **Establish the timeline.**
   - When was the record last correctly updated?
   - What operations happened between then and now?
   - Check audit logs for write operations on the affected records.

3. **Check event processing.**
   - If the systems communicate via events (Kafka, SQS, etc.), check
     consumer lag.
   - Look for failed or dead-lettered messages.
   - Check if events were published but not consumed (producer succeeded,
     consumer failed).

4. **Check for race conditions.**
   - Did two concurrent operations update the same record?
   - Is there a missing database transaction or optimistic lock?
   - Check if the write path uses proper idempotency keys.

5. **Check recent code changes.**
   - Was the write path or serialization logic recently modified?
   - Was a database migration run that altered column types or defaults?
   - Was a new consumer deployed with different processing logic?

6. **Remediate.**
   - Fix the affected records with a targeted data patch (never bulk-update
     without review).
   - Replay events from the dead-letter queue if applicable.
   - Fix the root cause in code and add validation to prevent recurrence.
   - Add reconciliation jobs to detect future inconsistencies early.

---

## Investigation Type 5: Resource Exhaustion

**Trigger:** Service is OOMKilled, disk full, connection pool drained, or
file descriptor limits hit.

### Data Sources
- Container / VM resource metrics (CPU, memory, disk, network)
- Process-level metrics (heap usage, GC stats, thread count, FD count)
- Kubernetes events (`kubectl describe pod`)
- Application logs (especially around restart times)
- Historical resource usage trends

### Steps

1. **Identify the exhausted resource.**
   - OOMKilled → memory exhaustion.
   - Disk full → log volume, temp files, or database growth.
   - Connection pool drained → too many concurrent requests or leaked
     connections.
   - Too many open files → file descriptor leak or excessive connections.

2. **Check if it's a leak or a spike.**
   - **Leak:** resource usage grows steadily over hours/days, eventually
     hitting the limit. Look for unclosed connections, streams, or
     unbounded caches.
   - **Spike:** resource usage jumps suddenly. Correlate with traffic
     spikes, large requests, or batch jobs.

3. **For memory issues:**
   - Check heap dumps or memory profiler output if available.
   - Look for large in-memory collections, unbounded caches, or objects
     held by long-lived references.
   - Check if the GC is running but unable to reclaim memory (memory
     fragmentation or reference leaks).
   - Compare container memory limit vs. JVM heap size — is the JVM
     configured to leave room for off-heap memory?

4. **For disk issues:**
   - Check log volume — is something logging at an unexpectedly high rate?
   - Check for orphaned temp files.
   - Check database growth — was a large data import or migration run?
   - Set up log rotation and retention policies if missing.

5. **For connection/FD issues:**
   - Check connection pool metrics — are connections being returned?
   - Look for missing `finally` blocks or `defer` statements that close
     connections.
   - Check if connection timeouts are configured — stale connections may
     never be reclaimed.

6. **Remediate.**
   - Short term: increase limits (memory, disk, pool size) to stop the
     bleeding.
   - Medium term: fix the leak or optimize the resource usage.
   - Long term: add resource monitoring alerts at 80% threshold so you
     catch issues before they become outages.

---

## Investigation Summary Template

After completing any investigation, document findings using this structure:

```markdown
## Investigation Summary

**Issue:** {one-line description}
**Severity:** {SEV1 / SEV2 / SEV3}
**Duration:** {start_time} – {end_time} ({total duration})
**Impact:** {users affected, revenue impact, SLA breach}

### Timeline
| Time | Event |
|------|-------|
| HH:MM | First alert fired |
| HH:MM | Investigation started |
| HH:MM | Root cause identified |
| HH:MM | Mitigation applied |
| HH:MM | Service fully recovered |

### Root Cause
{Detailed technical explanation of what went wrong and why.}

### Mitigation
{What was done to stop the bleeding.}

### Prevention
| Action Item | Owner | Due Date |
|------------|-------|----------|
| {action} | @engineer | YYYY-MM-DD |
| {action} | @engineer | YYYY-MM-DD |
```
