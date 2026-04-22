# Architecture: Body By Carisma — Client Coaching Platform
Last updated: 2026-04-21 — revisit every 3 months or after major structural changes.

## What This System Does
A mobile-first health and fitness coaching platform that turns structured coaching 
methodology into a daily execution system. Coaches build programs, schedule daily plans, 
and review client progress. Clients receive guided workouts, follow scheduled recipes, 
submit voice and video journal entries, and track their own progress through analytics 
dashboards. The system connects planning, execution, adherence, and reflection into one 
coherent data model. Coaches configure and observe. Clients execute and reflect. The 
platform tracks everything and surfaces it to both parties through AI-assisted insights 
and visual analytics.

## Folder Map (Codemap)
Answer: "Where is the thing that does X?"

```
bbc-platform/                        # Monorepo root
├── apps/                            # Client-facing entry points
│   ├── mobile/                      # React Native + Expo — primary client app
│   │   └── features/                # Domain-scoped feature modules
│   │       ├── training/            # Workout player, exercise logging, program view
│   │       ├── nutrition/           # Recipe view, meal adherence, meal plan
│   │       ├── journaling/          # Voice/video/text entry, timeline, prompts
│   │       ├── calendar/            # Daily plan view, schedule items, coach tasks
│   │       ├── analytics/           # Client progress dashboards and graphs
│   │       ├── messaging/           # Direct coach-client chat
│   │       └── auth/                # Login, session bootstrap, consent flows
│   ├── coach-web/                   # Coach dashboard — program builder, client view
│   │   └── features/                # Same domain-scoped pattern as mobile
│   ├── admin-web/                   # Admin portal — business analytics, org mgmt
│   └── marketing-site/              # Public site — Vercel only, no product logic
│
├── services/                        # Backend domain services — each owns its data
│   ├── identity/                    # Users, roles, orgs, consent, permissions
│   ├── calendar/                    # Schedule objects, daily plans, recurrence,
│   │                                #   cross-domain orchestration via events
│   ├── training/                    # Exercises, workouts, programs, sessions,
│   │                                #   timed workout engine definitions
│   ├── nutrition/                   # Recipes, meal plans, adherence logs,
│   │                                #   client recipe library
│   ├── journaling/                  # Journal entries, media metadata, transcripts,
│   │                                #   summaries, timeline events
│   ├── analytics/                   # Event ingestion, aggregations, graph-ready metrics
│   ├── messaging/                   # Message threads and events (Matrix Synapse)
│   ├── notifications/               # Reminders and delivery (Novu)
│   └── ingestion/                   # Media upload pipeline, transcription (faster-
│                                    #   whisper), AI orchestration (Haystack/vLLM)
│
├── packages/                        # Shared code — only truly cross-cutting things
│   ├── ui/                          # Shared UI primitives and design system tokens
│   ├── schemas/                     # Zod schemas — single source of truth for
│   │                                #   validation across apps and services
│   ├── types/                       # Shared TypeScript interfaces and domain types
│   ├── api-client/                  # Generated/typed API clients for gateway calls
│   ├── health-sync/                 # HealthKit (iOS) + Health Connect (Android)
│   │                                #   native integration wrappers
│   └── config/                      # Shared environment config, constants
│
├── infra/                           # Deployment, environment setup, AWS config,
│                                    #   Expo EAS build config, Docker/compose files
└── docs/                            # ARCHITECTURE.md, ADRs, product specs,
                                     #   analytics event definitions, onboarding guides
```

Each `features/` module inside an app is internally type-scoped:
```
features/training/
├── components/    # UI for this feature only
├── hooks/         # Feature-local data hooks
├── state/         # Zustand stores scoped to this feature
├── services/      # API calls — delegates to packages/api-client
└── types/         # Types local to this feature only
```

## System Layers and Boundaries
Data moves through the system in this order:

**[App UI] → [Feature Module] → [Shared API Client] → [API Gateway / BFF] → [Domain Service] → [DB / Storage / Event Bus]**

Cross-domain communication happens through **events and shared packages only** — never through direct service-to-service imports or feature-to-feature calls.

Non-negotiable boundary rules:
- UI components must NOT directly call domain services, databases, or storage —
  all calls go through the feature module → shared API client path
- Feature modules must NOT import from other feature modules' internals —
  cross-domain data is assembled through APIs and shared schemas in `packages/`
- The API gateway owns authentication, authorization, rate limiting, and request
  shaping — domain services must NOT enforce auth independently of it
- Domain services must NOT reach into each other synchronously — cross-domain
  reactions happen through events on the event bus, consumed by the relevant service
- The calendar/planning service is the orchestration layer for cross-domain scheduling —
  training and nutrition services do NOT schedule; they expose definitions for calendar
  to reference
- The `packages/schemas/` Zod schemas are the single source of truth for validation —
  never duplicate validation logic in feature components or service handlers
- Supabase Storage must NOT be called directly from feature code —
  all media access goes through the ingestion or journaling service boundary

## Data Flow
How data moves for the four most important user actions:

**Coach builds and schedules a client's day:**
Coach UI → Feature Module → API Client → API Gateway (auth + authz) →
Calendar/Planning Service → creates schedule objects (workouts, recipes, habits, tasks) →
links to Training/Nutrition service definitions → stores recurrence/dated scheduling →
emits `plan.scheduled` event → Notifications Service (reminders) + Analytics Service
(event ingested)

**Client starts and completes a guided workout:**
Client App → Training Feature → API Client → API Gateway →
Training Service (fetch session + timed workout engine config) →
returns session to app → app runs workout with cues and timer →
on completion: Training Service writes completed session + exercise logs + timer outcomes →
emits `workout.completed` event → Analytics Service ingests adherence event

**Client marks recipe adherence:**
Client App → Nutrition Feature → API Client → API Gateway →
Nutrition Service → relates adherence action to: scheduled recipe + meal plan item +
calendar schedule object + client recipe library entry (if substituted) →
stores adherence log → emits `recipe.adherence.logged` event →
Analytics Service ingests for meal adherence trends

**Client submits a voice journal entry:**
Client App → Journaling Feature → API Client → API Gateway →
Ingestion Service (media upload to Supabase Storage) →
Journaling Service creates timeline event + stores asset metadata →
queues transcription job → faster-whisper transcribes →
Haystack/vLLM generates summary + tags →
Journaling Service attaches transcript + summary + tags to canonical journal record →
record now readable by: coach review view + analytics dashboards + future memory queries

## Key Design Decisions

- **Monorepo over polyrepo:** Tight coordination across apps, services, and shared
  packages requires shared types, schemas, API clients, and design system code to stay
  in sync. A monorepo makes that coordination explicit and enforced. Tradeoff: more
  upfront tooling investment (Turborepo/Nx, shared tsconfig, lint config); service
  boundaries are maintained by convention rather than hard deployment isolation.

- **Supabase over self-managed Postgres + bespoke storage from day one:** Supabase
  provides real Postgres, RLS-backed storage, managed backups, and resumable uploads
  without the operational overhead of standing up that infrastructure ourselves. Keeps
  v1 velocity high. Tradeoff: Supabase becomes a platform dependency; migration to
  SeaweedFS or self-hosted Postgres later will require careful media abstraction and
  data-layer work. That migration path is preserved by keeping all Supabase calls behind
  service boundaries, never in feature code.

- **Keycloak over simpler auth (Firebase Auth, NextAuth, Clerk):** This product has
  complex role requirements (coach, client, admin, future multi-org), a likely HIPAA
  compliance path, and a need for OIDC-standard token flows. Keycloak is battle-tested
  for those requirements and keeps auth infrastructure fully under our control. Tradeoff:
  Keycloak has significant operational complexity compared to managed auth services;
  wrong choice for a simple CRUD app, right choice here.

- **Hybrid request-driven + event-driven over purely synchronous service calls:**
  Calendar, training, nutrition, journaling, analytics, and notifications all need to
  react to the same user actions without being tightly coupled. A pure request-driven
  model would create brittle chains of synchronous service calls. An event bus lets each
  domain react independently. Tradeoff: adds infrastructure complexity and makes
  end-to-end tracing harder; requires disciplined event schema versioning.

- **Calendar as orchestration layer:** The calendar/planning service is not just a
  schedule viewer. It is the domain that assembles cross-domain plans (workouts, recipes,
  habits, tasks) into a coherent daily structure. Training and nutrition expose
  definitions; calendar references and sequences them. Tradeoff: calendar becomes a
  critical-path service; changes to how planning works require coordinating across
  training and nutrition schema contracts.

## Architectural Invariants
These must NEVER be true, even if it would be convenient:

- Client data must never be queryable by another client — all DB queries filter by
  `userId` or `clientId`; Supabase RLS enforces this at the data layer as a second line
  of defense
- Health metrics, body data, journal content, and biometric fields must never appear
  in logs, error messages, or analytics event payloads
- Auth validation happens at the API gateway and Supabase RLS — NEVER inside
  UI components or feature-level hooks
- Features never import from each other's internals — cross-domain data flows through
  events and `packages/` shared contracts only
- No business logic in the database layer — no stored procedures or triggers;
  all logic lives in domain services
- AI-generated outputs (summaries, insights, tags) must never be presented to clients
  as clinical recommendations — all AI is assistive and requires human coaching context
- The ingestion/AI layer must never autonomously trigger health-critical actions —
  it produces inputs for coaches and dashboards, not decisions
- Supabase Storage must never be called directly from app feature code —
  always through the ingestion or journaling service boundary

## Cross-Cutting Concerns

- **Authentication:** Owned by `services/identity` + `packages/api-client`. Flow:
  Keycloak OIDC → Authorization Code flow → access token stored in app session context
  → attached as JWT bearer token in `Authorization` header on all API calls → validated
  at API gateway → user identity, org, roles, and permissions injected into request
  context → forwarded to domain services → Supabase RLS uses JWT claims as additional
  data-layer enforcement. Auth state must NOT be managed per-feature — one session
  provider in the app shell.

- **Error handling:** Backend: centralized error handler at API gateway converts all
  domain errors and exceptions into a consistent API error envelope (code, message,
  requestId). Domain services throw typed application errors for expected failures
  (e.g., `WorkoutAlreadyCompleted`, `RecipeNotFound`, `CalendarConflict`) — not generic
  runtime exceptions. Frontend: feature-level error boundaries + TanStack Query mutation
  error states. Failures are isolated — a journaling upload failure must not affect the
  workout player. No single app-level catch-all.

- **Logging:** Log: request metadata, error codes, user IDs (no PII), event types,
  service latency, failed job IDs. NEVER log: health metrics, body measurements,
  journal content, transcript text, mood or sentiment data, tokens, passwords, or any
  field tagged as sensitive in `packages/types/`. Log hygiene is enforced at the service
  level — not left to individual developers.

- **Validation:** Zod schemas in `packages/schemas/` are the single source of truth.
  Validation runs at the API gateway boundary and at service input boundaries.
  Never scattered in UI components. Frontend forms may use the same Zod schemas
  for field-level feedback, but that is display logic — authoritative validation
  is always server-side.

- **State management:** Server/remote state (workouts, programs, calendar, recipes,
  journal entries, dashboards) lives in TanStack Query — handles caching, background
  refresh, invalidation, and mutations. Client/interaction state (workout timer controls,
  audio cue toggles, workout player state, local draft entries, UX preferences) lives in
  Zustand stores scoped to the relevant feature. Zustand must NOT be used to cache
  server entities — that is TanStack Query's job. Feature-local transient state
  (e.g., a form's open/closed state) stays in local React state.

## External Integrations

| Service | Purpose | Owner module |
|---|---|---|
| Supabase Postgres | Primary database | services/* (each service owns its schema) |
| Supabase Storage | Media storage — journal assets, progress photos | services/ingestion, services/journaling |
| Keycloak | OIDC auth, roles, org membership, token issuance | services/identity |
| Matrix Synapse | Persistent chat rooms, message history, presence | services/messaging |
| LiveKit | Live coaching calls, live classes, realtime media | services/video |
| Cal.com | Scheduling primitives | services/calendar |
| Novu | Notification orchestration — reminders, alerts | services/notifications |
| faster-whisper | Speech-to-text transcription for voice journals | services/ingestion |
| Haystack | AI orchestration, RAG, journal intelligence pipeline | services/ingestion |
| vLLM | Server-side LLM inference for summaries and tags | services/ingestion |
| wger | Exercise catalog seed — read-only reference | services/training |
| HealthKit | iOS health data sync | packages/health-sync |
| Health Connect | Android health data sync (not Google Fit) | packages/health-sync |
| Expo EAS | Mobile build pipeline and E2E test automation | infra/ |
| AWS | Core production hosting, background workers, jobs | infra/ |

## What This Is Not

- This is NOT a generic calorie tracker or food logging app — recipe adherence within
  a coached plan is the model; exhaustive food logging edge cases are out of scope for v1
- This is NOT a telehealth EMR or clinical decision system — it is a coaching platform;
  AI is assistive, not diagnostic; no clinical workflows
- This is NOT a general social network or community platform — messaging and group
  spaces exist within the coach-client relationship, not as a standalone social product
- This is NOT a frontend that talks directly to databases or third-party services —
  all external communication routes through the API gateway and domain services
- This is NOT a flat type-scoped codebase — `components/`, `hooks/`, `services/` do
  not exist at the repo root; domain boundaries are enforced through folder structure
- The `nutrition` service does NOT handle medical dietary prescription — it supports
  habit-based guidance, meal adherence, and recipe delivery; prescription-level features
  require coach credential gating
- The `calendar` service does NOT replace personal productivity or calendar apps —
  it orchestrates coaching-defined schedule items; clients optionally project those
  outward to personal calendar via toggle, not the other way around
- The `ingestion` service does NOT make decisions — it produces transcripts, summaries,
  and tags as inputs for coaches and dashboards; all consequential actions remain
  human-initiated
- The `analytics` service does NOT share a data pipeline with health or journal stores —
  these are strictly separated; PostHog product events must never contain health fields
