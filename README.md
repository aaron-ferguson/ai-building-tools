# AI Building Tools

Five skills that give a project a **stack-ranked local backlog any agent can work from**:
queue a piece of feedback once, and weeks later a cold session can pick it up, build it, and
verify it without asking a single clarifying question.

| Skill | Does | Phase |
|---|---|---|
| `/queue` | Turns something you just said into a fully specified item and inserts it at a considered rank | Define |
| `/design` | Answers a design question and records the decision — no artifact | Design |
| `/prototype` | Builds something to look at — a flow diagram, a clickable mockup, or a real component | Design |
| `/develop` | Takes the top `ready` item, builds it TDD, and stops at `next: verify` | Build |
| `/verify` | Checks a change against the item's written acceptance criteria, then closes it or sends it back | Check |
| `/retro` | Reviews the items closed and the session around them, and lands the lessons where they get read again | Learn |

`/design` and `/prototype` split the Design phase by output: **tell me** versus **show me**.
Default to `/design` — escalation is cheap, a prototype you didn't need is not. `/design` never
invokes `/prototype`; it names what a prototype would have to settle and leaves the call to you.

`/develop` hands off to `/retro` the way it hands off to `/verify`, and for the same reason:
building an item, checking it, and learning from it are three jobs, and the last two are the ones
that get cut short when one skill owns all three. `/retro` also runs on its own, over a whole
session rather than one item — and it is the only skill here that routinely edits *these skills*,
since "the workflow misled me" is a finding like any other.

The executor here is the **agent**, and the artifact is code. Its sibling
[`ai-context-tools`](https://github.com/aaron-ferguson/ai-context-tools) is the other half —
there the executor is you, and the artifact is a decision or a record. `/queue` is for work an
agent will build; `/capture` over there is for your own tasks, meetings, and notes.

They're designed to be run by **two sessions at once** — one window developing, another
queueing feedback and verifying — without either destroying the other's work.

---

## Relationship to `ai-building-conventions`

These tools **own workflow**: how work is queued, ranked, claimed, verified, and closed.

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
alone. You cannot usefully adopt these tools alone — with no standard to check against, `verify`
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

Then say *"queue this: <the thing>"* in any project. `/queue` scaffolds
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
- **`qa_level` is set at queue time, not develop time.** This is what stops QA rigor quietly
  sliding session to session — the moment the level is chosen by whoever is doing the work, it
  drifts down to whatever is convenient today.
- **`verify` closes the item, not `develop`.** The stage holding the verdict is the stage that
  acts on it, so there is no window in which a green can go stale. What keeps two sessions off one
  ticket is the `next` field, not a read-only rule: every stage refuses a ticket addressed to
  another one.
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

**Pushing is not the last step — updating the install is.** A `/ai-building-tools:*` invocation
runs the version in the plugin cache, pinned at the commit it was installed from. Until you update
it, your pushed change is live for everyone except you, and the session you are testing in is
running the old skill while you read the new one. That failure is quiet by construction: nothing
errors, the skill just behaves like the version you stopped looking at.

So the loop is four steps, not two:

```bash
git push origin main                        # 1. the installer resolves from the remote
# bump "version" in .claude-plugin/plugin.json
claude plugin update ai-building-tools       # 2. pull it into the cache
```

**And a fifth step you cannot skip: restart.** A running session resolves its skills once, at
start, from whatever was installed then — so `claude plugin update` changes nothing for the
session you are sitting in. This is measurable: a `/capture` invocation in the session that
wrote this was still executing the **0.6.1** copy while **0.8.2** was installed. Three
versions behind, no warning, in the session that had just done the release.

So the honest chain is: **push → bump → update → restart.** Skip the last one and you are
reading new docs while running old code, which is the same failure as the first three, one
layer further in.

Then **use the plugin copy** — same as everyone else, and the only way packaging mistakes surface
before someone else finds them.

To see whether the copy you are running matches the one you are editing:

```bash
diff -rq skills ~/.claude/plugins/cache/ai-building-tools/ai-building-tools/*/skills
```

Silence means they agree. Any output is work you have written and are not running.
