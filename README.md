# AI Building Tools

Three skills that give a project a **stack-ranked local backlog any agent can work from**:
capture a piece of feedback once, and weeks later a cold session can pick it up, build it, and
verify it without asking a single clarifying question.

| Skill | Does |
|---|---|
| `/capture` | Turns something you just said into a fully specified item and inserts it at a considered rank |
| `/develop` | Takes the top `ready` item, builds it TDD, hands it to QA, closes it out |
| `/qa` | Verifies a change against the item's written acceptance criteria and returns PASS or FAIL |

They're designed to be run by **two sessions at once** — one window developing, another
capturing feedback and QA'ing — without either destroying the other's work.

---

## Relationship to `ai-building-conventions`

These tools **own workflow**: how work is captured, ranked, claimed, verified, and closed.

They **own no principles about code or product**. Every claim about what good software looks
like — TDD, secrets handling, input validation, PII in logs, accessibility, migration safety —
lives in [`ai-building-conventions`](https://github.com/aaron-ferguson/ai-building-conventions)
and is cited, never restated. A restated rule is a rule that drifts.

The test for any line in this repo is not "is this a principle?" but:

> Would this still be true if the backlog didn't exist?

Yes → it belongs in the conventions and gets cited. No → it's workflow and lives here. That's
why the five-tier ranking model *is* in this repo (it's meaningless without a queue) while the
TDD cycle is *not* (it's true regardless).

**The dependency runs one way.** These tools require the conventions; the conventions know
nothing about these tools and need no changes to work with them. You can adopt the conventions
alone. You cannot usefully adopt these tools alone — with no standard to check against, `qa`
would issue verdicts that look identical whether or not anything was actually verified, and
that silent equivalence is worse than being blocked. So the skills stop and tell you how to
wire it up instead.

---

## Install

```
/plugin marketplace add aaron-ferguson/ai-building-tools
/plugin install ai-building-tools
```

Then wire each project to your conventions — either is enough:

**Option A — the project's `CLAUDE.md`** (this is the wiring the conventions repo already
prescribes, so most projects already have it):

```markdown
## Conventions
@../ai-building-conventions/CONVENTIONS_CORE.md
```

**Option B — `.claude/backlog/config.yml`**, once the backlog exists:

```yaml
conventions:
  path: ../ai-building-conventions
```

Then say *"capture this: <the thing>"* in any project. `/capture` scaffolds
`.claude/backlog/` on first use, reading your real test commands out of `package.json` (or
`Makefile`, `pyproject.toml`) rather than guessing.

---

## What lands in your project

```
.claude/backlog/
  config.yml     project settings, next_id, conventions path, test commands
  QUEUE.md       the stack rank — line order IS the rank
  DONE.md        completed items, newest first
  .lock/         transient, held for seconds during a claim. Never commit it.
  items/
    0007-rate-limit-feedback-endpoint.md
```

Plain markdown, committed with the project. **`QUEUE.md` is readable and editable on its own** —
if the skills are unavailable, or you just want to reorder something by hand, nothing is locked
behind tooling. That's deliberate: the queue file is the product, and the skills are a wrapper
over it.

Add `.claude/backlog/.lock/` to `.gitignore`.

---

## Design notes

A few decisions that look odd until you know why:

- **No priority column, and no position number.** Line order is the rank. A priority field and
  a line position can disagree, and then nothing is unambiguous. A `#` column would need
  renumbering on every insert and close — turning each one-row change into a full-file rewrite,
  which is exactly how two concurrent sessions silently clobber each other.
- **Rank by pairwise comparison, never a score.** Five tiers, then ordered tie-breakers. False
  precision produces ties, and ties are the thing the queue exists to eliminate.
- **`qa_level` is set at capture time, not develop time.** This is what stops QA rigor quietly
  sliding session to session — the moment the level is chosen by whoever is doing the work, it
  drifts down to whatever is convenient today.
- **`qa` writes nothing.** Its output is a verdict; `develop` alone closes items. That read-only
  guarantee is what makes it safe to QA in one window while another develops.
- **Only two operations take a lock** — claiming an ID and claiming an item. Everything else is
  a single-line edit, which two sessions can do concurrently without coordination.

Full protocol in [`references/CONCURRENCY.md`](references/CONCURRENCY.md); the conventions
lookup in [`references/CONVENTIONS.md`](references/CONVENTIONS.md).

---

## Licence

MIT.

## Editing this plugin

**Do not edit the installed copy under `~/.claude/plugins/cache/`.** A plugin is installed from
this repository at a pinned commit, so anything changed in the cache is silently reverted by the
next update — no error, no conflict. Edit here, commit, and **push**: the installer resolves the
plugin from the remote, so a local commit alone still loses the change.

The `SOURCE` file at the repo root ships with the plugin for exactly this reason. It lands in the
install cache and marks that copy as disposable, which is what lets tooling warn before the work
is lost rather than after.
