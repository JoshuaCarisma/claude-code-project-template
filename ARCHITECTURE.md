# Architecture: [PROJECT NAME]
Last updated: [YYYY-MM-DD] — revisit every 3 months or after major structural changes.

## What This System Does
[One paragraph: the core problem solved, who uses it, and the main actors.]

## Folder Map
src/
├── app/           # [routing, page-level components]
├── components/    # [shared UI components]
├── features/      # [feature-scoped modules — list main ones]
├── lib/           # [utilities and helpers]
├── services/      # [external integrations]
├── hooks/         # [shared hooks]
└── types/         # [shared types and interfaces]

## Layer Boundaries
UI Layer → Feature Logic → Service Layer → External APIs/DB

- UI components must NOT directly call APIs or databases
- Feature logic must NOT import from other features directly
- Service layer owns all external communication
- [Add project-specific rules here]

## Data Flow
[Describe the 2-3 most critical user actions and how data moves]

**[Action 1]:**
[e.g. User submits form → FeatureService → DB → returns state → UI updates]

**[Action 2]:**
[trace here]

## Key Design Decisions
- **[Decision 1]:** [What was chosen, why, and what was traded off]
- **[Decision 2]:** [Same format]

## Architectural Invariants
Things that must NEVER be true:
- [e.g. User data must never be accessible to another user]
- [e.g. Auth checks happen at middleware level, never inside components]
- [Add your own]

## Cross-Cutting Concerns
- **Authentication:** [which module owns it, how it propagates]
- **Error handling:** [pattern used]
- **Logging:** [what gets logged, what never gets logged]
- **Validation:** [where it happens]
- **State management:** [approach]

## External Integrations
| Service | Purpose | Owner module |
|---|---|---|
| [e.g. Stripe] | Payments | services/payments |
| [e.g. Supabase] | Auth + DB | services/db |

## What This Is Not
- [Explicitly rule out things that might seem in-scope]