---
name: handoff
description: Full session handoff — saves state, generates handoff doc + resume prompt, offers compact/clear. Use when ending a session, context is depleted, or switching tasks. Heavier than /sc.
---

# Handoff — Session Persist + Handoff Doc + Resume Prompt

Combines `/sc` persist logic with handoff doc generation and a ready-to-paste resume prompt. Use when you need deep context preservation across session boundaries.

**When to use**: Context depleted (CARL DEPLETED), ending a session with work to continue, or switching between projects mid-stream. If you also use `/closeout-stack`, that is the end-of-session step (it runs this persist logic and adds commit, ship and receipt); use `/handoff` alone for a mid-stream context swap.

> **Reserved section: `## Retro Findings`.** A closeout pipeline may append a `## Retro Findings` section to the handoff doc after this skill returns. It is load-bearing for the next session's pickup. Never overwrite, move or delete it. If one already exists when this skill writes to an existing handoff doc, leave it intact.

---

## Step 1: Gather Session Context

Review the conversation to identify:
- **Project(s)** worked on (name + path)
- **Files** created or modified
- **Decisions** made and their rationale
- **Current task status** (complete, in-progress, blocked)
- **Pending items** / what's next
- **Blockers** or gotchas the next session needs

---

## Step 2: Handle Git

For each project directory touched:

```bash
git status --short
git log --oneline -5
```

If there are uncommitted changes, ask:

> You have uncommitted changes in `{project}`. Want to commit before handoff?

Never auto-commit. If user declines, note uncommitted files in the handoff doc.

---

## Step 3: Write Session Summary to Memory Vault

Write a session summary to the persistent memory vault:

```
Write:
  file_path: ~/Projects/memory-vault/sessions/{YYYY-MM-DD}-{topic-slug}.md
  content: |
    ---
    date: {YYYY-MM-DD}
    type: session
    project: {name}
    tags: [memory, session, {name}]
    ---

    # Session — {YYYY-MM-DD} — {brief topic}

    ## Summary
    {2-3 sentences of what was accomplished}

    ## Changes
    - `{file}`: {what changed}

    ## Decisions
    - {decision}: {rationale}

    ## Pending
    - {what's next}
```

The handoff doc on disk (Step 5) is the primary artifact; this vault copy enables cross-session search.

---

## Step 4: Sync Knowledge Graph

If `mcp__memory__read_graph` is available:
- Read the graph for any important entities/relations from this session
- Note key relationships in the handoff doc (Step 5) for context

If unavailable, skip silently.

---

## Step 5: Generate Handoff Doc

Determine the project scope path for the file location:
- If working in a specific project under `~/Projects/{name}/`, use that project's `.planning/` directory
- Otherwise, use `~/.claude/projects/{project-scope}/memory/`

Write to `HANDOFF-{TOPIC}-{YYYYMMDD}.md`:

```markdown
# Handoff: {Topic}
**Date**: {YYYY-MM-DD}
**Session**: {brief session description}
**Project**: {project name} (`{project path}`)

## What Was Done
- {Completed work with specific file paths}

## Current State
- {Where things stand — be specific}
- {Running services, deployed changes, test results}

## What's Next
1. {Immediate next action}
2. {Following action}
3. {Action after that}

## Key Decisions
- {Decision}: {rationale}

## Constraints & Gotchas
- {Things the next session needs to know}
- {Environment quirks, API limits, known issues}

## Files Modified This Session
- `{path}`: {what changed}
```

### Handoff Doc Rules
- **Keep a Retro Findings section.** If the file (or its vault copy) already exists, read it first. Copy any `## Retro Findings` section verbatim onto the end of the new document before you write it.
- **Be specific.** File paths, function names, error messages — not vague summaries.
- **"What's Next" is ordered.** Item 1 is the very next thing to do.
- **Omit empty sections.** No "Constraints: None."
- **Keep it under 60 lines.** This gets read into context on resume.

Also write a copy to the memory vault for cross-session search:

```
Write:
  file_path: ~/Projects/memory-vault/handoffs/{YYYY-MM-DD}-{topic-slug}.md
  content: |
    ---
    date: {YYYY-MM-DD}
    type: handoff
    project: {name}
    tags: [memory, handoff, {name}]
    ---

    {full handoff doc content}
```

---

## Step 6: Generate Resume Prompt

**Required**: every handoff, however it was triggered, prints a standalone resume prompt to the user. It is the main deliverable they copy into the next session, so never leave it only inside the handoff file.

Build a ready-to-paste prompt and display it as a fenced code block:

```
cd {project-dir} && Resume {project}: {next task}.
Read the handoff at {handoff_file_path}.
{one line on what was just finished, with the commit hash if there is one}.
{numbers this session produced, if any: tests run and passed, files changed}.
NEXT: {the specific next action, naming the skill to run}.
```

**Rules for resume prompts:**

- A fenced code block, so it copies in one click.
- The first line moves into the project folder.
- Take the commit hash from `git log -1 --format=%h` in the project folder. Leave it out when no commit was made this session.
- Only include numbers this session actually measured. Never invent counts; for a research or writing session, drop that line.
- The NEXT line names the exact skill to run, for example `/planning-stack <task>`.
- Five or six lines at most. It gets pasted raw into a new session.
- Name the handoff file path so the new session can read the full context.
- When `/closeout-stack` runs this skill, print only one resume prompt for the session, in this format.

---

## Step 7: Prompt to Compact or Clear

Present actionable options:

```
Session persisted. Choose how to continue:

  1. /compact — Compress context (keeps conversation, reduces tokens)
  2. /clear  — Fresh context (use the resume prompt above)
  3. Continue — Skip compression (not recommended if context is low)
```

If CARL bracket info is available, include it: "Context is at ~{N}% — compression recommended."

---

## Edge Cases

- **Multiple projects in one session**: Generate one handoff doc per project. Resume prompt references the primary project (ask if ambiguous).
- **No meaningful work done**: Skip the handoff doc. Just run the persist steps (3-4) and say "No substantial work to hand off."
- **Already handed off (handoff doc < 10 min old)**: "Handoff was just generated {N} minutes ago. Regenerate?" Proceed on yes.
- **No git repo**: Skip Step 2. Note "not a git repo" in handoff doc.
- **GSD project with `.planning/`**: Write handoff to `.planning/HANDOFF-{TOPIC}-{DATE}.md` alongside existing STATE.md. Both serve different purposes (STATE = machine-readable snapshot, HANDOFF = human-readable narrative).
