---
name: scoped-deploy
description: >-
  Scope a deploy to only the files the current task touched, so unrelated
  uncommitted work in the repo doesn't ride along to production. Use BEFORE any
  command that syncs a directory to a live or shared target: theme push, rsync,
  scp, `vercel --prod`, a deploy script, a container rebuild, a CI trigger, or a
  service restart that picks up whatever is on disk. Triggers: "deploy", "push
  to production", "ship it", "publish", "sync to the server", "go live".
---

# Scoped deploy

A deploy command that syncs a whole directory ships **everything in the working
tree**, not just what you changed. If someone left unfinished work in the repo,
a broad push puts it in production as a side effect nobody chose.

## Do this before every deploy

1. **`git status` first.** Always. Before the deploy command, not after it fails.
2. **Classify what you see.** For each modified/untracked file, ask: *did this
   task write this file?*
   - Everything is yours → a normal push is fine.
   - Anything is not yours → **stop, do not push broadly.**
3. **Scope it.** Use the tool's partial-push mechanism rather than a full sync:
   - `--only=<file>` / `--include=` flags, repeated per file
   - an explicit file allowlist in a deploy script
   - targeted `rsync`/`cp` of the specific paths instead of a directory sync
   - a commit-scoped deploy (`git archive`, deploy-from-ref) rather than
     deploy-from-working-tree
4. **Or ask.** If there's no scoping mechanism, tell the user exactly which
   unrelated files would ship and get an explicit go-ahead. Don't assume their
   in-progress work is ready just because yours is.
5. **Verify as an outsider.** Confirm the deploy from a clean, logged-out client
   (`curl` an anonymous request), not from your own authenticated session — edge
   and page caches routinely serve stale HTML to real visitors after a push that
   looked successful in an admin preview.

## Why this skill exists

A task deployed a small page plus a few unrelated fixes to a live storefront
theme. Sitting uncommitted in the same repo were the owner's unfinished changes
to a membership section and its template. A plain full-directory push would have
shipped that unreviewed work to production alongside the intended change. Running
`git status` first caught it; a repeated `--only=` push, scoped to exactly the
files the session had written, shipped the intended change and left the rest
untouched.

The failure mode is silent. A broad push succeeds, reports success, and the
unintended changes are live until a customer finds them.

## Anti-patterns

- Running the deploy first and reading `git status` only when something breaks.
- Committing someone else's in-progress work "to get a clean tree" so the push
  is safe. That's not scoping, that's authoring a commit you can't defend.
- `git stash`-ing unrelated changes to clean the tree, deploying, then popping.
  It works until the pop conflicts or you forget, and you've now put someone
  else's work at risk to save yourself a flag.
- Treating a green deploy log as proof. It proves the sync ran, not that only
  the right files moved.
