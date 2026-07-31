---
name: salesagent-code-review-konstantin
description: >-
  Cursor-native multi-agent PR review (8 dimensional agents + synthesis) for
  Prebid Sales Agent. Layer 1 via bin/pr-review-queue; Layer 2 via Task with
  named subagent_type (agents/*.md); writes ~/.cursor/reviews. Chat/draft-only
  by default. Goals: review (default), help. Use for /salesagent-code-review-konstantin
  or when salesagent-sdlc Phase 3 launches Reviewer C.
disable-model-invocation: true
---

# /salesagent-code-review-konstantin — Cursor orchestrator

**Cursor-idiomatic layout** (same shape as chris):

```text
.cursor-plugin/plugin.json
agents/review-*.md          ← Task subagent_type names
skills/.../SKILL.md         ← this orchestrator
commands/...md              ← slash alias
bin/pr-review-queue         ← deterministic Layer 1 (manifest / draft post gate)
```

Claude Code paths under `claude/` are **optional dual-tooling** (opt-in via
`INSTALL_CLAUDE=1 ./install.sh`) — not required for Cursor / SDLC.

**Privacy:** personal setup. Do **not** commit skill docs into `prebid/salesagent`.
Push only to `mkostromin-sigma/salesagent-code-review-konstantin` — never to upstream.

### `help` (goal)

If args are only **`help`** / **`?`**: Russian cheat-sheet; **stop**.

```text
/salesagent-code-review-konstantin help
/salesagent-code-review-konstantin <PR>                 → review one PR (preferred / SDLC)
/salesagent-code-review-konstantin                      → working tree vs merge-base(main)
/salesagent-code-review-konstantin wt [--base REF] [path...]

8 agents + synthesis — Task(subagent_type=review-*) + Auto inherit (never pin models)
Layer 1: $REPO/bin/pr-review-queue manifest <N> | manifest wt
Review (canonical): ~/.cursor/reviews/pr-<N>-salesagent-code-review-konstantin.md
                 or ~/.cursor/reviews/wt-salesagent-code-review-konstantin.md
Archive when done:  mv → ~/.cursor/reviews/done/  (never rm; same as chris/nicolas)
Queue scratch only: ~/.cursor/reviews/.konstantin-queue/…/queue/<stamp>/
GitHub post: NEVER unless explicit opt-in this turn (draft-only default; SDLC never posts)
Checkout: Documents/code/sigma/salesagent-code-review-konstantin
```

## Resolve REPO_ROOT / HARNESS_ROOT

Prefer the first path that contains `bin/pr-review-queue` and `agents/review-dry.md`:

1. `/Users/maksim.kostromin/Documents/code/sigma/salesagent-code-review-konstantin`
2. Symlink target of `~/.cursor/plugins/local/salesagent-code-review-konstantin` or `~/.cursor/skills/salesagent-code-review-konstantin`
3. Otherwise Glob for `agents/review-dry.md` next to `bin/pr-review-queue`

Verify:

- `$REPO_ROOT/bin/pr-review-queue`
- `$REPO_ROOT/agents/review-dry.md`
- `$REPO_ROOT/claude/skills/pr-review-queue/references/review-policy.md`
- `$REPO_ROOT/claude/skills/pr-review-queue/references/synthesis.md`

If missing, stop and tell the user to clone the fork and run `./install.sh`.

## Hard gates

1. **Read-only on product code** unless the user explicitly asks for a fix.
2. **Never post to GitHub (HARD — same as SDLC / nicolas).** Chat + local review file only.
   Drafts (`DRAFT-COMMENT.md`, `REVIEW-INLINE.json`, HTML) stay local.
   - **Forbidden** unless the user clearly opts in **this same turn** (`post to GitHub`,
     `comment on the PR`, `publish findings to #N`, `pr-review-queue post` with intent to publish).
   - **Not** opt-in: naming a PR, “ready for review”, re-review, SDLC Phase 3, writing
     `~/.cursor/reviews/…`, `artifact --open`, or `post --preview`.
   - **SDLC Phase 3:** never opts in — do not run `pr-review-queue post` (except `--preview` if useful).
   - Bin default: `PR_REVIEW_DRAFT_ONLY=1` blocks real posts until `PR_REVIEW_ALLOW_POST=1`.
3. **Model = Auto only (HARD).** On **every** Task (8 reviewers + synthesis): **omit** the `model` argument so subagents inherit the parent session (Auto). **Forbidden:** pinning `claude-opus-*`, `claude-sonnet-*`, `anthropic`, `gpt-*`, `composer-*`, `grok-*`, or any other slug. Do not “upgrade for quality.” Record in the chat/handoff validation line: `subagent_model: inherit (session/Auto)`.
4. **One PR per SDLC/Cursor review run** when invoked from `salesagent-sdlc` (pass the leaf PR). Standalone multi-PR queue mode is optional and out of SDLC Phase 3.
5. Fan-out via **Task** with **named `subagent_type`** matching `agents/*.md` (mandatory — same as chris). Do **not** use `generalPurpose` + “read this agent file” as the primary path. Serial fallback only if Task is unavailable.
6. **Never run tests / quality locally (HARD).** Review = read diff + source only. **Forbidden** in orchestrator and every nested Task: `pytest`, `tox`, `make quality`, `make test*`, `./run_all_tests.sh`, `scripts/run-test.sh`, `agent-db`, Docker test stacks. Rely on GitHub Actions CI for execution. Bash/`rg`/`grep`/`wc` for inspection is OK.

## GitHub post vs local drafts (HARD GATE)

**Chat + `~/.cursor/reviews/…`. Never GitHub unless asked.**

Upstream `pr-review-queue post` can publish body + inline — that path is **opt-in only**.
Cursor / `salesagent-sdlc` stop after local drafts + the canonical review file. Do not
create, edit, submit, comment, approve, resolve, label, or otherwise mutate the PR on
GitHub from this skill unless the user explicitly opted in this turn.

## Target

Resolve one surface:

| User / SDLC arg | Mode | Layer 1 |
|---|---|---|
| PR number or PR URL | **PR** | `pr-review-queue manifest <N>` |
| empty, `wt`, `working-tree`, or explicit path(s) without a PR | **working-tree** | `pr-review-queue manifest wt [--base REF] [-- path...]` |

- **Salesagent workspace:** cwd for `pr-review-queue` must be a **salesagent** checkout (not this harness repo). Prefer Phase 2 `WT_PATH` if provided; else the open workspace root if it looks like salesagent (`AGENTS.md` / `CLAUDE.md` + `src/`).
- **GitHub repo:** resolved automatically — `upstream` remote → else `gh repo view` (fork parent if any) → else `origin`. Same fork layout as Dev/SDLC (`origin` = fork, `upstream` = `prebid/salesagent`). Do **not** export `PR_REVIEW_REPO` unless debugging an unusual remote layout.
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
# optional: export PR_REVIEW_BASE=upstream/main
"$REPO_ROOT/bin/pr-review-queue" manifest wt [--base REF] [-- path...]
```

Parse the printed/saved `manifest.json`. Capture absolute paths: `diff`, `changed_files`, `checkout`, `prior_comments`, `review_dir`. In wt mode `pr` is `null`, `mode` is `working-tree`, and `checkout` is the live salesagent ROOT (dirty tree — not a disposable sibling worktree).

If Layer 1 fails (auth, CONFLICTING, empty wt diff, missing `gh`/`jq` for PR mode), stop with the error — do not fake a review.

### 2. Layer 2 — eight agents (parallel Tasks)

You are in the **main session** (required — subagents cannot spawn subagents).

In **one** parent turn, launch **eight** Tasks **in parallel** (one message, multiple
Task calls). Set `subagent_type` to the specialist name below (maps to
`$REPO_ROOT/agents/<name>.md`). **Omit `model`** (Auto inherit).

Each Task brief MUST include:

1. Absolute `$REPO_ROOT` and order to follow the agent file for that `subagent_type`.
2. Absolute path to `review-policy.md` — Read it first (or paste if short enough).
3. Manifest paths: `diff`, `changed_files`, `checkout`, `prior_comments`, `review_dir`.
4. Write findings only to `<review_dir>/review-<name>.md`.
5. Do not modify product source. Never run tests / `make quality` / tox.
6. Final chat line = one-line status only.

| `subagent_type` | Dimension |
|---|---|
| `review-dry` | DRY / semantic duplication |
| `review-testing` | test quality (read-only — no pytest) |
| `review-python-practices` | Pythonic / Pydantic / SA2 / async |
| `review-consistency` | naming / error shape / conventions |
| `review-layering` | transport / business / repo / adapter |
| `review-adcp-grounding` | AdCP spec grounding |
| `review-ratchet-allowlists` | allowlists only shrink |
| `review-bdd-grounding` | BDD across transports |

Wait for all eight before synthesis.

### 3. Layer 2 — synthesis (one Task)

Launch **one** Task (`generalPurpose` is OK here — synthesis is not a named agent):

1. Reads `synthesis.md` + `review-voice.md` + all `<review_dir>/review-*.md`
2. Writes `<review_dir>/FINDINGS.md`, `DRAFT-COMMENT.md`, `REVIEW-INLINE.json` per synthesis contract
3. Does **not** post (no `pr-review-queue post` without user opt-in + `PR_REVIEW_ALLOW_POST=1`)
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
5. Queue scratch (`FINDINGS.md` / drafts / HTML under `~/.cursor/reviews/.konstantin-queue/…`) is internal to the 8+1 fan-out — optional pointer in the review file; not archived by this skill; not what Phase 4 greps (root `pr-*-*.md` only).

File contents (English):

- Severity-ordered findings. Map Konstantin's **Should fix** → `SHOULD-FIX` (SDLC fix-all: all severities mandatory; Notes / FOLLOW-UP only when clearly out-of-scope).
- Each finding: `file:line`, mechanism, evidence, why tests miss it, fix.
- Validation line: `subagent_model: inherit (session/Auto)`
- Optional: absolute path to the queue run dir for deep dive.

Optional (standalone, not SDLC): `"$REPO_ROOT/bin/pr-review-queue" artifact --open` for HTML. Do **not** require HTML for SDLC. **`post` is PR-only and draft-blocked by default** — refuse for wt mode; refuse real post without explicit user opt-in.

### 5. Present in chat

Short Russian status: finding counts + **review path under `~/.cursor/reviews/`**. Do not dump full FINDINGS into chat when the review file exists.

## Not this skill

| Invoke | Meaning |
|---|---|
| `/salesagent-code-review-chris` | 8-specialist salesagent harness (different agents/detectors) |
| `/salesagent-code-review-nicolas` | cheap dual-lens review |
| `/salesagent-code-review-nicolas-with-claude` | Opus dual-lens (cost OK first) |
| Claude Code `/pr-review-queue` | Optional — only if `INSTALL_CLAUDE=1 ./install.sh` |

## Install reminder

From `$REPO_ROOT`:

```bash
./install.sh                    # Cursor plugin + skill + bin (default)
INSTALL_CLAUDE=1 ./install.sh   # also link ~/.claude/ agents+skill
```

Reload Cursor after install so plugin agents appear as Task `subagent_type`s.
