# Design Research Guide

When the user asks "how should I design X?", the arch-design skill needs to
**research first, recommend second**. This guide defines where to look and how
to present findings.

---

## Research Sources (in priority order)

### 1. Existing Code in Your Repos

The best design guidance comes from patterns already working in your codebase.
Use the github-researcher agent to find:

- **Similar features** — if you're adding payments, search for how orders or
  billing already work
- **Shared libraries** — look for common utils, middleware, or base classes
  that enforce patterns
- **Configuration patterns** — how do other services configure the same
  concern (retries, timeouts, connection pools)?
- **Test patterns** — how do similar features test the same kind of behavior?

### 2. README and In-Repo Documentation

Before searching online, check the repos themselves:

- `README.md` — often documents architecture decisions and setup
- `docs/` or `documentation/` directories
- `ARCHITECTURE.md`, `CONTRIBUTING.md` — design conventions
- Code comments on complex functions/classes
- `CHANGELOG.md` — reveals how the design evolved over time

### 3. GitHub Issues and PRs

Past discussions often capture design rationale:

- Search closed issues for prior debates about the same concern
- Read PR descriptions for complex features — they often explain *why*
- Look at review comments — reviewers sometimes suggest patterns

### 4. Online Documentation and References

Use web fetch to pull relevant resources:

- Official framework/library documentation
- Architecture pattern references (e.g., microservices patterns)
- Cloud provider best practices (AWS, GCP, Azure docs)
- Open-source projects that solve similar problems

---

## Output Format

Present design recommendations as a structured comparison, always grounded in
evidence:

```markdown
## Design: {Topic}

### Existing Patterns Found

**Pattern 1: {Name}** (found in `owner/repo`)
📂 `path/to/implementation` (L15-40)
- How it works: {brief description}
- Pros: {what works well}
- Cons: {known limitations}

**Pattern 2: {Name}** (found in `owner/other-repo`)
📂 `path/to/implementation` (L22-55)
- How it works: {brief description}
- Pros: {what works well}
- Cons: {known limitations}

### Comparison

| Aspect      | Pattern 1       | Pattern 2       |
|-------------|-----------------|-----------------|
| Complexity  | Simple          | Moderate        |
| Scalability | Limited         | Good            |
| Test coverage | High          | Low             |

### Recommendation

Use **Pattern 1** because:
- It's already used in 3 services in the codebase
- It matches the language/framework of the target service
- The simpler approach is sufficient for the expected load

### Implementation Sketch

Based on `owner/repo/path/to/implementation`, here's a starting point:

{code sketch adapted to the user's context}

### References

📂 `owner/repo/path/file` — existing implementation
📂 `owner/other-repo/path/file` — alternative approach
📖 https://docs.example.com/patterns — framework documentation
```

---

## Key Rules

1. **Every recommendation must cite real code** — no abstract "best practices"
   without at least one concrete example from the codebase or a linked online
   reference
2. **Show alternatives** — always present at least 2 approaches when possible
3. **Match the existing stack** — check `services.yaml` for the target service's
   language and framework before recommending patterns
4. **Search online when the codebase has no examples** — use web fetch to find
   well-regarded open-source implementations, and link to them
5. **Acknowledge gaps** — if you can't find relevant patterns, say so rather
   than inventing recommendations
