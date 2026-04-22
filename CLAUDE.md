# Project: [PROJECT NAME]

## Purpose
[One paragraph: what this app does and who it's for.]

## Tech Stack
- Framework: [e.g. Next.js, React, Vue]
- Language: [e.g. TypeScript]
- Database: [e.g. Supabase, PostgreSQL, MongoDB]
- Hosting: [e.g. Vercel, Railway, AWS]
- Auth: [e.g. Supabase Auth, NextAuth, Clerk]
- Testing: [e.g. Vitest, Jest, Playwright]

## Architecture
[2-4 bullets describing the high-level structure.]
See ARCHITECTURE.md for the full map.

## Coding Standards
- Small functions (<50 lines)
- Explicit error handling, no silent catches
- Typed interfaces at all module boundaries
- No secrets in code — use env vars
- Input validation at the edge, not scattered through business logic

## Security Rules (non-negotiable)
- Never log PII, tokens, or passwords
- Never trust client input — validate server-side
- Parameterize all DB queries
- Rate-limit all public endpoints
- Follow OWASP Top 10:2025 (see owasp-security skill)

## Commands
- Install: `[npm install / pnpm install]`
- Dev: `[npm run dev]`
- Test: `[npm test]`
- Lint: `[npm run lint]`
- Build: `[npm run build]`

## Workflow Rules
- Always use Plan Mode for multi-file changes
- Never commit without tests passing
- One feature per branch
- Ask before destructive operations (db migrations, mass deletes, force pushes)

## Do Not
- Weaken existing security or validation
- Add dependencies without justification
- [PROJECT-SPECIFIC off-limits areas go here]