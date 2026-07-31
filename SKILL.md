---
name: salesagent-code-review-konstantin
description: >-
  Thin Cursor entry for salesagent-code-review-konstantin. Loads the plugin
  orchestrator skill. Goals: review (default), help. Use for
  /salesagent-code-review-konstantin or SDLC Phase 3 Reviewer C.
disable-model-invocation: true
---

# /salesagent-code-review-konstantin — shim

This file is the **skill-root discovery entry** when the repo is symlinked to
`~/.cursor/skills/salesagent-code-review-konstantin`.

1. Resolve `REPO_ROOT` (this checkout / plugin / skill symlink target).
2. **Read and execute** `$REPO_ROOT/skills/salesagent-code-review-konstantin/SKILL.md`
   completely (Cursor-idiomatic orchestrator: `agents/` + Task `subagent_type`).

If that file is missing, run `./install.sh` from the fork checkout and reload Cursor.

```text
/salesagent-code-review-konstantin help
/salesagent-code-review-konstantin <PR|wt|>
```
