#!/bin/bash
# Waterfall Lint Installer
# Copies the waterfall-lint skill and the gauntlet-critic agent into your
# Claude Code directories. Run from the folder containing this script.
#
# (Optional alternative: install as a plugin via
#  /plugin marketplace add alexmakarski/waterfall-lint
#  /plugin install waterfall-lint@waterfall-lint )

set -e

SKILLS_DIR="$HOME/.claude/skills"
AGENTS_DIR="$HOME/.claude/agents"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SKILLS="$SCRIPT_DIR/skills"
SOURCE_AGENT="$SCRIPT_DIR/agents/gauntlet-critic.md"

if [ ! -d "$SOURCE_SKILLS/waterfall-lint" ]; then
    echo "ERROR: No 'skills/waterfall-lint/' folder found next to this script."
    echo "Expected: $SOURCE_SKILLS/waterfall-lint"
    exit 1
fi

mkdir -p "$SKILLS_DIR" "$AGENTS_DIR"

if [ -d "$SKILLS_DIR/waterfall-lint" ]; then
    echo "Updating existing skill at $SKILLS_DIR/waterfall-lint"
    rm -rf "$SKILLS_DIR/waterfall-lint"
fi
cp -R "$SOURCE_SKILLS/waterfall-lint" "$SKILLS_DIR/waterfall-lint"
chmod +x "$SKILLS_DIR/waterfall-lint/"*.sh
echo "Installed skill: $SKILLS_DIR/waterfall-lint"

# The least-privilege critic agent. Shared with critic-gauntlet; do not
# clobber an existing copy silently.
if [ -f "$AGENTS_DIR/gauntlet-critic.md" ]; then
    if cmp -s "$SOURCE_AGENT" "$AGENTS_DIR/gauntlet-critic.md"; then
        echo "Agent already installed (identical): $AGENTS_DIR/gauntlet-critic.md"
    else
        echo "NOTE: $AGENTS_DIR/gauntlet-critic.md already exists and differs"
        echo "      (likely from critic-gauntlet). Left untouched. Any version of"
        echo "      it works for waterfall-lint as long as tools stay scoped to"
        echo "      Read, Grep, Glob, Write."
    fi
else
    cp "$SOURCE_AGENT" "$AGENTS_DIR/gauntlet-critic.md"
    echo "Installed agent: $AGENTS_DIR/gauntlet-critic.md"
fi

echo ""
echo "Done. Optional critics need keys (see skills/waterfall-lint/.env.example):"
echo "  XAI_API_KEY (Grok), GEMINI_API_KEY (Gemini), DEEPSEEK_API_KEY (DeepSeek),"
echo "  and the codex CLI for the Codex critic."
