# Diagram Templates

Use these Mermaid templates when generating architecture diagrams. Pick the
diagram type that best fits the concept you are illustrating.

---

## 1. Call Chain (Horizontal Flow)

Use for showing a single request path through multiple services.

```mermaid
flowchart LR
    A[Client] --> B[API Gateway]
    B --> C[Service A]
    C --> D[Service B]
    D --> E[(Database)]
    C --> F[Cache]
```

**When to use:** Answering "what happens when a user does X?" — trace the
request from entry point to data store.

**Tips:**
- Keep it linear — one primary path per diagram
- Use `[(Database)]` for data stores, `[Cache]` for caches
- Add labels on edges for protocol: `-->|gRPC|`, `-->|REST|`, `-->|async|`

---

## 2. Dependency Graph (Vertical / Top-Down)

Use for showing which services depend on which.

```mermaid
flowchart TD
    A[payments-api] --> B[inventory-service]
    A --> C[notification-service]
    A --> D[fraud-detection]
    B --> E[warehouse-adapter]
    C --> F[email-provider]
    C --> G[sms-provider]
    D --> H[(fraud-rules-db)]
```

**When to use:** Mapping a service's upstream and downstream dependencies,
answering "what does this service talk to?"

**Tips:**
- Put the service under investigation at the top
- Group related dependencies visually
- Use different edge styles for sync vs async:
  `-->` for synchronous, `-.->` for asynchronous / event-driven

---

## 3. Sequence Diagram

Use for showing time-ordered interactions between components.

```mermaid
sequenceDiagram
    participant C as Client
    participant G as API Gateway
    participant A as Service A
    participant B as Service B
    participant DB as Database

    C->>G: POST /api/payments
    G->>A: Forward request
    A->>B: Check inventory
    B->>DB: Query stock
    DB-->>B: Stock available
    B-->>A: 200 OK
    A->>DB: Insert payment record
    DB-->>A: Confirmed
    A-->>G: 201 Created
    G-->>C: 201 Created
```

**When to use:** Investigating timing-sensitive issues, debugging request
flows, or explaining multi-step processes.

**Tips:**
- Use `-->>` (dashed) for responses, `->>` (solid) for requests
- Add `Note over A,B: description` for annotations
- Use `alt` / `else` blocks for branching logic
- Keep to ≤8 participants to stay readable

---

## 4. System Architecture (with Subgraphs)

Use for showing the overall system with logical groupings.

```mermaid
flowchart TD
    subgraph External
        Client[Web/Mobile Client]
        ThirdParty[Third-Party API]
    end

    subgraph Edge["Edge Layer"]
        CDN[CDN]
        LB[Load Balancer]
        GW[API Gateway]
    end

    subgraph Services["Application Services"]
        SvcA[Service A]
        SvcB[Service B]
        SvcC[Service C]
        Worker[Background Worker]
    end

    subgraph Data["Data Layer"]
        PG[(PostgreSQL)]
        Redis[(Redis)]
        S3[(Object Store)]
        Queue[[Message Queue]]
    end

    Client --> CDN --> LB --> GW
    GW --> SvcA & SvcB
    SvcA --> SvcC
    SvcA --> PG & Redis
    SvcB --> PG
    SvcC --> ThirdParty
    SvcA --> Queue --> Worker
    Worker --> S3
```

**When to use:** Architecture overview pages, onboarding docs, or answering
"how is the system structured?"

**Tips:**
- Group components into logical subgraphs (edge, services, data)
- Use descriptive subgraph labels
- Limit to 12–15 nodes maximum — split into multiple diagrams if larger

---

## 5. State Diagram

Use for showing entity lifecycle or workflow states.

```mermaid
stateDiagram-v2
    [*] --> Created
    Created --> Processing : submit()
    Processing --> Completed : success
    Processing --> Failed : error
    Failed --> Processing : retry()
    Failed --> Cancelled : cancel()
    Completed --> Refunded : refund()
    Refunded --> [*]
    Cancelled --> [*]
    Completed --> [*]
```

**When to use:** Explaining entity state machines (order lifecycle, payment
states, deployment stages), or answering "what are the possible states of X?"

**Tips:**
- Label transitions with the action or event that triggers them
- Include terminal states (`[*]`)
- Show error/retry paths — these are often the most important for debugging

---

## 6. Entity Relationship Diagram

Use for showing data model relationships.

```mermaid
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--|{ ORDER_ITEM : contains
    ORDER_ITEM }o--|| PRODUCT : references
    ORDER ||--|| PAYMENT : "paid by"
    USER ||--o{ ADDRESS : "has"
    ORDER }o--|| ADDRESS : "ships to"

    USER {
        uuid id PK
        string email
        string name
        timestamp created_at
    }
    ORDER {
        uuid id PK
        uuid user_id FK
        string status
        decimal total
        timestamp created_at
    }
    PRODUCT {
        uuid id PK
        string name
        decimal price
        string sku
    }
```

**When to use:** Documenting database schemas, explaining data models, or
answering "how is data structured?"

**Tips:**
- Show cardinality (`||--o{` = one-to-many, `||--||` = one-to-one)
- Include key columns (PK, FK) but skip low-importance fields
- Group related entities visually

---

## Choosing the Right Diagram

| Question Type | Diagram |
|--------------|---------|
| "What happens when…?" | Call Chain or Sequence |
| "What does this service depend on?" | Dependency Graph |
| "How is the system structured?" | System Architecture |
| "What are the possible states of…?" | State Diagram |
| "What is the data model?" | ER Diagram |
| "How do these services interact over time?" | Sequence Diagram |
