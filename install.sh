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
case ":${PATH}:" in
  *":${BIN}:"*) : ;;
  *) echo "WARNING: ${BIN} is not on your PATH — add it so 'pr-review-queue' resolves." ;;
esac
echo "installed."
