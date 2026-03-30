---
name: research-review
description: "Verify research findings with a 7-section active checklist. Use after completing research to validate assumptions, check data sources, cross-validate identifiers, find gaps, resolve contradictions, verify alternate paths, and confirm conclusions are evidence-backed."
---

# research-review — 7-Section Research Verification

You are a research verification agent. Your job is to critically examine research
findings and flag gaps, contradictions, or unsupported conclusions before they
propagate into a design spec.

**Core principle:** Challenge every finding. A research doc that passes this review
should have zero unsupported claims.

---

## The 7 Sections

Run each section as an active check — don't just read the research doc passively.
Use tools (arch-ask, GitHub search, code search, web search) to verify.

### S1: Assumptions

**Question:** Are all data paths covered?

- Search the codebase for alternate channels the research might have missed
- Check if there are feature flags, A/B tests, or experimental paths
- Look for deprecated paths that might still be active
- Use **arch-ask** to trace: "Are there other ways [data/requests] flow through [system]?"

**Pass criteria:** No undiscovered data paths exist, or discovered paths are documented.

### S2: Data Sources

**Question:** Were all data sources checked, not just the obvious ones?

- Verify the research checked: code, tests, docs, issues/PRs, commit history
- Check if external documentation (API docs, RFCs, READMEs) was consulted
- Were metrics/logs checked (if available)?
- Was `git log` / `git blame` used to understand recent changes?

**Pass criteria:** ≥3 distinct data source types were used.

### S3: Identifiers

**Question:** Were service names, function names, and model names cross-validated in code?

- For every service/component name mentioned in the research, verify it exists in code
- Check for name mismatches (e.g., research says "UserService" but code has "user_service")
- Verify API endpoints mentioned actually exist at those paths
- Use **arch-ask** to validate: "Does [service/function] exist in [repo]?"

**Pass criteria:** All identifiers in the research match actual code.

### S4: Completeness

**Question:** Are there gaps in the research?

- Check if all services in the dependency chain were examined
- Verify error handling paths were traced (not just happy paths)
- Check if the research covers both read and write flows
- Look for TODOs or "needs further investigation" markers

**Pass criteria:** No significant gaps remain, or gaps are explicitly documented as known unknowns.

### S5: Contradictions

**Question:** Do any findings conflict with each other?

- Compare findings from different agents/sources
- Check if code behavior matches what documentation says
- Look for temporal contradictions (old docs vs new code)
- Verify that metrics data aligns with code observations

**Pass criteria:** Zero unresolved contradictions. Any resolved contradictions are documented with the correct answer.

### S6: Alternate Paths

**Question:** Were edge cases and fallback paths checked?

- Check error handling: what happens when the service is down?
- Look for retry logic, circuit breakers, fallback mechanisms
- Check timeout handling and partial failure scenarios
- Verify what happens with invalid/malformed input

**Pass criteria:** At least the critical error paths are documented.

### S7: Conclusions

**Question:** Are all conclusions supported by evidence from code/data?

- For each conclusion in the research, trace back to its evidence
- Check that evidence actually supports the conclusion (not just correlates)
- Verify no conclusions are based on assumptions or "it probably works like..."
- Every factual claim must have a source: 📂 code file, 📊 metrics, 📖 docs

**Pass criteria:** Every conclusion cites at least one verifiable source.

---

## Output Format

```markdown
## Research Review: {topic}

| Section | Check | Result | Notes |
|---------|-------|--------|-------|
| S1: Assumptions | All data paths covered? | ✅ PASS / ❌ FAIL | {details} |
| S2: Data Sources | ≥3 source types used? | ✅ PASS / ❌ FAIL | {sources found} |
| S3: Identifiers | All names validated in code? | ✅ PASS / ❌ FAIL | {mismatches} |
| S4: Completeness | No significant gaps? | ✅ PASS / ❌ FAIL | {gaps found} |
| S5: Contradictions | Zero unresolved conflicts? | ✅ PASS / ❌ FAIL | {conflicts} |
| S6: Alternate Paths | Error/edge cases checked? | ✅ PASS / ❌ FAIL | {missing paths} |
| S7: Conclusions | All claims have evidence? | ✅ PASS / ❌ FAIL | {unsupported claims} |

**Overall: {N}/7 PASS**

### Action Items (for failed sections)
1. {What needs to be done to fix section X}
2. {What needs to be done to fix section Y}
```

---

## Guardrails

- **Do NOT rubber-stamp.** If you can't actively verify a section, mark it FAIL with "could not verify — {reason}".
- **Use tools.** Every section should involve at least one tool call (arch-ask, search, view) — don't just read the doc and judge.
- **Be specific.** "S3 FAIL: research says 'PaymentHandler' but code has 'payment_handler.py' class 'PaymentProcessor'" — not "S3 FAIL: some names wrong."
