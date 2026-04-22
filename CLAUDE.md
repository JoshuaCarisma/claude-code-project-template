# Project: Body By Carisma — Client Coaching Platform

## Purpose
A mobile-first health and fitness coaching platform for Body By Carisma clients. The app 
delivers a Trainerize-class coaching experience — workouts, programs, habits, nutrition, 
scheduling, messaging, and live video — layered with a first-class journaling system 
(text/audio/video), AI-assisted insights, wearable health sync, and multi-surface analytics 
dashboards for clients, coaches, and admins. Built to start as a direct-to-consumer coaching 
product and evolve into a scalable, licensable coaching system with clinic-facing potential.

## Tech Stack
- **Language / Framework**: TypeScript / React Native + Expo (prebuild / custom dev client)
- **Database**: Supabase Postgres + Supabase Storage (MVP); media abstraction kept clean for 
  SeaweedFS migration if volume or compliance requires it
- **Hosting**: AWS (core production backend, chat/video workers, background jobs); 
  Vercel (marketing site / lightweight web surfaces only); 
  Railway (prototypes and internal environments); 
  Expo EAS (mobile build + test automation)
- **Testing**: Jest + React Native Testing Library (mobile unit/integration), 
  Maestro (mobile E2E), Playwright (web/admin E2E), Vitest (backend/web package unit tests)
- **Auth**: Keycloak (role-based; ZITADEL if multi-org B2B becomes first-order)
- **Chat**: Matrix Synapse (persistent rooms, history, presence)
- **Video**: LiveKit (live coaching, classes, realtime media)
- **Scheduling**: Cal.com + native calendar insertion (EventKit on iOS, Calendar Provider 
  on Android)
- **Notifications**: Novu
- **AI / Transcription**: faster-whisper (speech-to-text), Haystack (orchestration/RAG), 
  vLLM (server-side inference)
- **Exercise seed**: wger (catalog/primitives only — product logic stays custom-owned)
- **Health sync**: HealthKit (iOS), Health Connect (Android) — Google Fit is deprecated, 
  do not use for new Android work
- **Analytics**: PostHog (product events) — scoped strictly, never mixed with health/journal 
  data stores

## Architecture (current state)
Seven modular service domains — this is not a monolith:
- **Identity & Permissions**: Auth, profiles, coach/client/admin roles, consent, org 
  membership, feature permissions. Must anticipate multi-coach and multi-org use.
- **Training Engine**: Exercise library (seeded by wger), workout/program builder, phases, 
  logging, RPE, progress photos, 1:1 / group / hybrid / at-home delivery modes.
- **Nutrition Engine**: Macro/calorie targets, meal tracking, meal photos + coach feedback, 
  food journal, recipes, meal planner, shopping lists, habit-based nutrition coaching. 
  Permission-tiered: general guidance → meal review → full meal planning.
- **Journaling & Media**: Text/audio/video journal entries, upload pipeline, transcription 
  (faster-whisper), AI summaries, tagging, searchable entries, coach-review mode, 
  mood/sentiment overlays. Journaling is a first-class data input — not a notes field.
- **Messaging & Community**: Direct coach–client messaging, group channels, 
  cohort/community spaces, media sharing, announcements, challenge threads.
- **Video & Calls**: Live coaching calls, live classes, async recorded coaching, 
  on-demand video, form review, scheduled calls.
- **Calendar & Scheduling**: App-native schedule objects first; clients can optionally 
  project coach items into personal calendar (toggle on/off). Never use device calendar 
  as system of record.
- **Analytics**: Event-driven dashboards for clients (progress/trends), coaches 
  (adherence/risk), and admins (business metrics/retention). All major user actions 
  emit time-stamped events.

→ See ARCHITECTURE.md for full domain model, entity map, and data flow decisions.

## Coding Standards
- TypeScript strict mode throughout — typed interfaces at all module boundaries
- camelCase for variables/functions; PascalCase for components, types, and interfaces; 
  kebab-case for file names
- Small, focused functions — keep under 50 lines; split on complexity, not just length
- Explicit error handling — no silent catches; always log or surface errors meaningfully
- Input validation at the API/service boundary using Zod — never trust client data inside 
  business logic
- No secrets in code — all credentials and keys via environment variables only
- Media access always abstracted behind a storage service interface — never call 
  Supabase Storage directly from UI components
- ESLint + Prettier enforced; run lint before every commit
- Health data and journal data must never share a store or pipeline with product 
  analytics (PostHog)

## Security Rules (non-negotiable)
- Never log PII, tokens, passwords, health metrics, or journal content
- Never trust client input — validate and sanitize server-side before any processing
- Parameterize all database queries — no raw string interpolation in SQL or Supabase queries
- Rate-limit all public-facing endpoints
- Follow OWASP Top 10:2025
- All health data handling must comply with privacy-by-design: explicit consent before 
  sync, data minimization, deletion/export flows, strict RBAC, and audit logging
- AI-generated outputs (summaries, insights, recommendations) must never cross into 
  diagnostic territory — human review required before any health-risk-adjacent output 
  reaches the client
- Nutrition meal-planning features must remain permission-tiered — full prescription-style 
  features require coach credential gating
- If a workload handles health-adjacent data on behalf of a clinic or business associate, 
  flag for BAA review before proceeding
- Auth changes of any kind require explicit approval before implementation

## Commands
- **Install**: `npm install`
- **Dev (mobile)**: `npx expo start`
- **Dev (with custom dev client)**: `npx expo start --dev-client`
- **Test (unit/integration)**: `npx jest`
- **Test (mobile E2E)**: `maestro test`
- **Test (web E2E)**: `npx playwright test`
- **Lint**: `npx eslint . --ext .ts,.tsx`
- **Format**: `npx prettier --write .`
- **Build (mobile)**: `eas build`
- **Build check (local)**: `npx expo export`

## Workflow Rules
- Use Plan Mode for all multi-file changes before writing any code
- Never commit with failing tests or lint errors
- One feature per branch — PRs must be focused and reviewable
- Ask before any destructive operations: DB migrations, mass deletes, storage bucket 
  changes, force pushes, dropping tables
- Ask before adding any new dependency — state the reason and confirm no lighter 
  alternative exists
- Never implement full live-class or multi-org features without scoping against the 
  phased roadmap (MVP → Phase 2 → Phase 3)
- AI prompt changes must be versioned and reviewed — no silent prompt edits in production

## Do Not
- Use Google Fit APIs for any new Android health integration — Health Connect only
- Use MinIO — it is archived as of Feb 2026; use Supabase Storage or a vetted alternative
- Use Dendrite as the Matrix homeserver — Matrix Synapse only for production
- Use Expo Go for development — always use the custom dev client (native modules required)
- Mix health/journal data with product analytics pipelines or PostHog event streams
- Access or render health data without confirmed user consent on record
- Implement diagnostic-level AI outputs — summaries and insights only; flag any 
  request that edges toward clinical interpretation
- Modify auth, RBAC, or consent logic without explicit approval
- Weaken, bypass, or remove existing security checks or input validation
- Commit secrets, tokens, API keys, or credentials to version control

## Project Notes
- The media abstraction layer must be kept clean from day one — Supabase Storage is 
  MVP infrastructure, not a permanent ceiling. SeaweedFS is the escape hatch for 
  large-scale journaling video volume or compliance-driven data-location requirements.
- The product has a clear HIPAA-adjacent compliance path (clinic partnerships, employer 
  programs). AWS was chosen for core production specifically for its HIPAA-eligible 
  services. Design data handling accordingly even before HIPAA formally applies.
- Journal entries are a first-class product input — a voice note should flow into 
  transcription, tagging, coach review, analytics, and AI summarization. Never treat 
  media journal entries as miscellaneous file uploads.
- wger is a seed for the exercise catalog only. Do not build product workflows around 
  wger's structure — all coaching logic is custom-owned.
- The coaching model is behavior-driven and corrective, not generic fitness-app. AI 
  must support human coaching decisions, not replace them.
