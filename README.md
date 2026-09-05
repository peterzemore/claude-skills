# claude-skills

Four small [Claude Code](https://claude.com/claude-code) skills, each one codified
from a real production incident rather than from general best practice.

They exist because the same four failures kept recurring across a set of live
systems — a storefront theme, a bookkeeping app, and a fleet of always-on agent
services. Each skill is the shortest thing that would have prevented its
incident.

| Skill | Prevents |
|---|---|
| [`scoped-deploy`](skills/scoped-deploy/SKILL.md) | A full-directory push shipping someone else's unfinished work to production |
| [`verify-ui-visually`](skills/verify-ui-visually/SKILL.md) | Declaring a UI fix verified by reading the state flag instead of the rendered pixels |
| [`verify-service-alive`](skills/verify-service-alive/SKILL.md) | A background service or nightly job silently dead for weeks after a path change |
| [`root-cause-first`](skills/root-cause-first/SKILL.md) | Patching a plausible-sounding cause that isn't the real one |

## Design notes

These are deliberately **not** a methodology. There's no mandated workflow, no
subagent orchestration, no hooks, and nothing that runs on its own. Each skill is
a single Markdown file that loads only when its trigger conditions match, so the
context cost when they're idle is a one-line description each.

Every skill follows the same shape:

1. **The rule** — what to do, in imperative steps you can actually follow.
2. **The mechanics** — the specific commands, selectors, or code that implement it.
3. **Why this skill exists** — the incident, including what the wrong fix was and
   how long the false confidence lasted.

Section 3 is the part that makes them work. A skill that says "verify your fixes"
is ignored; a skill that says "this exact check returned `true` three times while
the panel was covering the page" changes behavior.

Incidents are described de-identified — no hostnames, credentials, internal IDs,
or names.

## Install

```bash
git clone https://github.com/<you>/claude-skills.git
cd claude-skills
./install.sh            # symlinks into ~/.claude/skills/ (stays in sync with the repo)
./install.sh --copy     # copies instead, if you'd rather not symlink
```

Claude Code usually picks new skills up immediately; if yours don't appear,
start a new session.

Verify they loaded by asking Claude to list its available skills, or check the
symlinks directly:

```bash
ls -l ~/.claude/skills/ | grep claude-skills
```

## Uninstall

```bash
./install.sh --uninstall
```

## License

MIT
