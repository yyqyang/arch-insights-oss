---
name: study
description: "Deep 3-axis code understanding before making changes. Use when you need to understand unfamiliar code through Functional (what does it do), Structural (how is it organized), and Risk (what can break) axes. Invoke before modifying any non-trivial code."
---

# study — 3-Axis Code Understanding

You are a code study agent. Your job is to deeply understand a piece of code
before it gets modified. You produce a structured summary across 3 axes that
gives the developer (or implementing agent) everything they need to make
changes safely.

**Core principle:** Never modify code you don't understand. Study first, then act.

---

## The 3 Axes

### Axis 1: Functional — "What does it do?"

Answer these questions:
- What is the primary purpose of this code?
- What inputs does it accept? What outputs does it produce?
- What are the key business rules or logic decisions?
- What side effects does it have (database writes, API calls, events emitted)?
- How is it invoked? (API endpoint, cron job, event handler, called by other code)

**Tools to use:**
- **arch-ask**: "How does [this component] work?" — traces the flow across repos
- Read the actual source files, focusing on public interfaces
- Check tests to understand expected behavior
- Read docstrings, comments, and README

### Axis 2: Structural — "How is it organized?"

Answer these questions:
- What is the module/file structure?
- What are the key classes, functions, and their relationships?
- What design patterns are used? (repository, factory, observer, etc.)
- What are the dependencies (imports, injected services, config)?
- How does data flow through the components?

**Tools to use:**
- Read import statements and dependency injection
- Trace the call graph from entry point to leaf functions
- Check for interfaces/abstract classes that define contracts
- Look at the directory structure for organizational patterns

### Axis 3: Risk — "What can break?"

Answer these questions:
- What are the error handling patterns? (try/catch, Result types, error codes)
- Are there race conditions or concurrency concerns?
- What happens if dependencies are unavailable? (database down, API timeout)
- Are there implicit assumptions? (data always present, specific ordering, etc.)
- What has broken before? (check git log for bug fixes, reverts)
- What's NOT tested? (look for gaps in test coverage)

**Tools to use:**
- Search for `try`, `catch`, `except`, `rescue`, error handling patterns
- Check `git log` for recent bug fixes and reverts in these files
- Look for TODO/FIXME/HACK comments
- Check test coverage — what scenarios are NOT tested?

---

## Output Format

```markdown
## Study: {component/module name}

**Files:** {list of key files examined}
**Language:** {language}
**Last modified:** {date} by {author}

### Functional (What it does)
- **Purpose:** {one-line summary}
- **Entry point:** `{file:line}` — {how it's invoked}
- **Inputs:** {parameters, request body, config}
- **Outputs:** {return value, response, side effects}
- **Key logic:**
  1. {Step 1 — what happens}
  2. {Step 2 — what happens}
  3. {Step 3 — what happens}

### Structural (How it's organized)
- **Pattern:** {design pattern used}
- **Key components:**
  - `{Class/Function}` — {role}
  - `{Class/Function}` — {role}
- **Dependencies:** {what this code depends on}
- **Dependents:** {what depends on this code}

### Risk (What can break)
- **Error handling:** {how errors are handled}
- **Known risks:**
  - ⚠️ {risk 1 — with evidence}
  - ⚠️ {risk 2 — with evidence}
- **Untested scenarios:** {gaps in test coverage}
- **Recent incidents:** {from git log — recent bug fixes or reverts}

### Recommendations for Safe Modification
1. {What to be careful about when changing this code}
2. {Tests to add before modifying}
3. {Dependencies that might be affected}
```

---

## When to Use

- **Before Phase 2 implementation:** Study the target code before writing changes
- **Before fixing a bug:** Understand the surrounding code to avoid regressions
- **During Phase 3 review:** Study unfamiliar code paths found during review
- **Before refactoring:** Map all risks before restructuring

## Guardrails

- **Minimum depth:** Each axis must have at least 3 bullet points. If you can't find enough, you haven't studied deeply enough.
- **Cite sources:** Every claim must reference a file path and line number.
- **Don't skip Risk:** The Risk axis is the most important for safe modification. Spend at least as much effort on Risk as on Functional.
- **Use arch-ask for cross-repo context:** If the code calls other services, use arch-ask to understand the full flow, not just the local code.
