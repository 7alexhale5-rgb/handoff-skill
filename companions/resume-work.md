---
name: resume-work
description: Resume a project from saved state. Auto-activates when user says "where was I", "pick up where I left off", "resume", "continue the project", "what was I working on", or opens a session in a project with .planning/STATE.md.
---

# Resume Work — Session State Restore

Read `.planning/STATE.md` and present a concise briefing so the user can orient in 30 seconds and choose where to pick up.

---

## Step 1: Find State

Search for state in this order (stop at first hit):

### 1a: Local STATE.md (primary)

```
Glob: .planning/STATE.md
```

If found, read it.

### 1b: Parent directory check

If not in cwd, check if we're in a subdirectory:
```
Glob: ../.planning/STATE.md
Glob: ../../.planning/STATE.md
```

### 1c: Memory vault (fallback)

If no STATE.md found, search the memory vault for recent session states:
```bash
grep -rl "type: session" ~/Projects/memory-vault/sessions/ | head -5
```

Review results. Read the most recent matches.

Present results and ask which project to resume.

### 1d: No state found

If nothing found anywhere:
```
No saved state found in this directory.

Options:
- Navigate to your project directory and try again
- Run /init-project to start a new project
- Tell me what you were working on and I'll help you get oriented
```

Stop here.

---

## Step 2: Read Context (parallel)

Once STATE.md is found, gather orientation context in a single message:

```
Read: .planning/STATE.md
Read: .planning/ROADMAP.md
```

```bash
git log --oneline -10
git status --short
git branch --show-current
```

---

## Step 3: Staleness Check

Parse the `timestamp` field from STATE.md YAML frontmatter.

| Age | Action |
|-----|--------|
| < 24 hours | Fresh — use as-is |
| 1-7 days | Usable — note age, supplement with git log |
| > 7 days | Stale — warn user, lean heavily on git log for recent context |

**For stale state (>7 days):** Expand git log to `-30` and scan for relevant commits. Note: "State is {N} days old. Using git history to supplement."

**No timestamp field (old format):** Check file modification time via `stat`. Treat as stale if unsure.

---

## Step 4: Present Briefing

Format a concise briefing. Keep it SHORT — this is orientation, not a full report.

### Briefing Template

```
## Resuming: {project_name}

**Phase {N}/{total}:** {phase_name} — {phase_status}
**Last session:** {timestamp or "unknown"}
**Branch:** {git_branch}

### Where you left off
{1-3 sentences from STATE.md "Where We Left Off" section}

### What's next
1. {Next action from STATE.md}
2. {Following action}
3. {Action after that}

{If blockers exist:}
### Blockers
- {blocker}

{If uncommitted changes exist:}
### Uncommitted changes
{N} files modified — run `git status` for details

---
Where do you want to pick up?
```

### Rules for the Briefing

- **Never dump the full STATE.md.** Summarize it.
- **Never dump the full ROADMAP.md.** Reference it: "See `.planning/ROADMAP.md` for the full phase breakdown."
- **Include file paths** from STATE.md so the user can jump straight to code.
- **End with a question**, not a suggestion. Let the user decide where to start.
- **If git shows work not in STATE.md** (someone committed after pause): mention it. "Note: {N} commits found since last state save."

---

## Step 5: Ready for Work

After presenting the briefing, enter a ready state. The user will tell you what to do next. Common follow-ups:

| User says | Action |
|-----------|--------|
| "continue" / "pick up where I left off" | Start on the first "What's next" item |
| "plan the next phase" | Invoke `/plan-phase` |
| "verify this phase" | Invoke `/verify-phase` |
| "show me the full roadmap" | Read and present ROADMAP.md |
| "show progress" | Invoke `/project-progress` |
| Something else entirely | Follow the user's lead — they may have changed priorities |

Do NOT auto-start any work. Wait for direction.
