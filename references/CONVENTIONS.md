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

Find the conventions directory once, at the start of the skill, in this order. Stop at the first
one that resolves to a directory containing `CONVENTIONS_CORE.md`.

**1. `.claude/backlog/config.yml` → `conventions.path`**

```yaml
conventions:
  path: ../ai-building-conventions      # relative to the repo root, or absolute
```

The explicit answer. Relative paths resolve from the project root, not the current working
directory. Prefer this when the project has a backlog.

**2. The project's `CLAUDE.md` → the `## Conventions` import**

```markdown
## Conventions
@../ai-building-conventions/CONVENTIONS_CORE.md
```

This is the wiring the conventions repo already prescribes, so most projects need no config at
all. Take the directory containing the imported `CONVENTIONS_CORE.md`.

**3. Nothing resolved → stop.**

Do not guess a path, do not search the filesystem for a directory that looks right, and do not
proceed on your own judgement of what the conventions probably say. Report this and stop:

> This project isn't wired to a conventions repository, and these tools deliberately carry no
> standards of their own — they'd have nothing to check your work against.
>
> Fix it either way:
> - add `conventions.path` to `.claude/backlog/config.yml`, or
> - add a `## Conventions` import to the project's `CLAUDE.md` (see the conventions repo README)
>
> If you don't have the repo yet: https://github.com/aaron-ferguson/ai-building-conventions

Stopping is correct here. A backlog item queued with no NFR standard, or verified against no
standard, looks exactly like one that was done properly — and that silent equivalence is worse
than the inconvenience of being blocked.

**A ladder fails open at every rung but the last, and that is the failure mode to watch.** Step 3
is loud. Steps 1 and 2 are not: a `conventions.path` pointing at a directory that holds nothing
falls through to the `CLAUDE.md` import, which resolves, so the session gets correct conventions
and nobody learns the config is wrong. One project ran that way for weeks — `../ai-building-conventions`
from a nested repo resolved to a directory that did not exist, masked by a correct `../../` import
one rung below. **A broken explicit setting hidden by a working fallback is strictly worse than one
that fails loudly**, because nothing surfaces it: it can only be found by reading the file, and the
day the fallback is edited away it becomes a stop with no obvious cause. So where step 1 is present
and does not resolve, say so and keep going — a fallback that silently rescues a broken
configuration has repaired the session and not the project.

---

## What to load once it resolves

- **Always:** `<conventions>/CONVENTIONS_CORE.md`. It carries the always-on rules and an index
  of every other file with its trigger.
- **Always:** the project's own `CLAUDE.md`. Project overrides beat universal defaults;
  precedence is project `CLAUDE.md` > company profile > general default.
- **On demand:** exactly the files cited in the item's NFR table, plus whatever the core's index
  says the task triggers. Don't read all of them; don't read none.

Cite convention files by bare filename (`security-conventions.md`) in items and reports. The
directory is resolved per project and per machine, so an absolute path written into a backlog
item is wrong the moment anyone else reads it.

---

## Routing a finding to the repo it is about

A *park what surprised you* step writes to the buffer of the repo the finding is **about**, not the
one the session stands in. The subject test above decides which:

- **a convention file** → the conventions repo's **root** `FINDINGS.md`, the buffer it declares for
  gaps found from outside, in the format stated there — never its `.claude/backlog/` buffer, which
  holds gaps found from inside.
- **a skill, a reference file, or a backlog script** → the tools repo's `.claude/backlog/FINDINGS.md`.
- **anything else, this project's own code included** → stays in the local buffer.

**Both destinations are resolved, never guessed.** The conventions repo is the directory the ladder
above already resolved. The tools repo is `tools.path` in `.claude/backlog/config.yml`, resolved
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
