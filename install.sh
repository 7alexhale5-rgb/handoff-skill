#!/bin/bash
# Install handoff skill (and optional companions) into Claude Code
# Usage: curl -sL https://raw.githubusercontent.com/7alexhale5-rgb/handoff-skill/main/install.sh | bash

set -e

SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
REPO_URL="https://raw.githubusercontent.com/7alexhale5-rgb/handoff-skill/main"

echo "Installing handoff skill to $SKILLS_DIR..."

# Core skill
mkdir -p "$SKILLS_DIR/handoff"
curl -sL "$REPO_URL/SKILL.md" -o "$SKILLS_DIR/handoff/SKILL.md"
echo "  Installed: handoff"

# Companion skills (skip if already installed)
for skill in pause-work resume-work close-day; do
  if [ ! -f "$SKILLS_DIR/$skill/SKILL.md" ]; then
    mkdir -p "$SKILLS_DIR/$skill"
    curl -sL "$REPO_URL/companions/$skill.md" -o "$SKILLS_DIR/$skill/SKILL.md"
    echo "  Installed: $skill"
  else
    echo "  Skipped:   $skill (already exists)"
  fi
done

echo ""
echo "Done. Use /handoff in any Claude Code session."
echo ""
echo "Customize vault paths in $SKILLS_DIR/handoff/SKILL.md"
echo "if you don't use ~/Projects/memory-vault/."
