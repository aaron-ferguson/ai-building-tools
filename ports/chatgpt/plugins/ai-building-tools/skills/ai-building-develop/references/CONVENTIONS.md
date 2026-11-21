# Resolving the conventions

Read by `queue`, `develop`, `verify`, and `retro` before they do anything that cites a standard.

These tools hold **no principles about code or product**. Every claim about what good software
looks like — TDD, secrets handling, input validation, PII in logs, accessibility, migration
safety — lives in the [`ai-building-conventions`](https://github.com/aaron-ferguson/ai-building-conventions)
repository and is **cited, never restated**. A restated rule is a rule that drifts, and the dangerous case is not the wrong restatement but the **incomplete** one: it reads as correct, so nothing prompts a reader to open the source. A skill restating a locking rule kept its *reason* and dropped the condition that reason depended on, and a session following the restatement literally had to choose between writing an unreviewable blob and skipping the work the step exists for (`0126`). This applies to a rule restated from anywhere, not only from the conventions — a reference file's rule quoted into a skill drifts the same way.

What these tools *do* own is workflow: how work is queued, ranked, claimed, verified, and
closed. That split is the whole design. The test for any line is not "is this a principle?" but:

> Would this still be true if the backlog didn't exist?

Yes → it's a convention, cite it. No → it's workflow, it belongs here.

---

## Resolution order

Find the conventions directory once, at the start of the skill, in this order. Select the first valid core and report inconsistent pointers as described below.

**1. `.tickets/config.yml` → `conventions.path`**

```yaml
conventions:
  path: ../ai-building-conventions      # relative to the repo root, or absolute
```

The explicit answer. Relative paths resolve from the project root, not the current working
directory. Prefer this when the project has a backlog.

**2. Project instruction files.** In the repository root, inspect the
`## Conventions` section of `AGENTS.md`, then `CLAUDE.md`. Each can declare
a line such as `@../ai-building-conventions/CONVENTIONS_CORE.md`.
Read that file explicitly. Resolve relative paths against the project root.

Use the first readable core in the order config, AGENTS.md, CLAUDE.md.
Check all declared pointers for disagreement even if the first resolves.
Report broken pointers and conflicting destinations, naming the source selected.
If none resolves, stop before writing anything and explain how to set
`conventions.path` or add the import to a project instruction file.

## What to load

Read the resolved core, applicable project instructions and company profile.
Project overrides take precedence over company and general defaults.
Read files triggered by the core index and the ticket's NFR citations.
Cite convention files by bare filename in tickets and reports.

## Routing a finding to the repo it is about

A *park what surprised you* step writes to the buffer of the repo the finding is **about**, not the
one the session stands in. The subject test above decides which:

- **a convention file** → the conventions repo's **root** `FINDINGS.md`, the buffer it declares for
  gaps found from outside, in the format stated there — never its `.tickets/` buffer, which
  holds gaps found from inside.
- **a skill, a reference file, or a backlog script** → the tools repo's `.tickets/FINDINGS.md`.
  **Not its root**: the root buffer above is the conventions repo's alone. Two sessions on one
  day found no `FINDINGS.md` at the tools root and parked locally as though nothing resolved.
- **anything else, this project's own code included** → stays in the local buffer.

**Both destinations are resolved, never guessed.** The conventions repo is the directory the ladder
above already resolved. The tools repo is `tools.path` in `.tickets/config.yml`, resolved
from the project root exactly as `conventions.path` is. **Nothing resolving is a stop**, on rung 3's
ground: never infer the directory.

**Never derive either from the plugin install.** The marketplace clone beside it reads as a working checkout
— right `origin`, identical `HEAD`, whole backlog — and the plugin system refreshes it over anything
parked there (measured 2026-09-09).

**A destination that does not resolve, or is not a writable checkout, falls back to a marked local park:**
write the entry locally prefixed `[for <repo>]` so a later `retro` forwards it rather than
re-deriving where it belonged.

**One commit per repo, by pathspec, in the same turn as the write** — never one spanning two repos
(`git-conventions.md`) — and a park into another backlog takes that backlog's lock
(`CONCURRENCY.md`, *Lock every write to the backlog directory*).

**A finding crossing into a public tool repo carries no company material** — no client name, no
private path, no internal identifier. The receiving repo's classification binds the entry, not the
sending project's, and one that cannot meet it stays local (`data-privacy-conventions.md`).
