---
name: root-cause-first
description: >-
  Find the mechanism before writing the fix. Measure the failing step instead of
  guessing at a plausible cause, and don't ship a patch you can't explain. Use
  when debugging anything that hangs, times out, intermittently fails, or
  "just stopped working". Triggers: "it's hanging", "it's slow", "times out",
  "intermittent", "flaky", "randomly fails", "not sure why", "let's just add a
  retry", "add a timeout", "try increasing".
---

# Root cause first

A fix you can't explain is a guess. Guesses that happen to make the symptom go
away are worse than no fix, because they end the investigation.

## The rule

**Before you edit anything, be able to finish this sentence:**
"The failure happens because ___, which I confirmed by ___."

If you can't, you are not ready to write code. Go measure.

## Instrument the steps, don't intuit them

When something hangs or is slow, time each step in isolation before concluding
which one is blocked:

```python
import time
t = time.monotonic()
step_one()
print(f"step_one: {time.monotonic() - t:.2f}s"); t = time.monotonic()
step_two()
print(f"step_two: {time.monotonic() - t:.2f}s")
```

Blocked I/O is the *intuitive* cause of a hang and frequently the wrong one. The
alternative — the work is genuinely large, or is being redone from scratch every
attempt — looks identical from outside and is fixed completely differently.

## Symptom patches that mask causes

These are legitimate tools and terrible first responses. Each one can convert a
diagnosable failure into an intermittent one:

| Patch | What it hides |
|---|---|
| Adding a timeout | Work that is slow for a real, fixable reason |
| Adding a retry | A non-idempotent operation, or a genuine error |
| `sleep()` before a check | A missing wait-for-condition; now it's flaky and slow |
| Bumping a limit | A leak or unbounded growth |
| try/except around the failure | The error message that told you the answer |

Use them **after** you understand the mechanism, as the deliberate right answer —
never as the first thing you try.

## Checkpoint long work before you tune it

If a process redoes everything from zero on each restart, every debugging attempt
pays full cost and every crash loses all progress. Save incremental progress
*first*, then investigate. This often makes the original symptom disappear on its
own, which is itself a diagnosis.

## Why this skill exists

A mail-triage service appeared to hang on startup: six-plus minutes, no errors,
no output. The obvious read was a blocked network call, and the first fix was a
connection timeout — plausible, and wrong.

Timing each step directly showed the connection was fine, under a second per
call. The real cause was a genuine backlog of 49 messages, each requiring a real
model API call, combined with a scan loop that saved progress **only once, at the
end of the whole batch**. Every restart mid-scan redid all 49 from zero. The fix
was to save after every message and background the startup scan so the server
responds immediately regardless of backlog size.

The timeout patch would have "worked" — it would have made the process fail
faster while never processing the backlog at all.

## Also

- Trace to the origin, not the crash site. The place that threw is usually
  downstream of where the bad value was created.
- Prefer condition-based waiting (`wait until X is true`) over duration-based
  waiting (`sleep 5`). Duration guesses are the main source of flaky tests.
- When a bug class appears once, grep for it everywhere before closing. The same
  root cause usually has siblings; see [verify-service-alive](../verify-service-alive/SKILL.md).
