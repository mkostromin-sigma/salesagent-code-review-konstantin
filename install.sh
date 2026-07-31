#!/usr/bin/env bash
#
# Install Cursor-native plugin + skill + bins.
# Claude Code links are OPT-IN (INSTALL_CLAUDE=1).
#
# Push policy: origin = mkostromin-sigma/salesagent-code-review-konstantin only.
#
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${HOME}/.local/bin"
CURSOR_SKILLS="${HOME}/.cursor/skills"
LOCAL_PLUGINS="${HOME}/.cursor/plugins/local"
PLUGIN_DEST="${LOCAL_PLUGINS}/salesagent-code-review-konstantin"
mkdir -p "$BIN" "$CURSOR_SKILLS" "$LOCAL_PLUGINS"

link() { ln -sfn "$1" "$2"; printf '  %s -> %s\n' "$2" "$1"; }

require_file() {
  if [ ! -e "$1" ]; then
    echo "error: missing required file: $1" >&2
    exit 1
  fi
}

require_file "${REPO}/.cursor-plugin/plugin.json"
require_file "${REPO}/skills/salesagent-code-review-konstantin/SKILL.md"
require_file "${REPO}/agents/review-dry.md"
require_file "${REPO}/bin/pr-review-queue"

agent_count="$(find "${REPO}/agents" -maxdepth 1 -name 'review-*.md' | wc -l | tr -d ' ')"
if [ "${agent_count}" -lt 8 ]; then
  echo "error: expected ≥8 agents/review-*.md, found ${agent_count}" >&2
  exit 1
fi

echo "bin (on PATH):"
for f in "$REPO"/bin/*; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in
    __pycache__|*.pyc) continue ;;
  esac
  link "$f" "$BIN/$(basename "$f")"
done

echo "Cursor plugin (agents → Task subagent_type):"
if [ -L "${PLUGIN_DEST}" ] || [ -e "${PLUGIN_DEST}" ]; then
  if [ -L "${PLUGIN_DEST}" ]; then
    current="$(readlink "${PLUGIN_DEST}")"
    if [ "${current}" = "${REPO}" ]; then
      echo "  Already installed: ${PLUGIN_DEST} → ${REPO}"
    else
      rm "${PLUGIN_DEST}"
      link "$REPO" "$PLUGIN_DEST"
    fi
  else
    echo "error: ${PLUGIN_DEST} exists and is not a symlink. Remove it and re-run." >&2
    exit 1
  fi
else
  link "$REPO" "$PLUGIN_DEST"
fi

echo "Cursor skill (slash / discovery):"
link "$REPO" "$CURSOR_SKILLS/salesagent-code-review-konstantin"

# Claude Code — opt-in only (Cursor does not need it)
if [ "${INSTALL_CLAUDE:-0}" = "1" ]; then
  CLAUDE="${HOME}/.claude"
  mkdir -p "$CLAUDE/agents" "$CLAUDE/skills"
  echo "claude agents (opt-in):"
  for f in "$REPO"/claude/agents/*.md; do link "$f" "$CLAUDE/agents/$(basename "$f")"; done
  echo "claude skills (opt-in):"
  for d in "$REPO"/claude/skills/*/; do link "${d%/}" "$CLAUDE/skills/$(basename "$d")"; done
else
  echo "claude install skipped (default). Opt-in: INSTALL_CLAUDE=1 ./install.sh"
fi

echo
CFG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/pr-review-queue"
mkdir -p "$CFG_DIR"
REVIEWS_HOME="${HOME}/.cursor/reviews"
QUEUE_HOME="${REVIEWS_HOME}/.konstantin-queue"
mkdir -p "$REVIEWS_HOME/done" "$QUEUE_HOME"
WT_BASE_DEFAULT="${PR_REVIEW_WT_BASE:-${HOME}/Documents/code/sigma}"
cat > "$CFG_DIR/config" <<EOF
# pr-review-queue configuration (written by install.sh; edit freely).
# Canonical review: ~/.cursor/reviews/pr-<N>-salesagent-code-review-konstantin.md
# (archive with mv → ~/.cursor/reviews/done/). Queue scratch (FINDINGS/drafts/HTML):
: "\${PR_REVIEW_HOME:=${QUEUE_HOME}}"
# Draft-only by default (Cursor/SDLC). Real post needs user opt-in + PR_REVIEW_ALLOW_POST=1:
: "\${PR_REVIEW_DRAFT_ONLY:=1}"
# Default PR checkouts: <repo>/.git/.worktrees/pr-<N> (and pr-<N>-1, …).
# Legacy sibling base (only if PR_REVIEW_USE_LEGACY_WT_BASE=1):
: "\${PR_REVIEW_WT_BASE:=${WT_BASE_DEFAULT}}"
EOF
echo "agents  -> ${agent_count} under agents/ (Task subagent_type)"
echo "review  -> ~/.cursor/reviews/pr-<N>-salesagent-code-review-konstantin.md (archive -> reviews/done/)"
echo "scratch -> ${QUEUE_HOME}/<owner>-<repo>/queue/<stamp>/"
echo "post    -> blocked by default (PR_REVIEW_DRAFT_ONLY=1); opt-in: PR_REVIEW_ALLOW_POST=1"
echo "PR lanes: <salesagent>/.git/.worktrees/pr-<N>"

echo
case ":${PATH}:" in
  *":${BIN}:"*) : ;;
  *) echo "WARNING: ${BIN} is not on PATH — add it so \`pr-review-queue\` resolves (skill prefers PATH, not abs bin paths)." ;;
esac

if git -C "$REPO" remote get-url origin >/dev/null 2>&1; then
  origin_url="$(git -C "$REPO" remote get-url origin)"
  case "$origin_url" in
    *mkostromin-sigma/salesagent-code-review-konstantin*)
      echo "origin OK (fork): $origin_url"
      ;;
    *)
      echo "WARNING: origin is not the mkostromin-sigma fork: $origin_url" >&2
      ;;
  esac
fi
if git -C "$REPO" remote get-url upstream >/dev/null 2>&1; then
  echo "note: upstream remote exists — keep it fetch-only; never push upstream."
fi
echo "installed. Reload Cursor so /salesagent-code-review-konstantin + agent types appear."
