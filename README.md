# Prebid Sales Agent PR Review

Automated multi-agent code review for the [prebid/salesagent](https://github.com/prebid/salesagent)
repository. It **operates on** whatever git repo you run it in but is **not part of**
any project — it installs into `~/.local/bin` and `~/.claude/` by symlink and leaves no
footprint in the repos it reviews (worktrees and all review outputs live outside the
target tree).

Eight review agents each grade one dimension of a PR's diff; a synthesis step dedups
across them, verifies each finding against the checked-out code, and produces one
GitHub-ready review (a body comment plus inline comments anchored to changed lines).
The review is written to disk and rendered as a self-contained local HTML page — it
posts nothing until you approve it, per PR.

Reviews are written in the voice of a senior Python architect: pragmatic, direct, and
grounded in the mechanism of each defect rather than adjectives.

## Contents

```
bin/pr-review-queue                       # driver: scout/setup (Layer 1) + present/post (Layer 3)
bin/pr-radar                              # "which PRs need my attention" bucketing tool
bin/pr-review-artifact                    # deterministic HTML assembler for a run
claude/agents/review-*.md                 # the 8 review agents (see below)
claude/skills/pr-review-queue/SKILL.md    # /pr-review-queue — the one-command surface (drives Layer 2)
claude/skills/pr-review-queue/references/ # review-policy.md, synthesis.md, review-voice.md
```

The eight agents: `review-dry`, `review-testing`, `review-python-practices`,
`review-consistency`, `review-layering` (general code-quality dimensions), plus
`review-adcp-grounding`, `review-bdd-grounding`, `review-ratchet-allowlists`
(salesagent/AdCP-specific). All ship in this repo — no external plugin is required.

## Install

```bash
./install.sh          # symlinks bin/* -> ~/.local/bin, claude/agents + skills -> ~/.claude/*
```

Ensure `~/.local/bin` is on your `PATH`, and use [Claude Code](https://claude.com/claude-code)
so the skill and agents resolve. Editing a file here updates the live install (symlinks
point back at this repo, the source of truth).

## Use

From inside the target GitHub repo (the driver derives `owner/repo` from the remote):

```bash
pr-review-queue manifest [PR...]     # empty -> pulls candidates from pr-radar; skips CONFLICTING
pr-review-queue manifest wt [--base REF] [-- path...]   # working-tree mode (no PR; cannot post)
# then, in Claude Code or Cursor:
/pr-review-queue [PR...]             # Claude Code — runs all three layers; draft-only
/salesagent-code-review-konstantin [PR|wt|]   # Cursor skill
pr-review-queue artifact --open      # build + open the local review HTML for the newest run
pr-review-queue post <PR> --preview  # show the exact GitHub-review payload (body + inline)
pr-review-queue post <PR>            # post one review: body comment + inline comments on diff lines
```

`/pr-review-queue` drives the three layers itself: it prepares the manifest, fans out
the 8 agents per PR, synthesizes each draft, builds the artifact, and then stops for
your per-PR approval before posting.

### Where things go (never in the target repo)

- **Worktrees (PR mode):** `<salesagent>/.git/.worktrees/pr-<N>` (reuse Dev labor
  lane when clean + at tip), else `pr-<N>-1`, `pr-<N>-2`, … Review agents grep that
  tree; it must match the PR tip SHA the diff was built from. Pass
  `PR_REVIEW_CHECKOUT` / `WT_PATH` to force a path. Legacy
  `$PR_REVIEW_WT_BASE/<repo>-pr<N>` only with `PR_REVIEW_USE_LEGACY_WT_BASE=1`.
- **Canonical review (HARD):** `~/.cursor/reviews/pr-<N>-salesagent-code-review-konstantin.md`
  (same trio naming as chris/nicolas). When fixed+pushed: `mv` → `~/.cursor/reviews/done/` (never `rm`).
- **Queue scratch only:** `~/.cursor/reports/salesagent-code-review-konstantin/<owner>-<repo>/queue/<stamp>/`
  (`FINDINGS.md`, drafts, HTML). Override with `PR_REVIEW_HOME`. Not what Phase 4 greps.

Override with `PR_REVIEW_REPO`, `PR_REVIEW_HOME`, `PR_REVIEW_CHECKOUT` / `WT_PATH`,
`SALESAGENT_WORKTREES`, `PR_REVIEW_INCLUDE_CONFLICTING=1`.

## Review model

**Cursor / SDLC LLM:** every Task omits `model` (session **Auto** inherit). Never pin
Anthropic/GPT/Composer/Grok slugs from this path.

**Severity bar — one fix tier: Should fix.** No "nice to have", no "blocking". The line is
scope + is-it-a-smell, not importance: every in-scope defect or architectural smell (DRY,
type-safety, layer/boundary, missing coverage, single-transport grading) is a Should
fix, diagnosed to its root. Wired BDD across all four transports is the verification
bar — unit tests are not accepted as proof of functionality. Guard allowlists may only
shrink. A maintainer's still-unaddressed prior-round item leads its section, flagged
respectfully. Spec claims are grounded to the version the target repo pins.

The full bar is [`review-policy.md`](claude/skills/pr-review-queue/references/review-policy.md);
the synthesis + artifact contract is
[`synthesis.md`](claude/skills/pr-review-queue/references/synthesis.md); the final prose
pass is [`review-voice.md`](claude/skills/pr-review-queue/references/review-voice.md).
Edit those to tune behavior.

## License

[MIT](LICENSE). If you build on or redistribute a derivative, please cite this
repository as attribution — see [`NOTICE`](NOTICE).

## Cursor / personal fork notes

This checkout is the **mkostromin-sigma** fork
[`salesagent-code-review-konstantin`](https://github.com/mkostromin-sigma/salesagent-code-review-konstantin).

For Cursor + `salesagent-sdlc` Phase 3 (Reviewer C), see [`CURSOR.md`](CURSOR.md) and the root [`SKILL.md`](SKILL.md).

```bash
PR_REVIEW_INSTALL_NONINTERACTIVE=1 ./install.sh
```

Push only to the fork remote (`origin`). Do not push to the upstream
`KonstantinMirin/prebid-salesagent-pr-review` repository.
