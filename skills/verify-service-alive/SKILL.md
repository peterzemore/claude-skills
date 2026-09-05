---
name: verify-service-alive
description: >-
  After moving, renaming, or reconfiguring anything a background service depends
  on, prove every affected service and timer still actually runs and still
  produces its output. Use after directory reorganizations, project renames,
  venv or dependency rebuilds, path or config edits, and unit-file changes.
  Triggers: "moved the project", "renamed", "reorganize", "restructure", "the
  service", "systemd", "cron", "timer", "scheduled job", "backup", "it stopped
  working", "203/EXEC", "was that still running?".
---

# Verify a service is still alive

Background services fail **silently**. Nothing pages you when a nightly job stops
running — you find out when you need the thing it was supposed to produce and it
isn't there.

## After any move, rename, or path change

1. **Find every reference to the old path, not just the one you were working on.**
   ```bash
   grep -rl "/old/path" ~/.config/systemd/user/ /etc/systemd/system/ 2>/dev/null
   crontab -l 2>/dev/null | grep -F "/old/path"
   systemctl --user list-units --all | grep -i <project>
   ```
   Fix all of them in one pass.
2. **Reload, restart, and check status:**
   ```bash
   systemctl --user daemon-reload
   systemctl --user restart <unit>
   systemctl --user status <unit> --no-pager
   ```
3. **Prove it with a functional check, not a status word.** `active (running)`
   means a process exists. It does not mean the process works. Make a real
   request and check the real output: an HTTP 200 from the actual endpoint, a
   row written, a report generated, a ledger that still balances.

## Timers and scheduled jobs need a different check

A timer that is `enabled` and `waiting` can have failed on every single firing.
Check the **last successful run**, not the schedule:

```bash
systemctl --user list-timers --all
journalctl --user -u <unit> --since "7 days ago" | tail -40
ls -lt /path/to/the/output/    # newest artifact — is it actually recent?
```

If the newest output is older than the interval, the job has been failing since
that date, whatever the timer says.

## The venv / entry-point trap (`203/EXEC`)

Python venvs bake **absolute paths** into console-script shebangs at install
time. Move or rename the directory and every entry point breaks:

- systemd symptom: `status=203/EXEC`
- shell symptom: `<venv>/bin/<tool>: exec: <old-path>: not found`

The fix is always to rebuild the venv in place — never hand-patch shebangs:

```bash
rm -rf .venv && python3 -m venv .venv && pip install -e .
```

This applies to *every* script in `bin/`, not just `pip`.

## Unit-file gotchas that cause silent or confusing failures

- **`ExecStart=` word-splits on whitespace.** A path containing spaces needs
  quoting: `ExecStart="%h/path with spaces/.venv/bin/python3" server.py`.
  `WorkingDirectory=` is a single-value directive and does not.
- **`StartLimitIntervalSec=` / `StartLimitBurst=` belong in `[Unit]`, not
  `[Service]`.** Misplaced, systemd ignores them with only a log warning — no
  hard error, so it looks like it worked.
- **Don't run a managed service by hand.** A manual foreground instance collides
  on the same port with the systemd-managed one and produces baffling results.
  Use `systemctl --user {start,stop,restart,status}` and `journalctl --user -u`.

## Why this skill exists

A directory reorganization moved a project. Its systemd unit still pointed at the
old path, so the app had been silently inactive since the move — unnoticed
because nothing urgent needed it. Fixing that unit surfaced a second failure
(`203/EXEC`) from the stale venv shebang.

Then the real lesson: **a separate backup unit had the identical stale-path bug
and was missed**, because the search stopped at the unit under investigation.
That backup had failed every night for over a week — zero successful database
backups — before anyone noticed. The same stale-venv-path bug hit three different
projects in a single session after the same reorganization.

Check every unit that references the old path. Check that its output is recent.
