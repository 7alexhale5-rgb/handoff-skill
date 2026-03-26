---
name: pause-work
description: Save session state for cross-session handoff. Auto-activates when user says "pause", "stopping for now", "pick this up later", "save state", "end of session", or "switching contexts".
---

# Pause Work — Session State Save

Capture current project state into `.planning/STATE.md` so a future session can orient in 30 seconds via `/resume-work`.

---

## Step 1: Locate `.planning/` Directory

Search for `.planning/` in the current working directory:

```
Glob: .planning/ROADMAP.md
Glob: .planning/STATE.md
Glob: .planning/PROJECT.md
```

**If no `.planning/` directory exists:**
- Check if there's a ROADMAP.md or PROJECT.md anywhere nearby (user might be in a subdirectory)
- If still nothing: "No `.planning/` directory found. This skill saves state for projects initialized with `/init-project`. Want me to create a minimal STATE.md anyway?" If yes, create `.planning/` and proceed with a lightweight state file.

---

## Step 2: Gather Context

Fire these in parallel:

### 2a: Read existing planning artifacts

```
Read: .planning/ROADMAP.md (if exists)
Read: .planning/STATE.md (if exists — we'll overwrite but want current state)
```

### 2b: Git state

```bash
git status --short
git log --oneline -10
git diff --stat
```

### 2c: Current phase info

If ROADMAP.md exists, extract:
- Current phase number and name (look for first unchecked `- [ ]` phase, or the one marked `in-progress`)
- Total phases
- How many phases are complete

If phase directory exists, read the phase PLAN.md:
```
Glob: .planning/phases/**/PLAN.md
```
Read the current phase's PLAN.md to understand what's been planned.

---

## Step 3: Build STATE.md

Generate STATE.md with YAML frontmatter (machine-readable) + markdown body (human-readable).

### Template

```markdown
---
project: "{project_name}"
phase: {N}
phase_name: "{phase_name}"
phase_status: "{pending|planning|in-progress|verifying|complete}"
total_phases: {N}
phases_complete: {N}
last_step: "{description of last completed work}"
timestamp: "{ISO 8601 datetime}"
git_branch: "{current branch}"
---

# Session State

## Where We Left Off

{1-3 sentences describing current position — what was just done and what's immediately next}

## Progress

{Phase X of Y: {phase_name}}
{Brief status: what's done in this phase, what remains}

## What's Next

1. {Next immediate action}
2. {Following action}
3. {Action after that}

## Recent Decisions

{Only include if decisions were made this session — otherwise omit this section}
- {Decision}: {rationale}

## Blockers / Open Questions

{Only include if there are active blockers — otherwise omit this section}
- {Blocker or question}

## Uncommitted Changes

{Only include if git status shows changes — otherwise "Clean working tree"}
{List of modified/untracked files relevant to the project}
```

### Rules for STATE.md Content

- **Be specific, not generic.** "Implemented the webhook handler in `src/api/webhook.ts`" not "Made progress on the API."
- **Include file paths** for any work in progress — the resume session needs to know where to look.
- **Keep it under 50 lines.** This gets read into context on resume — every line costs tokens.
- **Omit empty sections.** No "Blockers: None" — just skip the section.
- **YAML frontmatter is for machines** (quick status checks). Markdown body is for humans (orientation).

---

## Step 4: Write STATE.md

Write the generated content to `.planning/STATE.md`.

If a previous STATE.md existed, overwrite it completely (state files are snapshots, not append logs).

---

## Step 5: Cache to Memory Vault

Write a session state snapshot to the memory vault for cross-session search:

```
Write:
  file_path: ~/Projects/memory-vault/sessions/{date}-state-{project-slug}.md
  content: |
    ---
    date: {date}
    type: session
    project: {project_name}
    tags: [memory, session, {project_name}, state]
    ---

    # Session State — {project_name}

    - Phase: {N}/{total} - {phase_name}
    - Status: {phase_status}
    - Last step: {last_step}
    - Branch: {git_branch}
    - Next: {first next action}
```

STATE.md on disk remains the primary store; this vault copy enables search across projects.

---

## Step 6: Confirm

Present a brief confirmation:

```
State saved to .planning/STATE.md

  Phase {N}/{total}: {phase_name} ({phase_status})
  Last: {last_step}
  Next: {first next action}

Run /resume-work in your next session to pick up where you left off.
```

Do NOT suggest committing STATE.md — it's a working file that changes every session.

**CARL bracket check:** If CARL context bracket is DEPLETED or CRITICAL (<40% remaining), suggest `/handoff` instead: "Context is low. Consider `/handoff` for a full session handoff rather than a lightweight pause."

---

## Edge Cases

- **No git repo**: Skip git-related fields. Set `git_branch: "n/a"`.
- **Multiple projects in session**: Ask which project to save state for if cwd is ambiguous.
- **Mid-task pause**: Capture the incomplete task clearly: "In progress: {task}. Not yet complete — {what remains}."
- **Already paused (STATE.md < 5 min old)**: "State was just saved {N} minutes ago. Overwrite with current state?" Proceed on yes.
