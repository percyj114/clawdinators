---
name: distill-pr-intent
description: Side-effect-free distillation of a single OpenClaw PR into a short intent memo (stdout-only).
user-invocable: false
---

# Distill PR Intent (single PR, stdout-only)

## Goal

Given **one** PR number in **openclaw/openclaw**, output a short memo answering:

> What was the author trying to accomplish (motivation / problem framing / bet), as evidenced by the code change?

## Inputs

- Required: PR number (assume repo `openclaw/openclaw`).

## Rules

- **No external side effects**: no comments, labels, merges, pushes.
- Prefer **code-derived intent**. PR title/body are secondary.
- Do **not** guess. If intent is unclear from artifacts, say so.
- Keep output short + stable. No telemetry/timing in the memo.

## Output format (stdout)

```text
PR INTENT (openclaw#<PR>)

<free prose, up to ~5 sentences; keep under ~10 lines>
```

## Mechanical steps (deterministic)

1) Work in the OpenClaw repo worktree tooling:

```sh
cd /var/lib/clawd/repos/openclaw
scripts/pr review-init <PR>
scripts/pr review-checkout-pr <PR>

source .local/review-context.env
```

2) Gather diff artifacts:

```sh
git diff --name-status "$MERGE_BASE"..HEAD > .local/intent.name-status.txt
git diff --stat "$MERGE_BASE"..HEAD > .local/intent.stat.txt

# Patch budget: 200KB
patch_bytes=$(git diff "$MERGE_BASE"..HEAD | wc -c | tr -d ' ')
if [ "$patch_bytes" -le 200000 ]; then
  git diff "$MERGE_BASE"..HEAD > .local/intent.patch.txt
  echo PATCH_OK > .local/intent.patch-mode.txt
else
  : > .local/intent.patch.txt
  echo TOO_LONG > .local/intent.patch-mode.txt
fi
```

3) Distill intent:
- If `PATCH_OK`: infer intent from `.local/intent.patch.txt`.
- If `TOO_LONG`: infer intent from `.local/intent.name-status.txt` + `.local/intent.stat.txt`.

If multiple intents exist, mention 2–3 briefly.

If nothing coherent: say `Intent unclear: ...`.
