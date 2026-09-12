---
id: "0147"
title: Make claim name the declared paths that do not exist instead of reserving them
type: bug
next: develop
status: in-progress
qa_level: unit
size: s
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0106", "0075"]
expects:
  - skills/queue/templates/claim
  - .claude/backlog/claim
  - tests/claim.test.sh
claimed_by: "9d88"
claimed_at: 2026-09-12T04:18:53Z
touches:
  - skills/queue/templates/claim
  - .claude/backlog/claim
  - tests/claim.test.sh
---

## Problem

**A ticket's `expects:` can name a file that has never existed, and the lifecycle presents it as a
path.** `0075` expected `tests/skill-prose.test.sh`; there is no such file in the tree or anywhere in
the history. `./next develop`'s `EXPECTS` line is the first thing a claiming session reads about scope,
and `./claim` seeds `touches:` from it verbatim — so a fictional path is *reserved as held scope*,
against which the file-scope check then compares every other session's work, until somebody narrows it
by hand.

`./claim` already warns that `touches:` is provisional and must be narrowed. What it cannot currently
say is **which** of the paths are not real, which is the one fact that distinguishes "narrow this" from
"this ticket's scope is partly fiction" — and it is a fact the script is standing in the right place to
check.

A fictional `expects:` entry is also a signal about the ticket rather than about the tree: `0075`'s was
a test file a capture pass assumed would exist. Naming it at claim time is the cheapest moment to
discover that the ticket was specified against a file nobody wrote.

## Functional requirements

- **FR1** — `./claim` reports, for each path it seeds into `touches:`, whether it resolves in the
  working tree, and names the ones that do not.
- **FR2** — A non-existent path is a **warning, not a refusal**: a ticket may legitimately declare a
  file it is about to create, and that is the common case for a new guard.
- **FR3** — A directory and a glob both count as resolving if they match anything, so declaring
  `tests/` or `items/` is not reported.
- **FR4** — The report distinguishes *does not exist* from *exists and is held by another claim*, which
  the script already reports separately and must keep separate.

## Non-functional requirements

- **Compatibility** — a claim whose every declared path exists produces the output it produces today.
  How this would red: a case comparing the full output over an all-resolving fixture.

## Acceptance criteria

- [ ] AC1 — Given an item whose `expects:` names one path that does not exist and one that does, when
  `./claim` runs, then it names the missing one and not the existing one, and the claim succeeds.
  Red-making input: today's `claim`, which names neither.
- [ ] AC2 — Given an item whose `expects:` names only paths that exist, when `./claim` runs, then the
  output is byte-identical to today's. Red-making mutation: printing an unconditional line.
- [ ] AC3 — Given an item declaring a directory that exists and a glob that matches at least one file,
  when `./claim` runs, then neither is reported missing. Red-making mutation: testing with `-f`, which
  reports every directory as absent.
- [ ] AC4 — Given an item declaring a path that exists and is held by another claim, when `./claim`
  runs, then it is reported as held and not as missing. Red-making mutation: reporting both from one
  branch.
- [ ] AC5 — Given `0075`'s real item file, when `./claim 0075` runs against it, then
  `tests/skill-prose.test.sh` is named as not existing. Red-making input: today's script.
- [ ] AC6 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
  reports `0 failed`. Red-making change: editing the template and not `.claude/backlog/claim`.

## QA plan

- **Why this level:** `unit` — `claim` has a large existing suite that already scaffolds fixture
  backlogs with `expects:` lists.
- **Specific checks:**
  - Run `tests/claim.test.sh` and `tests/backlog-scripts-installed.test.sh` individually, then the
    whole suite with `|| true` per `config.yml`'s note.
  - Confirm AC2 by capturing today's output before the change and diffing, not by reading the new
    branch.

## Out of scope

- Correcting `0075`'s own `expects:`. The field is the ticket's and editing it is an `amend`.
- Refusing a claim over a fictional path. FR2 decides against it.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a `develop` park on `0075`. The park identified the exact place
  to report it — `claim`'s existing `touches: is set provisionally` warning — which FR1 follows.

- **2026-09-11 (develop, `9d88`) — AC5 is stale and was not built; it has no satisfiable form.** It
  asks that `./claim 0075` name `tests/skill-prose.test.sh` as not existing. Two independent
  reasons that cannot happen. `0075`'s `expects:` no longer carries that path — it reads
  `tests/remote-anchor.test.sh`, which exists — and the session that corrected it is the **same
  `develop` park (`0968`, 2026-09-09) that filed this ticket**, visible in `git log -p` on the item
  as the `-  - tests/skill-prose.test.sh` beside the note recording the defect. And `0075` is
  `status: done`, so `claim` refuses at the ready check long before the report. The criterion was
  written against a state its own author had already repaired.
  Its substance — *a real live ticket with a fictional path is named* — has a current instance:
  **`0132` declares `skills/orchestrate/SKILL.md`, which the `0129` rename deleted.** Claiming it
  to demonstrate this was not available to this session (see the selection note below). Left for
  the author: drop AC5, or re-point it at `0132`. AC1 already pins the behaviour on a fixture.

- **2026-09-11 — FR4's premise is half right, and the criterion was read for its substance.** It
  says *does not exist* and *held by another claim* are things "the script already reports
  separately". `claim` names a holder in exactly one place — the exclusive-claim refusal, a
  non-zero exit on a `"*"` ticket. For an **ordinary** claim it reports no holders at all; that is
  `./next`'s job. So FR4 was implemented as the separation it actually asks for: the new report is
  **existence-only**, and an existing path is never called fiction because something holds it.
  AC4's case pins that, and the mutation it names — answering both from one branch — reds it.

- **2026-09-11 — the count and the path list come out of one awk pass, on purpose.** The seeding
  awk already wrote `N_EXPECTS` to a temp file rather than letting a second parser recompute it,
  with a comment saying two parsers of the same frontmatter drift silently. The path list has the
  same property and was added to that same `END` block rather than to a new parser. Cleaning order
  inside it is bullet → trailing comment → quotes: comment before quotes, or a `#` inside a quoted
  path survives as part of the path. `0135`'s `expects:` carries inline comments, so this is a live
  shape rather than a hypothetical.

- **2026-09-11 — glob support is free, and is what the unquoted `$p` buys.** `for m in $p` expands
  a glob to its matches and leaves a non-glob (or a glob with no matches) literal — which is the
  right answer in all three cases. It is the one place in the new block where quoting would be the
  bug rather than the fix; the mutation sweep pins it.

- **2026-09-11 — mutation sweep over the new block, template copy (the one `tests/claim.test.sh`
  runs), control first.** Control (no-op comment) `0 failed`; `-e` → `-f` `1`; `for m in "$p"`
  `1`; report made unconditional `3`; existence test dropped `4`; warning turned into a refusal
  `6`. Restored clean, verified by `diff` against a copy taken before the sweep — the fix was
  committed first, because `git checkout -- <path>` restores to `HEAD` and would have deleted an
  uncommitted one.

- **2026-09-11 — adjacent defect found and NOT fixed here: a legitimate glob in `expects:` is read
  as an exclusive whole-tree claim.** The detector asks whether an asterisk appears anywhere in the
  entry, not whether the entry is `"*"`. Probed and confirmed. Parked in `FINDINGS.md`; it still
  needs a row, and this session did not write one.

- **2026-09-11 — selection: `0132` and `0134` were stepped over, both on file scope.** `0135`
  [`7a9b`] is held with no declared `touches:`, which reads as *its `expects:` files are held*. Both
  rows collide with it once their own stale paths are resolved — each declares
  `skills/orchestrate/SKILL.md` and `tests/orchestrate.test.sh`, deleted by the `0129` rename, whose
  live spellings `skills/sprint/SKILL.md` and `tests/sprint.test.sh` are both in `0135`'s set, and
  `0132` additionally shares `.claude/backlog/config.yml`. `./next develop` offered `0132` as TAKE
  because the collision is invisible at the declared spellings — the stale path is what hid it.
