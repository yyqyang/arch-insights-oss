---
name: implementation
description: "Multi-agent parallel implementation orchestration. Use for features that span multiple modules or files. Coordinates parallel waves: test writing, implementation per module, and interface cross-checking."
---

# implementation — Multi-Agent Parallel Orchestration

You are an implementation orchestrator. Your job is to coordinate parallel
agents working on different modules of a feature simultaneously, ensuring
they produce code that works together.

**Core principle:** Parallelize independent work, serialize dependent work.
Tests define the contract between agents.

---

## Step 1 — Analyze the Spec for Parallelism

Read the design spec and identify:

1. **Independent modules** — code that can be written in parallel (different files, no shared interfaces)
2. **Dependent modules** — code that must be written sequentially (one depends on another's output)
3. **Shared interfaces** — contracts that multiple modules must agree on (API schemas, event formats, data models)

Build a dependency graph:

```
module-a (data models) ──┐
                          ├── module-c (API layer, needs a + b)
module-b (business logic)─┘
```

---

## Step 2 — Wave Execution

### Wave 1: FAIL_TO_PASS Test Writing (parallel)

For each module, launch a parallel agent to write tests:

```
For each module in parallel:
  Agent task:
    1. Read the spec section for this module
    2. Write unit tests that exercise each requirement
    3. Tests MUST fail right now (no implementation yet)
    4. Tests define the acceptance criteria for Wave 2
    5. Return: list of test files and test names
```

**Shared interface tests:** Also write integration tests that verify the
contracts between modules. These ensure Wave 2 agents produce compatible code.

### Wave 2: Implementation (parallel for independent modules)

```
For each independent module in parallel:
  Agent task:
    1. Read the spec section for this module
    2. Read the FAIL_TO_PASS tests from Wave 1
    3. Use **study** skill to understand existing code in the target area
    4. Use **arch-design** to find reference patterns across GitHub
    5. Implement until all Wave 1 tests pass
    6. Return: list of changed files and test results
```

For dependent modules, execute sequentially in dependency order:
```
For each dependent module (in order):
  Wait for dependencies to complete
  Then implement (same steps as above)
```

### Wave 3: Interface Cross-Check

After all modules are implemented:

```
Cross-check:
  1. Use **arch-ask** to verify: "How does [module A] connect to [module B]?"
  2. Run ALL tests (unit + integration)
  3. Verify API contracts match between producer and consumer modules
  4. Verify event schemas match between emitter and handler
  5. If mismatch → fix the inconsistent side → re-run tests
```

---

## Step 3 — Ratchet (Quality Lock)

After each wave, apply the ratchet:

```
RATCHET:
  1. Run full test suite
  2. If ALL pass → LOCK this state (git commit)
  3. If SOME fail:
     a. Identify which module's changes caused the failure
     b. Revert ONLY that module's changes
     c. Re-attempt with a different approach
     d. Keep all other modules' passing changes
  4. If ALL fail → revert entire wave, try different approach
  5. Max 3 retries per wave before escalating
```

---

## Output Format

```markdown
## Implementation Report

### Wave Summary
| Wave | Modules | Status | Tests |
|------|---------|--------|-------|
| Wave 1 (tests) | {modules} | ✅ Complete | {N} tests written, all failing |
| Wave 2 (impl) | {modules} | ✅ Complete | {N} tests passing |
| Wave 3 (cross-check) | all | ✅ Complete | {N} total tests passing |

### Modules Implemented
| Module | Files Changed | Tests | Status |
|--------|--------------|-------|--------|
| {module-a} | {file list} | {N pass / M total} | ✅ |
| {module-b} | {file list} | {N pass / M total} | ✅ |

### Interface Verification
| Interface | Producer | Consumer | Status |
|-----------|----------|----------|--------|
| {API/event} | {module-a} | {module-b} | ✅ Compatible |

### Ratchet History
| Wave | Attempt | Result |
|------|---------|--------|
| Wave 2 | 1 | ✅ All tests pass |
| Wave 3 | 1 | ❌ Contract mismatch → fixed |
| Wave 3 | 2 | ✅ All tests pass |
```

---

## When to Use

- **Multi-file features:** When the spec touches ≥3 files that can be worked on independently
- **Multi-module features:** When different parts of the feature are in different modules/packages
- **Multi-repo features:** When changes span multiple repositories

For single-file or simple changes, skip this skill and implement directly.

## Guardrails

- **Tests first.** Wave 1 (tests) must complete before Wave 2 (implementation) starts.
- **Never skip Wave 3.** Interface cross-checking catches the most dangerous bugs.
- **Ratchet is mandatory.** Never proceed to the next wave without locking passing state.
- **Log everything.** Each wave gets a line in `.workflow-log.tsv`.
