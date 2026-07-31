# Cursor / salesagent-sdlc integration

This fork is installed beside the other personal review checkouts:

```text
~/Documents/code/sigma/salesagent-code-review-chris/
~/Documents/code/sigma/salesagent-code-review-nicolas/
~/Documents/code/sigma/salesagent-code-review-nicolas-with-claude/
~/Documents/code/sigma/salesagent-code-review-konstantin/   ← this repo
```

## Cursor discovery

```bash
./install.sh
# or non-interactive:
PR_REVIEW_INSTALL_NONINTERACTIVE=1 ./install.sh
```

- Symlinks this checkout to `~/.cursor/skills/salesagent-code-review-konstantin`
- Symlinks `bin/*` → `~/.local/bin`
- Optionally keeps Claude Code links under `~/.claude/` (`SKIP_CLAUDE_INSTALL=1` to skip)

Slash command: **`/salesagent-code-review-konstantin`** (see root [`SKILL.md`](SKILL.md)).

## salesagent-sdlc Phase 3

SDLC launches this skill as **Reviewer C** in parallel with:

| | Skill |
|--|-------|
| A | `salesagent-code-review-chris` |
| B | `salesagent-code-review-nicolas` |
| C | `salesagent-code-review-konstantin` (this) |

Handoff artifact (Phase 4 consumes):

`~/.cursor/reviews/pr-<N>-salesagent-code-review-konstantin.md`

SDLC never posts Konstantin drafts to GitHub.

## Git remotes (HARD)

- **origin** = `mkostromin-sigma/salesagent-code-review-konstantin` only
- Do **not** push to `KonstantinMirin/prebid-salesagent-pr-review`
- Optional `upstream` may be fetch-only for syncing; push URL must stay unset / disabled

## See also

- Upstream Claude skill: `claude/skills/pr-review-queue/SKILL.md`
- Driver: `bin/pr-review-queue`
- Limitations after Cursor migration: ask the installer / see the SDLC migration report in chat when this skill was first wired
