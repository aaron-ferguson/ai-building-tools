---
name: verify
description: >
  Verify a change against a backlog item's acceptance criteria and non-functional requirements
  at the QA level the item declares — unit, integration, or end-to-end. Use when the user says
  "QA this", "verify it", "check it works", "run the e2e tests on this", "does this meet the
  criteria", or invokes /verify. Invoked automatically by the develop skill before an item can be
  closed. Reads .claude/backlog/items/ for the acceptance criteria and QA plan.
---

# /verify

Verify that a change actually satisfies what was promised. Distinct from `/code-review`, which
hunts for defects in a diff — this one checks a change against a **written contract** and
returns pass or fail.

**`verify` writes nothing to the backlog.** It reads `QUEUE.md`, the item file and `config.yml`,
and modifies none of them — not the status, not the ACs, not the notes. Its output is a verdict
to its caller, and `develop` owns acting on it. That read-only guarantee is what makes it safe
to run in a second window against an item another session is actively developing. If you notice
something worth recording, hand it to `queue`; do not edit the item yourself. A finding you cannot
yet place — a fragile check, a cost pattern — may be parked in `.claude/backlog/FINDINGS.md`, which
is a buffer rather than the queue and so does not breach the rule above.
(See `references/CONCURRENCY.md` at the plugin root — `../../references/CONCURRENCY.md` from
this file.)

**This skill states no standards of its own.** What counts as secure, private, accessible, or
adequately tested is defined by the project's conventions and cited here, never restated.
Resolve them per `references/CONVENTIONS.md`.

---

## Step 1 — Get the contract

With an item ID: read `.claude/backlog/items/<id>-*.md` and take the **Acceptance criteria**,
**Non-functional requirements**, and **QA plan** sections.

Without one: infer the item from the branch, recent commits, or the conversation. If there's
no backlog item at all, verify against whatever the user stated as the goal — and say explicitly
that you're verifying an unwritten contract, which is weaker.

Read `.claude/backlog/config.yml` for the project's real commands, and resolve the conventions
per `references/CONVENTIONS.md`. If none resolve, stop — a verdict issued against no standard
is indistinguishable from one issued against a real one, and that is the failure mode this
whole design exists to prevent.

---

## Step 2 — Check whose tree you are testing, then run the declared level

**Before running anything**, see what else is in flight:

```bash
git status --porcelain
```

A second window developing another item means the suite you are about to run covers a file set
that never existed as a coherent state. Its red may belong to work half-written, and its green
may be luck.

- Changes confined to the item under test → proceed normally.
- Changes outside it → **still run**, but say so in the verdict and label the result
  **advisory**: name the unrelated paths, and state that a confident PASS needs a clean tree.
  Do not stash, revert, or check out anything to tidy it — that is another session's work and
  destroying it is far worse than an imprecise verdict.
- The item under test is `in-progress` under a claim token you did not mint, and you were
  invoked directly rather than by `develop` → say plainly that you are verifying an item another
  session is mid-way through, so a red may simply mean unfinished.

The item's `qa_level` was set at queue time. Run **that** level and everything below it —
levels are cumulative, sitting on the pyramid defined in `testing-conventions.md`.

| Level | Run |
|---|---|
| `verify` | the scripted assertion named in the item's QA plan, plus lint/typecheck if the project has them. The assertion must be executed and its output shown — a `verify` item read-and-eyeballed is not verified |
| `unit` | lint, typecheck, unit suite scoped to the change |
| `integration` | the above, plus the integration suite across the seams this change touches |
| `e2e` | the above, plus the specific journeys named in the item's QA plan |

**If the declared level has no command in `config.yml`, stop and say so.** Do not substitute a
lower level and call it verified — that is exactly the silent downgrade the per-item declaration
exists to prevent.

**A configured level with no tests yet is an empty set, not a red.** Because levels are
cumulative, an `integration` item on a young project runs a unit command over a directory that
holds nothing — and most runners exit non-zero on "no test files found", which reads as a
failing level when nothing failed. Check whether the run collected zero tests before calling it,
and report it as `no tests at this level` rather than a FAIL. The genuine red to keep is the
opposite case: a level that *had* tests and now collects none, which means they moved or stopped
matching the pattern.

Scope to the change; full-suite runs are for when the user asks. Keep output lean, and raise
verbosity only while investigating a failure.

**For e2e:** drive the real entry point against a local or staging target with synthetic data —
never production, never production credentials. Stop every server, container, or browser you
started, in this same turn. If Playwright is the project's runner, use it.

---

## Step 3 — Check the acceptance criteria literally

Walk each AC one at a time and record how you verified it — which test, which observed
behaviour, which screenshot. "Looks right" is not a verification. An AC you cannot verify is a
**fail**, not a pass with a caveat.

**A green check is only evidence if it could have been red, and confirming that is your job
rather than the implementer's.** They have already convinced themselves; the whole reason this
pass is separate is to distrust that. So for each AC whose verdict rests on an automated check,
break the behaviour the check exists to catch and confirm the check goes red — then restore it.
The failure mode is not a check wired to nothing, which is obvious; it is a check that runs,
asserts, and measures something *adjacent* to the defect: a UI drag that ends off the element
under test so the click never lands there, a value chosen where the distortion is symmetrical, a
synthetic gesture whose step size clears the very threshold it is testing. Each of those passes
against deliberately broken code.

Budget this for the checks you would cite when closing the item, not for the whole suite. **If a
check cannot be made to fail, the AC is unverified** — that is a `FAIL` under the rule above, not
a pass with a note.

**And a check can only see what its runner can represent.** Before accepting one, ask what the
runner actually simulates: a headless browser has no collapsing chrome, no real compositor and no
finger; a fake clock has no drift. If the defect lives in what the runner *substitutes*, no
result from it counts in either direction — say so, and fall back to the level that can observe
it, even when that level is a human on a device. **A higher test level is not automatically a
stronger one**; it is stronger only if its runner can observe the defect, and promoting an item
to a level that structurally cannot see the bug buys a green light that means nothing.

---

## Step 4 — Check the NFRs that the item declared

**First, ask what the change made newly *reachable*.** The ACs enumerate what the change must
do; nothing in them can cover a path the change **creates**, because there was nothing to write
an AC about when the item was queued. Any change to routing, visibility, permissions, or the
conditions under which a screen or endpoint is offered adds states that were previously
unreachable — and a destructive or privileged action sitting on one of those is now available
by a route nobody reviewed. Walk the newly reachable states and check each against the rules the
project already holds elsewhere. A change that made a menu reachable while a saved document
existed put an unconfirmed discard one tap away, and every written AC passed: the defect was
created by the change rather than verified against it, so only this question finds it.

For each filled row in the item's NFR table, confirm the stated requirement holds. **Load the
cited convention file** — the row states what this item must satisfy, the convention states
what the rule is, and you are checking against the rule. Do not check against the row alone
unless it is self-evidently complete.

Then run the always-on pass regardless of what the table says. **Read `CONVENTIONS_CORE.md` for
the current always-on rules and check the diff against them** — they are non-negotiable, they
apply to every change, and an item does not get a row for them precisely because they are never
optional. This skill deliberately does not list them: a copy here would drift from the source
and you would end up checking the stale version.

The privacy pass in `data-privacy-conventions.md` runs on any change that adds or moves a log
field, an analytics event, or an egress destination, whether or not the item has a Privacy row.

If the change touches auth, credentials, or data visibility and the item has no Security row,
that's a gap in the item — flag it and run the `security-conventions.md` pass anyway. Same for
a UI change with no Accessibility row and `accessibility-conventions.md`. A missing row is an
oversight at queue time, not permission to skip the check.

---

## Step 5 — Park what surprised you

Before reporting, write anything that surprised you into `.claude/backlog/FINDINGS.md` as one
dated line. This is the discovery-time recording `documentation-conventions.md` already requires,
at the one moment the context is still hot.

Triggers, at minimum: **a template or skill step that had no correct answer for your case**; **a
configured command that behaved unexpectedly**; **a scaffolding step you had to invent**.

**An explicit "nothing surprised me" is a complete result.** The habit must not manufacture
findings to justify itself — an invented entry is read, and paid for, by every later session.

**Commit `FINDINGS.md` in the same turn you write it, by pathspec** —
`git commit -m "Park what <skill> hit" -- .claude/backlog/FINDINGS.md`. A finding left uncommitted
until close is one `git stash` from gone, and it is the other window's commit that carries it off.

Anything whose home is already obvious — a mechanism, a rule, a unit of work — goes to that home
instead of here.

---

## Step 6 — Verdict

State **PASS** or **FAIL** plainly, then the evidence table: each AC and NFR row, how it was
checked, and the result. Include the actual failure output for anything red.

If Step 2 found unrelated changes in the tree, mark the verdict **PASS (advisory)** or
**FAIL (advisory)** and name what made it so. An advisory PASS is not a green `develop` may
close on — it is a request to re-run against a clean tree.

A partial pass is a FAIL with a list. Never soften a red result, never report a check you
skipped as though it ran, and never close an item on your own authority — `develop` owns
closing, and it needs a real green from you to do it.

If QA passes but you noticed unrelated problems along the way, don't fix them here — hand them
to `queue` as new items.
