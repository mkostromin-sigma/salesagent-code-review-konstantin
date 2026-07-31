---
name: salesagent-code-review-konstantin
description: >-
  Cursor wrapper for the Konstantin multi-agent PR review (8 dimensional
  agents + synthesis). Runs Layer 1 via bin/pr-review-queue, fans out agents
  with Task, synthesizes drafts, writes ~/.cursor/reviews handoff. Chat-only /
  draft-only by default — never posts to GitHub unless the user explicitly
  opts in. Goals: review (default), help. Use for /salesagent-code-review-konstantin
  or when salesagent-sdlc Phase 3 launches Reviewer C.
disable-model-invocation: true
---

# /salesagent-code-review-konstantin — Cursor orchestrator

This skill is the **Cursor entry point** for the [salesagent-code-review-konstantin](https://github.com/mkostromin-sigma/salesagent-code-review-konstantin)
fork (upstream: KonstantinMirin's Claude Code PR-review tooling).

**Privacy:** personal setup. Do **not** commit skill docs into `prebid/salesagent`.
Push only to `mkostromin-sigma/salesagent-code-review-konstantin` — never to upstream.

### `help` (goal)

If args are only **`help`** / **`?`**: Russian cheat-sheet; **stop**.

```text
/salesagent-code-review-konstantin help
/salesagent-code-review-konstantin <PR>                 → review one PR (preferred / SDLC)
/salesagent-code-review-konstantin                      → working tree vs merge-base(main)
/salesagent-code-review-konstantin wt [--base REF] [path...]

8 agents + synthesis — Task model: inherit Auto ONLY (never pin Anthropic/GPT/…)
Layer 1: $REPO/bin/pr-review-queue manifest <N> | manifest wt
Review (canonical): ~/.cursor/reviews/pr-<N>-salesagent-code-review-konstantin.md
                 or ~/.cursor/reviews/wt-salesagent-code-review-konstantin.md
Archive when done:  mv → ~/.cursor/reviews/done/  (never rm; same as chris/nicolas)
Queue scratch only: ~/.cursor/reports/salesagent-code-review-konstantin/…/queue/<stamp>/
GitHub post: opt-in only (PR mode); wt mode cannot post
Checkout: Documents/code/sigma/salesagent-code-review-konstantin
```

## Resolve REPO_ROOT

Prefer the first path that contains `bin/pr-review-queue` and `claude/skills/pr-review-queue/SKILL.md`:

1. `/Users/maksim.kostromin/Documents/code/sigma/salesagent-code-review-konstantin`
2. Symlink target of `~/.cursor/skills/salesagent-code-review-konstantin` if it is a symlink
3. Otherwise Glob for `claude/skills/pr-review-queue/references/review-policy.md` and take the repo root two levels above `claude/skills/`

Verify:

- `$REPO_ROOT/bin/pr-review-queue`
- `$REPO_ROOT/claude/agents/review-dry.md`
- `$REPO_ROOT/claude/skills/pr-review-queue/references/review-policy.md`
- `$REPO_ROOT/claude/skills/pr-review-queue/references/synthesis.md`

If missing, stop and tell the user to clone the fork and run `./install.sh`.

## Hard gates

1. **Read-only on product code** unless the user explicitly asks for a fix.
2. **Never post to GitHub** unless the user clearly opts in this turn (`post to GitHub`, `pr-review-queue post`, etc.). SDLC Phase 3 never opts in.
3. **Model = Auto only (HARD).** On **every** Task (8 reviewers + synthesis): **omit** the `model` argument so subagents inherit the parent session (Auto). **Forbidden:** pinning `claude-opus-*`, `claude-sonnet-*`, `anthropic`, `gpt-*`, `composer-*`, `grok-*`, or any other slug. Do not “upgrade for quality.” Record in the chat/handoff validation line: `subagent_model: inherit (session/Auto)`.
4. **One PR per SDLC/Cursor review run** when invoked from `salesagent-sdlc` (pass the leaf PR). Standalone multi-PR queue mode is optional and out of SDLC Phase 3.
5. Fan-out agents via **Task** (mandatory). Do not invent a serial one-agent shortcut unless Task is unavailable — then say so and run sequentially.

## Target

Resolve one surface:

| User / SDLC arg | Mode | Layer 1 |
|---|---|---|
| PR number or PR URL | **PR** | `pr-review-queue manifest <N>` |
| empty, `wt`, `working-tree`, or explicit path(s) without a PR | **working-tree** | `pr-review-queue manifest wt [--base REF] [-- path...]` |

- **Salesagent workspace:** cwd for `pr-review-queue` must be a **salesagent** checkout (not this harness repo). Prefer Phase 2 `WT_PATH` if provided; else the open workspace root if it looks like salesagent (`AGENTS.md` / `CLAUDE.md` + `src/`).
- Set `PR_REVIEW_REPO=prebid/salesagent` when the cwd remote is a fork (so PR manifests target upstream PRs). For **wt** mode this is still used as the state-dir key; `gh` is not required for the diff itself.
- **Base ref (wt):** default tries `upstream/main`, `origin/main`, `main`, `master`. Override with `--base` or env `PR_REVIEW_BASE`.
- **Path filter (wt):** optional pathspecs after `wt` (or after `--`) limit the diff — same idea as chris/nicolas path/glob mode.
- **Empty diff (wt):** Layer 1 fails loud — nothing to review (clean tree vs base).

## Execute (align with upstream Layer 1–2; Cursor-adapted Layer 3)

### 0. Policy load

Read completely before fan-out:

- `$REPO_ROOT/claude/skills/pr-review-queue/references/review-policy.md`
- `$REPO_ROOT/claude/skills/pr-review-queue/references/synthesis.md`
- `$REPO_ROOT/claude/skills/pr-review-queue/references/review-voice.md` (for the synthesis Task)

Also skim `$REPO_ROOT/claude/skills/pr-review-queue/SKILL.md` for the canonical Layer 1–3 contract — this Cursor skill **implements** that contract with Cursor Task + personal handoff paths.

### 1. Layer 1 — manifest

From the **salesagent** tree (or `$WT_PATH`):

**PR mode:**

```bash
export PR_REVIEW_REPO="${PR_REVIEW_REPO:-prebid/salesagent}"
# Optional — only if Dev lane is NOT at …/.git/.worktrees/pr-<N>:
# export PR_REVIEW_CHECKOUT="$WT_PATH"
"$REPO_ROOT/bin/pr-review-queue" manifest <N>
```

Checkout resolution (PR mode) — **no env required** in the common case:

1. `PR_REVIEW_CHECKOUT` / `WT_PATH` if set (non-canonical Dev lane override)  
2. else `…/.git/.worktrees/pr-<N>` when `HEAD==tip` and **clean** (never hard-reset a dirty labor lane)  
3. else create/reuse `…/.git/.worktrees/pr-<N>-1`, `-2`, … (detached at tip; reset allowed only when clean)  
4. legacy `PR_REVIEW_WT_BASE/<repo>-pr<N>` only if `PR_REVIEW_USE_LEGACY_WT_BASE=1`

**Working-tree mode** (empty arg / `wt` / pathspecs):

```bash
export PR_REVIEW_REPO="${PR_REVIEW_REPO:-prebid/salesagent}"
# optional: export PR_REVIEW_BASE=upstream/main
"$REPO_ROOT/bin/pr-review-queue" manifest wt [--base REF] [-- path...]
```

Parse the printed/saved `manifest.json`. Capture absolute paths: `diff`, `changed_files`, `checkout`, `prior_comments`, `review_dir`. In wt mode `pr` is `null`, `mode` is `working-tree`, and `checkout` is the live salesagent ROOT (dirty tree — not a disposable sibling worktree).

If Layer 1 fails (auth, CONFLICTING, empty wt diff, missing `gh`/`jq` for PR mode), stop with the error — do not fake a review.

### 2. Layer 2 — eight agents (parallel Tasks)

In **one** PM/parent turn, launch **eight** Tasks (`generalPurpose` or equivalent). Each Task brief MUST:

1. Instruct: Read `$REPO_ROOT/claude/agents/review-<name>.md` completely and follow it.
2. Include the full text of `review-policy.md` **or** an absolute path + order to Read it first.
3. Pass absolute paths from the manifest: `diff`, `changed_files`, `checkout`, `prior_comments`.
4. Write findings only to `<review_dir>/review-<name>.md`.
5. Do not modify product source. Final chat line = one-line status only.
6. **Omit `model` (Auto inherit). Never pass a model slug.**

| Agent file | Dimension |
|---|---|
| `review-dry.md` | DRY / semantic duplication |
| `review-testing.md` | test quality |
| `review-python-practices.md` | Pythonic / Pydantic / SA2 / async |
| `review-consistency.md` | naming / error shape / conventions |
| `review-layering.md` | transport / business / repo / adapter |
| `review-adcp-grounding.md` | AdCP spec grounding |
| `review-ratchet-allowlists.md` | allowlists only shrink |
| `review-bdd-grounding.md` | BDD across transports |

Wait for all eight before synthesis.

### 3. Layer 2 — synthesis (one Task)

Launch one Task that:

1. Reads `synthesis.md` + `review-voice.md` + all `<review_dir>/review-*.md`
2. Writes `<review_dir>/FINDINGS.md`, `DRAFT-COMMENT.md`, `REVIEW-INLINE.json` per synthesis contract
3. Does **not** post
4. **Omit `model` (Auto inherit)** — same HARD gate as the eight reviewers

### 4. Canonical review file (`~/.cursor/reviews/` — HARD)

Same contract as chris / nicolas. **This is the review consumers use** (SDLC Phase 4,
local fix, archive). Do **not** treat the queue run dir as the review artifact.

| Mode | Path |
|---|---|
| PR | `~/.cursor/reviews/pr-<N>-salesagent-code-review-konstantin.md` |
| working-tree | `~/.cursor/reviews/wt-salesagent-code-review-konstantin.md` |

Trio naming (example PR 1812):

```text
~/.cursor/reviews/pr-1812-salesagent-code-review-chris.md
~/.cursor/reviews/pr-1812-salesagent-code-review-nicolas.md
~/.cursor/reviews/pr-1812-salesagent-code-review-konstantin.md
```

Rules:

1. Create `~/.cursor/reviews/` (and `done/`) if missing. Never write the review into the git repo.
2. On re-review of the same target, **overwrite** the same path (one current file per target) unless the user asks to keep history.
3. Write the file when actionable findings exist; if the synthesized list is empty — **do not** write it; say clean in chat only.
4. **Archive (HARD):** after all findings from that file are fixed and pushed, `mv` it to `~/.cursor/reviews/done/` — **never `rm`**. Outstanding work = root `reviews/` only; ignore `done/` as open work. (SDLC / Dev / Q1-B share this rule.)
5. Queue scratch (`FINDINGS.md` / drafts / HTML under `~/.cursor/reports/salesagent-code-review-konstantin/…`) is internal to the 8+1 fan-out — optional pointer in the review file; not archived by this skill; not what Phase 4 greps.

File contents (English):

- Severity-ordered findings. Map Konstantin's **Should fix** → `SHOULD-FIX` (SDLC fix-all: all severities mandatory; Notes / FOLLOW-UP only when clearly out-of-scope).
- Each finding: `file:line`, mechanism, evidence, why tests miss it, fix.
- Validation line: `subagent_model: inherit (session/Auto)`
- Optional: absolute path to the queue run dir for deep dive.

Optional (standalone, not SDLC): `"$REPO_ROOT/bin/pr-review-queue" artifact --open` for HTML. Do **not** require HTML for SDLC. **`post` is PR-only** — refuse for wt mode.

### 5. Present in chat

Short Russian status: finding counts + **review path under `~/.cursor/reviews/`**. Do not dump full FINDINGS into chat when the review file exists.

## Not this skill

| Invoke | Meaning |
|---|---|
| `/salesagent-code-review-chris` | 8-specialist salesagent harness (different agents/detectors) |
| `/salesagent-code-review-nicolas` | cheap dual-lens review |
| `/salesagent-code-review-nicolas-with-claude` | Opus dual-lens (cost OK first) |
| Claude Code `/pr-review-queue` | Same upstream skill under `~/.claude/` if `install.sh` Claude links exist |

## Install reminder

From `$REPO_ROOT`:

```bash
./install.sh
```

Symlinks `bin/*` → `~/.local/bin`, Cursor skill → `~/.cursor/skills/salesagent-code-review-konstantin`, and optionally Claude Code paths. Reload Cursor after install.
