# Claude Code Project Template

## Quick Start — New Project
```bash
cp -r ~/Projects/_starter-kit ~/Projects/[new-project-name]
cd ~/Projects/[new-project-name]
git init && git add . && git commit -m "chore: project foundation"
```
Then in Claude Code:
1. `"Generate a CLAUDE.md for this project"`
2. `"Generate an ARCHITECTURE.md for this project"`
3. `"Generate a MEMORY.md for this project"`

Then update the hook path in `.claude/settings.json` to match this project's location.
Push to GitHub. Start building.

---

## Every Session
**Start:** Claude auto-loads CLAUDE.md + ARCHITECTURE.md + MEMORY.md — just start your task

**Building:** `/clear` → describe task → review plan → implement → code-reviewer → commit

**End:** `/project:wrap-up` → `git commit && git push` → `/clear`

---

## The Three Files
| File | Purpose | Updated by |
|---|---|---|
| CLAUDE.md | Rules + stack | You, when things change |
| ARCHITECTURE.md | Codebase map | Re-run skill every 3 months |
| MEMORY.md | Where you left off | `/project:wrap-up` every session |

---

*See below for the full SOP with every detail.*

---



# Claude Code Project Template — SOP
Standard Operating Procedure for starting and running any new project.

---

## One-Time Global Setup
*(Already done — never repeat this)*

- [x] OWASP skill installed at `~/.claude/skills/owasp-security/`
- [x] Trail of Bits skills installed at `~/.claude/skills/`
- [x] Custom skills installed at `~/.claude/skills/`:
  - `codebase-setup` — generates CLAUDE.md
  - `architecture-doc` — generates ARCHITECTURE.md
  - `memory-doc` — generates and updates MEMORY.md

---

## Starting a New Project

### Step 1 — Copy the template
```bash
cp -r ~/Projects/_starter-kit ~/Projects/[new-project-name]
cd ~/Projects/[new-project-name]
```

### Step 2 — Update the hook path
Open `.claude/settings.json` and update the absolute path in the
PreToolUse hook to match this project's location:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/joshuacarisma/Projects/[new-project-name]/.claude/hooks/block-dangerous.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npm run lint --silent || true"
          }
        ]
      }
    ]
  }
}
```

### Step 3 — Initialize git
```bash
git init
git add .
git commit -m "chore: project foundation from starter kit"
```

### Step 4 — Create the GitHub repo
Go to github.com → New repository → name it → then:
```bash
git remote add origin https://github.com/JoshuaCarisma/[new-project-name].git
git push -u origin master
```

### Step 5 — Generate CLAUDE.md
Open the project in VS Code, open Claude Code, then say:
```
Generate a CLAUDE.md for this project
```
Claude triggers the codebase-setup skill, asks you questions about
your stack and goals, and produces a complete CLAUDE.md.

### Step 6 — Generate ARCHITECTURE.md
```
Generate an ARCHITECTURE.md for this project
```
Claude triggers the architecture-doc skill, explores the codebase
structure, and produces ARCHITECTURE.md. Review and fill in any
[NEEDS INPUT] placeholders.

### Step 7 — Generate MEMORY.md (Create Mode)
```
Generate a MEMORY.md for this project
```
Claude triggers the memory-doc skill in Create Mode. It reads your
CLAUDE.md and ARCHITECTURE.md first to avoid redundant questions,
then interviews you for anything it couldn't infer. Produces a
complete MEMORY.md for session one.

### Step 8 — Commit the generated files
```bash
git add .
git commit -m "docs: add CLAUDE.md, ARCHITECTURE.md, and MEMORY.md"
git push
```

### Step 9 — Start building
Enable Plan Mode before any multi-file work:
- Press Shift+Tab twice in Claude Code, OR
- Start your prompt with /plan

---

## Every Coding Session

### Starting a session
Claude Code automatically loads at startup:
- CLAUDE.md — your rules and stack
- ARCHITECTURE.md — the codebase map
- MEMORY.md — where you left off

No re-explaining needed. Just describe your next task.

### During a session — building a feature
Always use Plan Mode for anything touching more than one file:

1. `/clear` if switching tasks or starting fresh
2. Describe what you want to build
3. Claude triggers the planner subagent → produces a written plan
4. Review and edit the plan before approving
5. Claude implements — OWASP skill auto-activates on security-relevant code
6. When done: `Use the code-reviewer subagent on this change`
7. If touching auth, health data, or payments:
   `Use the security-reviewer subagent`
8. Run tests → if passing, commit

### Ending a session — always do this

**Step 1 — Run the wrap-up command:**
```
/project:wrap-up
```
This triggers the memory-doc skill in Update Mode. Claude reads the
full conversation, then surgically updates MEMORY.md with:
- Current status and phase
- Exact resume point for next session
- New decisions (appended — never edited or deleted)
- New solved problems (appended — never edited or deleted)
- Tech debt added this session
- Completed items moved to What's Been Built
- One-line session note with today's date

**Step 2 — Commit everything:**
```bash
git add .
git commit -m "your commit message"
git push
```

**Step 3 — Clear context:**
```
/clear
```

---

## When to Use Each Subagent

| Subagent | When to invoke |
|---|---|
| planner | Before any multi-file change or new feature |
| code-reviewer | After every implementation, before committing |
| security-reviewer | Before merging anything touching auth, client data, or payments |

Invoke by telling Claude Code:
```
Use the [planner / code-reviewer / security-reviewer] subagent
```

---

## When to Use Each Skill

| Skill | When to run | How to invoke | Output |
|---|---|---|---|
| codebase-setup | Once at project kickoff | "Generate a CLAUDE.md" | CLAUDE.md |
| architecture-doc | Once after stack decided | "Generate an ARCHITECTURE.md" | ARCHITECTURE.md |
| architecture-doc | Every 3 months or after major restructure | "Refresh my ARCHITECTURE.md" | Updated ARCHITECTURE.md |
| memory-doc | Once at start of first session | "Generate a MEMORY.md" | MEMORY.md |
| memory-doc | End of every coding session | `/project:wrap-up` | Updated MEMORY.md |

---

## Maintaining the Three Core Files

| File | What it is | Who updates it | How often |
|---|---|---|---|
| CLAUDE.md | Rules, stack, standards | You manually | When stack or rules change |
| ARCHITECTURE.md | Codebase map | Re-run architecture-doc skill | Every 3 months or after major restructure |
| MEMORY.md | Session log, decisions, state | `/project:wrap-up` | End of every session |

**Troubleshooting rule:**
- Claude keeps making the same mistake → fix goes in `CLAUDE.md`
- Claude doesn't know where something lives → update `ARCHITECTURE.md`
- Claude doesn't know where you left off → run `/project:wrap-up` more consistently

---

## wrap-up.md Command Reference
*(Lives at `.claude/commands/wrap-up.md` — do not modify)*

```
---
description: End of session update — fills in MEMORY.md with what happened today
---

Review our entire conversation this session and update MEMORY.md:

1. Current Status — update phase and one-line summary of where things stand
2. Resume Here — write the specific next task, branch name, and relevant files
3. Decisions Log — add any decisions we made with date, reasoning, and tradeoff
4. Solved Problems — add anything we debugged or figured out
5. Tech Debt — add any shortcuts we knowingly took
6. What's Been Built — move anything completed from What's Left
7. Session Notes — add one line summary of today dated YYYY-MM-DD

Be specific in Resume Here — future me needs to know exactly where to start.
Do not remove any existing entries. Only add new ones.
```

---

## Reference — Project File Structure

```
[project-name]/
├── CLAUDE.md                    # Rules + stack — loaded every session
├── ARCHITECTURE.md              # Codebase map — loaded every session
├── MEMORY.md                    # Session state — loaded every session
├── .claude/
│   ├── settings.json            # Hook config — update absolute path per project
│   ├── agents/
│   │   ├── planner.md           # Plans before code — uses Opus
│   │   ├── code-reviewer.md     # Reviews after implementation — uses Sonnet
│   │   └── security-reviewer.md # Audits before merge — uses Opus
│   ├── commands/
│   │   └── wrap-up.md           # /project:wrap-up — triggers memory-doc update
│   ├── hooks/
│   │   └── block-dangerous.sh   # Blocks destructive bash commands
│   └── skills/                  # Project-specific skills if any
└── src/
    └── your app code
```

---

## Global File Structure

```
~/.claude/
└── skills/
    ├── owasp-security/          # Auto-activates on security-relevant code
    ├── codeql/                  # Trail of Bits static analysis
    ├── differential-review/     # Trail of Bits code review
    ├── insecure-defaults/       # Trail of Bits insecure pattern detection
    ├── sarif-parsing/           # Trail of Bits SARIF output processing
    ├── semgrep/                 # Trail of Bits semgrep analysis
    ├── codebase-setup/          # Generates CLAUDE.md
    ├── architecture-doc/        # Generates ARCHITECTURE.md
    └── memory-doc/              # Generates + updates MEMORY.md
```

---

## Quick Reference Card

```
NEW PROJECT:    cp template → update hook path in settings.json →
                git init → push to GitHub →
                "Generate CLAUDE.md" → "Generate ARCHITECTURE.md" →
                "Generate MEMORY.md" → start building

SESSION START:  Claude auto-loads CLAUDE.md + ARCHITECTURE.md + MEMORY.md
                Just describe your next task

BUILDING:       /clear → describe task → review plan → implement →
                code-reviewer → security-reviewer if needed → commit

SESSION END:    /project:wrap-up → git commit → git push → /clear
```