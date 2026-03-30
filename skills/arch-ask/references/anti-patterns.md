# Code Search Anti-Patterns

Common mistakes that waste time and produce poor results when researching
architecture questions. Avoid every one of these.

---

## 1. Natural Language Queries

GitHub code search is keyword-based, not semantic. Treat it like `grep`, not
like asking a colleague.

❌ `search_code("how does user authentication work in the payments service")`
✅ `search_code("repo:{repo} AuthenticationService language:java")`
✅ `search_code("repo:{repo} JwtTokenProvider language:java")`

**Why it matters:** Natural language queries return noise — README files,
comments, blog posts vendored into the repo — not the implementation you need.

---

## 2. Single-Repo Tunnel Vision

When you find ServiceA calling `httpClient.post("/api/v2/inventory")`, you
**must** trace into ServiceB's repo to find the handler. The answer is never
complete if you only look at one side of a service boundary.

❌ Finding a REST call in `payments-api` and summarizing the interaction from
the caller's code alone.
✅ Searching `inventory-service` for the matching route handler, then
describing both sides.

**Rule of thumb:** Every HTTP call, gRPC stub, or message-queue publish is a
signal to search another repo.

---

## 3. Too Many Search Variations in One Repo

If your first 2–3 searches in a repo return nothing relevant, the code
probably does not live there. Move on to another repo or ask the user for
clarification.

❌ Trying 8 different query reformulations in the same repo hoping to find
the right class name.
✅ After 2 failed searches, check `services.yaml` dependencies or broaden
to a broader search (drop the `repo:` filter) to discover which repo actually owns the code.

---

## 4. Ignoring the Language Filter

Without a language filter, results include YAML configs, Markdown docs, JSON
fixtures, and vendored code. Always scope by language when you know it.

❌ `search_code("repo:{repo} PaymentProcessor")`
✅ `search_code("repo:{repo} PaymentProcessor language:java")`

**Bonus:** Combine with `path:` to focus on source directories:
`search_code("repo:{repo} PaymentProcessor language:java path:src/")`

---

## 5. Searching for Generated Code

Generated files (protobuf stubs, OpenAPI clients, ORM models) clutter results
and describe **interfaces**, not **logic**. Search for the hand-written
implementation instead.

❌ `search_code("repo:{repo} PaymentServiceGrpc")`  — hits the generated gRPC stub
✅ `search_code("repo:{repo} PaymentServiceImpl language:java")`  — hits the real implementation

**Tip:** Exclude generated paths when possible:
`search_code("repo:{repo} PaymentService NOT path:generated/ NOT path:proto/")`

---

## 6. Overlooking Test Files

Tests are gold for understanding behavior — they show how a class is
instantiated, what inputs it expects, and what outputs it produces. Don't
skip them.

❌ Only reading production code and guessing at expected behavior.
✅ Searching for test files: `search_code("repo:{repo} PaymentProcessorTest language:java")`

Tests are especially useful for understanding edge cases, error handling, and
integration contracts.

---

## 7. Copying File Snippets Without Context

A 10-line snippet from the middle of a class is often misleading. Always read
the full file (or at least the class declaration, constructor, and the method
in question) before drawing conclusions.

❌ Reading lines 142–155 of `PaymentController.java` and concluding that
authentication is not enforced.
✅ Reading the class-level annotations (`@Authenticated`, `@RolesAllowed`)
and the middleware chain to understand the full request lifecycle.

---

## 8. Assuming Naming Conventions Are Universal

Different teams use different conventions. One team's `UserService` is another
team's `UserManager`, `UserFacade`, or `user_handler.go`. When a search fails,
try synonyms.

❌ Searching only for `UserService` and concluding the feature doesn't exist.
✅ Trying `UserService`, `UserManager`, `UserHandler`, `user_controller`,
`users.go`, `UsersApi` before giving up.

**Systematic approach:** Search for the **domain noun** (`User`, `Payment`,
`Order`) without the suffix first, then filter results.

---

## 9. Not Reading Dependency Manifests

`pom.xml`, `go.mod`, `package.json`, and `requirements.txt` tell you what
libraries and frameworks a service uses. This context changes how you
interpret the code.

❌ Spending 20 minutes searching for a custom authentication implementation
when the service uses Spring Security (visible in `pom.xml`).
✅ Reading the dependency manifest first to understand the framework, then
searching for configuration (`SecurityConfig`, `WebSecurityConfigurerAdapter`).

---

## 10. Presenting Search Results as Architecture

Raw code search results are **evidence**, not **answers**. Your job is to
synthesize findings into a coherent architecture narrative.

❌ Dumping a list of files and code snippets:
"I found `PaymentController.java`, `PaymentService.java`, and
`PaymentRepository.java`."
✅ Synthesizing a narrative:
"The payments service uses a three-layer architecture: the controller
validates and deserializes HTTP requests, delegates to the service layer for
business logic (idempotency checks, fraud scoring), and persists via a
repository that wraps a PostgreSQL database."

**Always answer the user's question**, not just show what you found.
