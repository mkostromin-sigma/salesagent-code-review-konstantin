#!/usr/bin/env bash
#
# Install tooling for Cursor + optional Claude Code.
# Symlinks into ~/.local/bin, ~/.cursor/skills/, and (optionally) ~/.claude/.
# Never writes into the salesagent product tree.
#
# Push policy: this checkout's origin must be mkostromin-sigma/salesagent-code-review-konstantin.
# Do not add a push URL for KonstantinMirin/prebid-salesagent-pr-review.
#
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${HOME}/.local/bin"
CURSOR_SKILLS="${HOME}/.cursor/skills"
CLAUDE="${HOME}/.claude"
mkdir -p "$BIN" "$CURSOR_SKILLS"

link() { ln -sfn "$1" "$2"; printf '  %s -> %s\n' "$2" "$1"; }

echo "bin (on PATH):"
for f in "$REPO"/bin/*; do link "$f" "$BIN/$(basename "$f")"; done

echo "Cursor skill:"
# Whole-repo symlink so SKILL.md + bin/ + claude/ resolve from one discovery root
link "$REPO" "$CURSOR_SKILLS/salesagent-code-review-konstantin"

# Claude Code (optional — keep for dual tooling; Cursor does not require it)
if [ "${SKIP_CLAUDE_INSTALL:-0}" != "1" ]; then
  mkdir -p "$CLAUDE/agents" "$CLAUDE/skills"
  echo "claude agents:"
  for f in "$REPO"/claude/agents/*.md; do link "$f" "$CLAUDE/agents/$(basename "$f")"; done
  echo "claude skills:"
  for d in "$REPO"/claude/skills/*/; do link "${d%/}" "$CLAUDE/skills/$(basename "$d")"; done
else
  echo "claude install skipped (SKIP_CLAUDE_INSTALL=1)"
fi

echo
# Legacy WT_BASE config kept for PR_REVIEW_USE_LEGACY_WT_BASE=1 only.
# Default PR checkouts now use <salesagent>/.git/.worktrees/pr-<N> (see SKILL.md).
WT_BASE_DEFAULT="${PR_REVIEW_WT_BASE:-${HOME}/Documents/code/sigma}"
CFG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/pr-review-queue"
mkdir -p "$CFG_DIR"
cat > "$CFG_DIR/config" <<EOF
# pr-review-queue configuration (written by install.sh; edit freely).
# Default PR checkouts: <repo>/.git/.worktrees/pr-<N> (and pr-<N>-1, …).
# Legacy sibling base (only if PR_REVIEW_USE_LEGACY_WT_BASE=1):
: "\${PR_REVIEW_WT_BASE:=${WT_BASE_DEFAULT}}"
EOF
echo "PR lanes: <salesagent>/.git/.worktrees/pr-<N> (legacy WT_BASE=${WT_BASE_DEFAULT} if enabled)"

echo
case ":${PATH}:" in
  *":${BIN}:"*) : ;;
  *) echo "WARNING: ${BIN} is not on your PATH — add it so 'pr-review-queue' resolves (Cursor skill uses absolute \$REPO_ROOT/bin paths anyway)." ;;
esac

# Reminder: fork-only push
if git -C "$REPO" remote get-url origin >/dev/null 2>&1; then
  origin_url="$(git -C "$REPO" remote get-url origin)"
  case "$origin_url" in
    *mkostromin-sigma/salesagent-code-review-konstantin*)
      echo "origin OK (fork): $origin_url"
      ;;
    *)
      echo "WARNING: origin is not the mkostromin-sigma fork: $origin_url" >&2
      echo "         Push only to mkostromin-sigma/salesagent-code-review-konstantin." >&2
      ;;
  esac
fi
if git -C "$REPO" remote get-url upstream >/dev/null 2>&1; then
  echo "note: upstream remote exists — keep it fetch-only; never push upstream."
fi

echo "installed."
echo "Reload Cursor (skills) so /salesagent-code-review-konstantin appears."
