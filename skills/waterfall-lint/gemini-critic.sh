#!/usr/bin/env bash
# Gemini adversarial critic invocation for the waterfall-lint skill (forked from critic-gauntlet).
#
# Usage: gemini-critic.sh <work-folder> <round-number> [--mode qa] (default: qa)
# Example: gemini-critic.sh /path/to/reviews/wfl-2026-08-14 1 --mode qa
#
# Reads brief-v<N>.md and proposal-v<N>.md from the work folder, and NOTHING
# else. Unlike critic-gauntlet, this fork does not append prior-round critiques;
# see the note above DATE= for why. The --mode flag selects the system-prompt rubric from
# modes/<mode>.system.txt (default: architecture). Builds the prompt, calls the
# Google AI Studio API, writes critique-v<N>-gemini.md.

set -euo pipefail

# --- Model pin ---------------------------------------------------------------
# Verified current 2026-07-10. Override per-run with GEMINI_MODEL=... in the env.
# Pro tier is preferred over Flash for adversarial reasoning (Gemini 3.5 shipped
# as Flash only; 3.1 Pro remains the reasoning tier). Re-pin when a newer Pro
# replaces it.
MODEL="${GEMINI_MODEL:-gemini-3.1-pro-preview}"
# -----------------------------------------------------------------------------

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <work-folder> <round-number> [--mode qa] (default: qa)" >&2
    exit 1
fi

DIR="$1"
ROUND="$2"
shift 2

MODE="qa"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --mode) MODE="$2"; shift 2 ;;
        *) echo "ERROR: unknown argument: $1" >&2; exit 1 ;;
    esac
done

# Locate the modes dir. Works whether the script sits alongside modes/ (skill folder)
# or in a sibling tools/ dir (plugin layout).
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODES_DIR=""
for cand in "$SELF_DIR/modes" "$SELF_DIR/../skills/critic-gauntlet/modes" "$SELF_DIR/../modes"; do
    [ -d "$cand" ] && { MODES_DIR="$(cd "$cand" && pwd)"; break; }
done
if [ -z "$MODES_DIR" ]; then
    echo "ERROR: modes/ dir not found near $SELF_DIR" >&2
    exit 1
fi
SYSTEM_FILE="$MODES_DIR/${MODE}.system.txt"
if [ ! -f "$SYSTEM_FILE" ]; then
    echo "ERROR: unknown mode '$MODE' (no $SYSTEM_FILE)" >&2
    exit 1
fi

if [ ! -d "$DIR" ]; then
    echo "ERROR: work folder not found: $DIR" >&2
    exit 1
fi

BRIEF="$DIR/brief-v${ROUND}.md"
PROPOSAL="$DIR/proposal-v${ROUND}.md"
OUTPUT="$DIR/critique-v${ROUND}-gemini.md"

if [ ! -f "$BRIEF" ]; then
    echo "ERROR: brief not found: $BRIEF" >&2
    exit 1
fi
if [ ! -f "$PROPOSAL" ]; then
    echo "ERROR: proposal not found: $PROPOSAL" >&2
    exit 1
fi

# Resolve a named API key from env, a repo/home .env, or common shell rc files.
resolve_key() {
    local var="$1"
    local val="${!var:-}"
    if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
    local candidates=(
        "$(cd "$(dirname "$0")" && pwd)/.env"
        "$HOME/.env"
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
    )
    for f in "${candidates[@]}"; do
        [ -f "$f" ] || continue
        val=$(grep -E "^(export[[:space:]]+)?${var}=" "$f" 2>/dev/null | tail -1 \
            | sed -E "s/^(export[[:space:]]+)?${var}=//" | tr -d '"' | tr -d "'")
        if [ -n "$val" ]; then printf '%s' "$val"; return 0; fi
    done
    return 1
}

if ! GEMINI_API_KEY="$(resolve_key GEMINI_API_KEY)"; then
    echo "ERROR: GEMINI_API_KEY not found in env, .env, or shell rc files (.zshrc/.bashrc/.bash_profile/.profile)" >&2
    echo "Set it with: export GEMINI_API_KEY=your-key" >&2
    exit 1
fi
export GEMINI_API_KEY

# NO prior-round context. This is the waterfall fork's deliberate divergence
# from critic-gauntlet, which appends round N-1 critiques here.
#
# In the gauntlet the proposal is stable across rounds, so a prior critique is
# context. In a waterfall the artifact is REGENERATED between passes, so a
# prior critique describes a page that no longer exists. Measured on a real
# pass: 5 of one critic's 14 findings quoted the previous pass's draft,
# strings that were not in the artifact it was given. The prior critique
# outweighed the artifact.
#
# The do-not-re-flag lists (accepted warts, already-refuted findings) travel
# inline in the brief instead, where they are the operator's curated text
# rather than another model's unverified output.

DATE=$(date +%Y-%m-%d)

# --- Editorial mode: real cold read (two-call protocol) -----------------------
# The editorial brief requires a first pass over the article WITHOUT the brief
# or atoms; a single stuffed prompt cannot deliver that. In editorial mode,
# call 1 sees the article alone and returns the cold-read log; call 2 gets the
# full materials plus those notes.
COLD_BLOCK=""
if [ "$MODE" = "editorial" ]; then
    COLD_SYSTEM="You are an independent editorial critic on your FIRST pass over an article. You have not seen the brief or source materials yet; that is deliberate. Read the article cold, top to bottom. Produce ONLY your cold-read log: where your attention flagged, where you got confused, where you stopped believing, whether you would have kept reading if it landed in your inbox. Quote the exact passages. No em-dashes. No double hyphens. No preamble, no summary of the article, no verdict."
    COLD_PAYLOAD=$(jq -n \
        --arg system "$COLD_SYSTEM" \
        --arg user "$(cat "$PROPOSAL")" \
        '{
            systemInstruction: {
                parts: [{text: $system}]
            },
            contents: [
                {role: "user", parts: [{text: $user}]}
            ],
            generationConfig: {
                temperature: 0.3,
                maxOutputTokens: 8000
            }
        }')
    COLD_RESPONSE=$(curl -sS "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$COLD_PAYLOAD")
    COLD_NOTES=$(echo "$COLD_RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')
    if [ -z "$COLD_NOTES" ]; then
        echo "ERROR: empty cold-read response from Google AI Studio API (editorial two-call, call 1)" >&2
        echo "$COLD_RESPONSE" >&2
        exit 1
    fi
    COLD_BLOCK="

===== YOUR COLD-READ NOTES (your own first pass, article only; reproduce verbatim as your cold-read log) =====
$COLD_NOTES"
fi
# -----------------------------------------------------------------------------

# System prompt = mode rubric with placeholders substituted. This critic's identity.
SYSTEM_PROMPT=$(cat "$SYSTEM_FILE")
SYSTEM_PROMPT="${SYSTEM_PROMPT//\{\{ROUND\}\}/$ROUND}"
SYSTEM_PROMPT="${SYSTEM_PROMPT//\{\{DATE\}\}/$DATE}"
SYSTEM_PROMPT="${SYSTEM_PROMPT//\{\{CRITIC\}\}/Gemini (Google AI Studio API direct)}"
SYSTEM_PROMPT="${SYSTEM_PROMPT//\{\{MODEL\}\}/$MODEL via Google AI Studio API direct}"

USER_PROMPT="Read everything below, then produce the critique.

===== BRIEF =====
$(cat "$BRIEF")

===== MATERIAL UNDER REVIEW (the target of critique) =====
$(cat "$PROPOSAL")
${COLD_BLOCK}

===== TASK =====
Produce the adversarial critique now. Markdown format. No preamble. Start with the heading and metadata, then follow the brief's output format."

PAYLOAD=$(jq -n \
    --arg system "$SYSTEM_PROMPT" \
    --arg user "$USER_PROMPT" \
    '{
        systemInstruction: {
            parts: [{text: $system}]
        },
        contents: [
            {role: "user", parts: [{text: $user}]}
        ],
        generationConfig: {
            temperature: 0.3,
            maxOutputTokens: 32000
        }
    }')

RESPONSE=$(curl -sS "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

CONTENT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // .error.message // "ERROR: no content"')

if [ -z "$CONTENT" ] || [ "$CONTENT" = "null" ] || [ "$CONTENT" = "ERROR: no content" ]; then
    echo "ERROR: empty or failed response from Google AI Studio API" >&2
    echo "Full response:" >&2
    echo "$RESPONSE" >&2
    exit 1
fi

echo "$CONTENT" > "$OUTPUT"

WORDS=$(echo "$CONTENT" | wc -w | tr -d ' ')
RECOMMENDATION=$( (echo "$CONTENT" | grep -iE '(ship.with.amendments|kill.{0,3}re.?formulate|ship.as.is)' || true) | head -1 | tr -d '*' | head -c 80)

echo "Gemini critique written to $OUTPUT"
echo "Words: $WORDS"
echo "Recommendation snippet: $RECOMMENDATION"
