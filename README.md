# Handoff — Claude Code Session Persistence Skill

A Claude Code skill that captures full session context into structured handoff documents, enabling seamless work continuation across session boundaries.

## The Problem

LLM context windows are ephemeral. When a Claude Code session ends — context depleted, end of day, or switching projects — all working knowledge evaporates. Starting a new session means re-reading files, re-establishing context, and losing the "why" behind decisions made minutes ago.

## The Solution

`/handoff` runs a 7-step pipeline that captures everything a future session needs to pick up exactly where you left off:

1. **Gather** — Scans the conversation for projects, files, decisions, status, blockers
2. **Git** — Checks working tree state, asks about uncommitted changes (never auto-commits)
3. **Session Summary** — Writes a searchable session record to a persistent memory vault
4. **Knowledge Graph** — Syncs entity relationships from the MCP memory graph (if available)
5. **Handoff Doc** — Generates a structured markdown document with specific file paths, decisions with rationale, and ordered next-actions
6. **Resume Prompt** — Produces a copy-pasteable prompt for the next session
7. **Lifecycle** — Offers `/compact` (compress context) or `/clear` (fresh start)

## Installation

### One-liner (recommended)

```bash
curl -sL https://raw.githubusercontent.com/7alexhale5-rgb/handoff-skill/main/install.sh | bash
```

This installs the core `/handoff` skill plus three companion skills (`/pause-work`, `/resume-work`, `/close-day`) into `~/.claude/skills/`. Existing companion skills are not overwritten.

### Manual install

```bash
mkdir -p ~/.claude/skills/handoff
curl -sL https://raw.githubusercontent.com/7alexhale5-rgb/handoff-skill/main/SKILL.md \
  -o ~/.claude/skills/handoff/SKILL.md
```

### From source

```bash
git clone https://github.com/7alexhale5-rgb/handoff-skill.git
cp handoff-skill/SKILL.md ~/.claude/skills/handoff/SKILL.md
# Optional companions:
for s in pause-work resume-work close-day; do
  mkdir -p ~/.claude/skills/$s
  cp handoff-skill/companions/$s.md ~/.claude/skills/$s/SKILL.md
done
```

Then invoke with `/handoff` in any Claude Code session.

### Customizing Vault Paths

The skill writes to two locations by default:

| Output | Default Path | Purpose |
|--------|-------------|---------|
| Session summary | `~/Projects/memory-vault/sessions/` | Cross-session search |
| Handoff doc (vault copy) | `~/Projects/memory-vault/handoffs/` | Persistent archive |
| Handoff doc (project copy) | `{project}/.planning/` | Immediate use on resume |

Edit the paths in `SKILL.md` Steps 3 and 5 to match your filesystem layout.

## How It Works

### The Handoff Document

The core output is a structured markdown file (`HANDOFF-{TOPIC}-{DATE}.md`) written to your project's `.planning/` directory:

```markdown
# Handoff: Auth Middleware Refactor
**Date**: 2026-03-26
**Session**: Migrated auth from Express middleware to Next.js proxy.ts
**Project**: my-app (`~/Projects/my-app/`)

## What Was Done
- Moved auth logic from `src/middleware/auth.ts` to `proxy.ts`
- Updated 12 route handlers to use new `auth()` helper
- Added Clerk integration test in `tests/auth.test.ts`

## Current State
- Auth working on all routes except `/api/webhooks/*`
- Webhook routes need CSRF exemption — blocked on Clerk docs

## What's Next
1. Add CSRF exemption for webhook routes in `proxy.ts`
2. Run full E2E suite: `npm run test:e2e`
3. Deploy to preview: `vercel deploy`

## Key Decisions
- Chose proxy.ts over middleware.ts: Next.js 16 rename, gains Node.js runtime

## Constraints & Gotchas
- Clerk middleware must be called before `auth()` works in Server Components
- Webhook signature verification requires raw body — don't parse JSON first

## Files Modified This Session
- `proxy.ts`: New file — auth middleware entry point
- `src/middleware/auth.ts`: Deleted (logic moved to proxy.ts)
- `tests/auth.test.ts`: New integration test
```

### Design Principles

- **Specificity over brevity** — File paths, function names, error messages. Not "made progress on auth."
- **60-line cap** — Handoff docs get loaded into context on resume. Every line costs tokens.
- **Ordered next-actions** — Item 1 in "What's Next" is always the immediate next action. The resume prompt references it directly.
- **Never auto-commit** — Git state is surfaced, not managed. The skill asks; you decide.
- **Dual-write pattern** — Every handoff writes to both the project directory (for immediate use) and a persistent vault (for cross-project search).
- **Omit empty sections** — No "Constraints: None." If a section has nothing, skip it.

### The Resume Prompt

Every handoff generates a ready-to-paste prompt:

```
Resume prompt (copy-paste after /compact or in new session):
───────────────────────────────────────────────────
I'm resuming work on my-app. Read the handoff doc at
~/Projects/my-app/.planning/HANDOFF-AUTH-REFACTOR-20260326.md
and continue from where we left off.
Focus on: Add CSRF exemption for webhook routes in proxy.ts.
───────────────────────────────────────────────────
```

## Companion Skills

The Handoff skill works best as part of a session lifecycle system. The companion skills in `companions/` show the full spectrum:

| Skill | Weight | Purpose | Pairs With |
|-------|--------|---------|------------|
| `pause-work` | Light | Machine-readable `STATE.md` snapshot | `resume-work` |
| **`handoff`** | **Heavy** | **Full narrative handoff + resume prompt** | **Manual resume** |
| `resume-work` | — | Reads STATE.md, presents 30-second briefing | `pause-work` |
| `close-day` | Ritual | End-of-day capture (3 questions + daily note) | `morning-brief` |

### When to Use Which

- **Quick pause, same project tomorrow** → `/pause-work`
- **Context depleted mid-task** → `/handoff`
- **Switching to a different project** → `/handoff`
- **Done for the day** → `/close-day` (which suggests `/handoff` if needed)
- **Resuming after any of the above** → `/resume-work` or paste the resume prompt

## Two-Tier Memory Architecture

The handoff skill feeds into a two-tier memory system:

```
T1: Hot Context (~/.claude/projects/*/memory/)
    MEMORY.md index (auto-loaded, 200-line cap)
    Topic files linked from the index

T2: Persistent Memory (~/Projects/memory-vault/)
    sessions/    ← Step 3 writes here
    handoffs/    ← Step 5 writes here (vault copy)
    planning/    ← Cross-session planning docs
    decisions/   ← Decision records
```

**T1** is automatically loaded into every Claude Code session (up to 200 lines). The MEMORY.md index links to handoff entries so they're discoverable.

**T2** is searched on-demand via `grep` on the vault path. This enables queries like "what was the last handoff for mission-control?" across all sessions.

## Adapting for Your Setup

The skill is designed to be customized. Key adaptation points:

1. **Vault paths** — Change `~/Projects/memory-vault/` to wherever you store persistent notes (Obsidian, Notion export, plain markdown)
2. **YAML frontmatter** — The `type`, `tags`, and `date` fields enable structured search. Adjust to match your note system's conventions.
3. **Knowledge graph** (Step 4) — Uses the MCP memory graph if available. Remove this step if you don't use the memory MCP server.
4. **CARL integration** (Step 7) — References CARL context brackets for compression recommendations. Remove if you don't use CARL.
5. **`.planning/` directory** — The GSD/planning-stack convention. Change to your project's preferred location for working docs.

## License

MIT
