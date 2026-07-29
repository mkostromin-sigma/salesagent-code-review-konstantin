#!/usr/bin/env bash
#
# Symlink this repo's tooling into the live locations so it's picked up by PATH
# and by Claude Code's global config, in every project — without copying anything
# into a project tree. Re-run any time (idempotent).
#
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${HOME}/.local/bin"
CLAUDE="${HOME}/.claude"
mkdir -p "$BIN" "$CLAUDE/agents" "$CLAUDE/skills"

link() { ln -sfn "$1" "$2"; printf '  %s -> %s\n' "$2" "$1"; }

echo "bin (on PATH):"
for f in "$REPO"/bin/*; do link "$f" "$BIN/$(basename "$f")"; done
echo "claude agents:"
for f in "$REPO"/claude/agents/*.md; do link "$f" "$CLAUDE/agents/$(basename "$f")"; done
echo "claude skills:"
for d in "$REPO"/claude/skills/*/; do link "${d%/}" "$CLAUDE/skills/$(basename "$d")"; done

echo
# Worktree base — where per-PR checkouts live, as siblings of your other clones:
# <base>/<repo>-pr<NNNN>. It is machine-specific, so configure it here. An explicit
# PR_REVIEW_WT_BASE in the environment always overrides this at run time.
WT_BASE_DEFAULT="${PR_REVIEW_WT_BASE:-${HOME}/projects}"
if [ -t 0 ] && [ -z "${PR_REVIEW_WT_BASE:-}" ]; then
  printf 'Worktree base for per-PR checkouts [%s]: ' "$WT_BASE_DEFAULT"
  read -r ans || true
  [ -n "${ans:-}" ] && WT_BASE_DEFAULT="${ans/#\~/$HOME}"
fi
CFG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/pr-review-queue"
mkdir -p "$CFG_DIR"
cat > "$CFG_DIR/config" <<EOF
# pr-review-queue configuration (written by install.sh; edit freely).
# Where per-PR worktrees are created: <base>/<repo>-pr<NNNN>. An explicit
# PR_REVIEW_WT_BASE in your environment overrides this.
: "\${PR_REVIEW_WT_BASE:=${WT_BASE_DEFAULT}}"
EOF
echo "worktree base -> ${WT_BASE_DEFAULT}  (config: ${CFG_DIR}/config)"

echo
case ":${PATH}:" in
  *":${BIN}:"*) : ;;
  *) echo "WARNING: ${BIN} is not on your PATH — add it so 'pr-review-queue' resolves." ;;
esac
echo "installed."
