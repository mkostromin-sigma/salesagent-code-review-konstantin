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

Targets:

```bash
# From a salesagent checkout:
pr-review-queue manifest 1699              # auto: .git/.worktrees/pr-1699 or pr-1699-1…
pr-review-queue manifest wt                # working tree vs merge-base(main)
pr-review-queue manifest wt --base upstream/main -- src/core/
```

PR checkouts live under **`salesagent/.git/.worktrees/`** (same canon as
`salesagent-dev` / `ensure-pr-worktree.sh`). No `PR_REVIEW_CHECKOUT` export needed
when the Dev lane is the usual `pr-<N>` path.

| Path | Role |
|---|---|
| `pr-<N>` | Dev labor lane — reused when tip matches and tree is clean |
| `pr-<N>-1`, `pr-<N>-2`, … | Review-only alts when labor lane is dirty / wrong tip |

## salesagent-sdlc Phase 3

SDLC launches this skill as **Reviewer C** in parallel with:

| | Skill |
|--|-------|
| A | `salesagent-code-review-chris` |
| B | `salesagent-code-review-nicolas` |
| C | `salesagent-code-review-konstantin` (this) |

Handoff artifact (Phase 4 consumes):

- PR: `~/.cursor/reviews/pr-<N>-salesagent-code-review-konstantin.md`
- Working-tree (standalone / pre-PR): `~/.cursor/reviews/wt-salesagent-code-review-konstantin.md`

SDLC Phase 3 always uses **PR mode** (leaf PR from Phase 2). Working-tree mode is for standalone `/salesagent-code-review-konstantin` (empty/`wt`/paths) before a PR exists.

## Git remotes (HARD)

- **origin** = `mkostromin-sigma/salesagent-code-review-konstantin` only
- Do **not** push to `KonstantinMirin/prebid-salesagent-pr-review`
- Optional `upstream` may be fetch-only for syncing; push URL must stay unset / disabled

## See also

- Upstream Claude skill: `claude/skills/pr-review-queue/SKILL.md`
- Driver: `bin/pr-review-queue`
- Limitations after Cursor migration: ask the installer / see the SDLC migration report in chat when this skill was first wired
