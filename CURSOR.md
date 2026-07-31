# Cursor / salesagent-sdlc integration

## Idiomatic Cursor layout (same as chris)

```text
salesagent-code-review-konstantin/
  .cursor-plugin/plugin.json
  agents/review-*.md              # Task subagent_type = filename stem
  skills/salesagent-code-review-konstantin/SKILL.md   # orchestrator
  commands/salesagent-code-review-konstantin.md
  bin/pr-review-queue             # Layer 1 deterministic (not LLM)
  SKILL.md                        # thin skill-root shim → skills/…/SKILL.md
  claude/                         # OPTIONAL Claude Code dual path
```

Fan-out: `Task(subagent_type="review-dry"|…)` — **not** `generalPurpose` + paste agent md.
Claude Code install is **opt-in** (`INSTALL_CLAUDE=1`); Cursor / SDLC never need it.

## Install

```bash
./install.sh
# or non-interactive defaults already non-interactive:
./install.sh
INSTALL_CLAUDE=1 ./install.sh   # only if you also use Claude Code
```

- Plugin → `~/.cursor/plugins/local/salesagent-code-review-konstantin`
- Skill → `~/.cursor/skills/salesagent-code-review-konstantin`
- Bins → `~/.local/bin`

Reload Cursor after install.

## Phase 3 (SDLC)

| | Skill |
|--|-------|
| A | `salesagent-code-review-chris` |
| B | `salesagent-code-review-nicolas` |
| C | `salesagent-code-review-konstantin` (this) |

**Canonical review** (same trio; after fix+push: `mv` → `reviews/done/`, never `rm`):

- PR: `~/.cursor/reviews/pr-<N>-salesagent-code-review-konstantin.md`
- Working-tree: `~/.cursor/reviews/wt-salesagent-code-review-konstantin.md`

Queue scratch only:

`~/.cursor/reviews/.konstantin-queue/<owner>-<repo>/queue/<stamp>/`

**GitHub post (HARD):** never from Cursor/SDLC. Drafts local.
`PR_REVIEW_DRAFT_ONLY=1`; real post needs user opt-in + `PR_REVIEW_ALLOW_POST=1`.

**Model:** omit Task `model` (Auto inherit).

**Tests:** never run locally — GitHub Actions owns CI.

## Git remotes (HARD)

- **origin** = `mkostromin-sigma/salesagent-code-review-konstantin` only
- Do **not** push to `KonstantinMirin/prebid-salesagent-pr-review`
- Optional `upstream` may be fetch-only

## See also

- Root orchestrator: [`skills/salesagent-code-review-konstantin/SKILL.md`](skills/salesagent-code-review-konstantin/SKILL.md)
- Layer policy: [`claude/skills/pr-review-queue/references/review-policy.md`](claude/skills/pr-review-queue/references/review-policy.md)
