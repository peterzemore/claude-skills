# claude-skills — working notes

- `install.sh` **symlinks** `skills/*` into `~/.claude/skills/`. Editing a skill under
  `~/.claude/skills/<name>/` edits this repo. Commit from here.
- Content is deliberately de-identified: no hostnames, store names, domains, IDs,
  addresses, or people's names in any skill. The incidents are described by shape.
  Keep it that way — the repo is public.
- Each skill keeps the same three parts: the rule, the mechanics, and *why this skill
  exists* (the incident, including what the wrong fix was and how long the false
  confidence lasted). The third part is what makes a skill fire; don't trim it to
  "best practice" prose.
- Skills load on their trigger phrases in the `description`. When adding a trigger,
  use the words a person actually says in the moment ("it's still showing"), not the
  name of the concept.
- No hooks, no scripts that run on their own, no mandated workflow. If a proposed
  addition needs one of those, it belongs somewhere else.
