---
name: close-day
description: Use when wrapping up a work session — says "I'm done for the day", "wrap up", "close out", "end of day", or wants to capture what happened and prepare a handoff before stopping.
---

# Close Day

End-of-day capture: what happened -> what's pending -> daily note draft -> memory vault sync.

## Steps

### 0. Pre-flight

If `.planning/STATE.md` exists and phase is in-progress, suggest: "You have an active project phase. Run `/pause-work` first to save state?"

### 1. Capture (3 Questions)

Ask one at a time:

1. "What did you ship or finish today? (be specific)"
2. "What's blocked or still in flight?"
3. "What's the first thing you're doing next session?"

### 2. Deliver Closeout Summary

```
## Session Closeout — {date}

**Shipped**: {Q1}
**In flight / blocked**: {Q2}
**Next first move**: {Q3}
```

### 3. Draft Daily Note Block

Display for paste into today's daily note:

```markdown
## Session Closeout

**Shipped**
{Q1 as bullet list}

**In flight**
{Q2 as bullet list}

**Tomorrow: first move**
{Q3}
```

Say: "Copy this into today's daily note."

### 4. Sync to Memory Vault

```
Write:
  file_path: ~/Projects/memory-vault/sessions/{YYYY-MM-DD}-closeout.md
  content: |
    ---
    date: {YYYY-MM-DD}
    type: session
    project: general
    tags: [memory, session, closeout]
    ---

    # Closeout — {YYYY-MM-DD}

    **Shipped**: {Q1}
    **In flight**: {Q2}
    **Next**: {Q3}
```

### 5. Suggest Save

Say: "Run `/sc` to persist session context before you go."

## Rules

- Keep it fast — this is the END of a session, not a planning session
- Don't ask more than 3 questions
