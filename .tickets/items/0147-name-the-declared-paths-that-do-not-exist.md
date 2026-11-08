---
id: "0147"
title: Make claim name the declared paths that do not exist instead of reserving them
type: bug
next:
status: done
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
claimed_by:
claimed_at:
touches:
closed: 2026-09-12
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

- [x] AC1 — Given an item whose `expects:` names one path that does not exist and one that does, when
  `./claim` runs, then it names the missing one and not the existing one, and the claim succeeds.
  Red-making input: today's `claim`, which names neither.
- [x] AC2 — Given an item whose `expects:` names only paths that exist, when `./claim` runs, then the
  output is byte-identical to today's. Red-making mutation: printing an unconditional line.
- [x] AC3 — Given an item declaring a directory that exists and a glob that matches at least one file,
  when `./claim` runs, then neither is reported missing. Red-making mutation: testing with `-f`, which
  reports every directory as absent.
- [x] AC4 — Given an item declaring a path that exists and is held by another claim, when `./claim`
  runs, then it is reported as held and not as missing. Red-making mutation: reporting both from one
  branch.
- [x] AC6 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
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

- **2026-09-12 (verify, `0d96`) — sent to `queue` on a stale contract, not on a red. Five of six ACs
  and the Compatibility NFR pass, each pinned by a mutation this session ran itself; the whole
  suite is green across all 30 files. AC5 is the only thing standing in the way, and it is
  unsatisfiable as written for the two reasons `develop` gave, both re-probed here: `0075` no
  longer declares `tests/skill-prose.test.sh`, and being `done` it has no `QUEUE.md` row, so
  `./claim 0075` exits 1 at `no row for 0075 in QUEUE.md`.
  **The constraint on any replacement: an acceptance criterion must not rest on another ticket's
  mutable frontmatter.** That is what failed here — the bytes AC5 depends on were edited by the
  same pass that wrote it, and no guard can see a fixture that lives in someone else's item file.
  Re-pointing at `0132` has the same defect and is worse today: `0132` is `in-progress` under
  `0a54`, and its `skills/orchestrate/SKILL.md` is exactly the kind of entry a claiming session is
  about to correct. If a real-tree instance is wanted, pin the bytes into a fixture the suite owns;
  if it is not, drop AC5 — no FR requires one, and AC1 already pins FR1's behaviour. Parked the
  generalisable half in `FINDINGS.md`.

- **2026-09-12 (queue) — Re-specified: the code at `5d51b9d` is right and stays; AC5 is dropped
  and nothing else changes.** Verify `0d96` passed AC1–AC4, AC6 and the Compatibility NFR, each with
  a mutation it ran, and found AC5 unsatisfiable. It was dropped rather than re-pointed, on verify's
  constraint: a criterion must not depend on another ticket's frontmatter, which that ticket can
  change. Re-pointing at `0132` repeats the defect. Pinning a real item's bytes into a fixture adds
  nothing AC1 does not already prove on its own fixture. No FR asked for a real-tree instance.
  **AC6 keeps its number**, as an id rather than a position, so the QA evidence above and every note
  citing it still resolve. No guard cites AC5 (`grep 0147 tests/` names AC1–AC4 only). No criteria
  gain code, so the stage is `verify`, not `develop`. The next verify pass re-runs the suite, since
  `tests/claim.test.sh` has uncommitted edits from `0083` [`7bf5`] as of this re-spec.

## QA evidence

**2026-09-12, verify `0d96`, `qa_level: unit`.** Suite run per `config.yml`'s per-file form
(`for t in tests/*.test.sh; do "$t" || true; done`); no `lint:` or `typecheck:` command is
configured. Tree clean at Step 2 and at verdict, so the intersection with the evidence set is empty
and this is not advisory. Both copies of `claim` are byte-identical (`diff` clean), so the guard
harness — which copies `skills/queue/templates/claim` into its fixtures — exercises the installed
script's bytes.

| Criterion | How it was checked | Result |
|---|---|---|
| AC1 — missing path named, existing one not, claim succeeds | `tests/claim.test.sh` case *0147 AC1*: five assertions, incl. that the fictional path is still seeded (FR2 is a warning, not a refusal). Mutation M4 (`-e` test forced true) → `89 passed, 3 failed`; mutation M5 (existence test removed, nothing ever resolves) → `88 passed, 4 failed`, reddening *and not the one that does* | PASS |
| AC2 — all-resolving item's output byte-identical to today's | `tests/claim.test.sh` case *0147 AC2* uses `assert_eq` over the whole report, not `assert_contains`. Named mutation run: report made unconditional (`if true; then`) → `89 passed, 3 failed` | PASS |
| AC3 — an existing directory and a matching glob are neither reported | `tests/claim.test.sh` cases *0147 AC3* (both halves: resolving dir+glob silent, absent dir still named). Named mutation `-e` → `-f` → `91 passed, 1 failed`; glob mutation `for m in $p` → `for m in "$p"` → `91 passed, 1 failed` | PASS |
| AC4 — an existing path held by another claim is reported held, not missing | `tests/claim.test.sh` case *0147 AC4* (`add_held 0034 yy88` + an existing declared path). Mutation M5 reddens its assertion *an existing path is not fiction just because it is held* | PASS |
| AC5 — `./claim 0075` names `tests/skill-prose.test.sh` as not existing | **Unsatisfiable as written, two independent reasons, both probed.** `0075`'s `expects:` reads `skills/retro/SKILL.md`, `skills/develop/SKILL.md`, `tests/remote-anchor.test.sh` — the fictional path was removed by the same develop park that filed this ticket (`git log -p` on the item, `-  - tests/skill-prose.test.sh`). And `0075` is `status: done` with no `QUEUE.md` row: `./claim 0075` exits 1 at `no row for 0075 in QUEUE.md`, before any report. Neither pass nor fail is honest | **STALE** |
| AC6 — whole suite, every file `0 failed` | 30 files, each run individually. Tallies pasted from each file's own line; largest `tests/next.test.sh` `413 passed, 0 failed`, `tests/close.test.sh` `240 passed, 0 failed`, `tests/claim.test.sh` `92 passed, 0 failed`, `tests/sprint.test.sh` `179 passed, 0 failed, 0 skipped`. `grep -cE '[1-9][0-9]* failed'` over the captured output → `0` | PASS |
| NFR Compatibility — an all-resolving claim produces today's output | The equality assertion under AC2 is the case the NFR asks for; the unconditional-line mutation is the red it names | PASS |

**Always-on convention pass (`CONVENTIONS_CORE.md`).** Shell change, no new log field, analytics
event or egress destination, so no `data-privacy-conventions.md` trigger; no auth, credential or
data-visibility surface, so no missing Security row; no UI. Step 4's *what did this make newly
reachable* pass: the change adds one advisory stanza after the four existing scope outcomes and no
new branch, exit code or write — nothing previously unreachable is now offered.

**Mutation sweep, control-last.** Control before the sweep: `92 passed, 0 failed`. Five mutations,
each applied to `skills/queue/templates/claim` (the copy the harness runs) over a committed tree,
restored by that path alone, `git diff --stat` confirming each landed: `-e`→`-f` 1 failed; quoted
`$p` 1; report unconditional 3; existence test forced true 3; existence test removed 4. Restored
copy `diff`-identical to the pre-sweep copy; control after: `92 passed, 0 failed`; tree clean.

**2026-09-12, verify `b4d6`, `qa_level: unit` — re-verification after the AC5 re-spec.** No tick
above was trusted; every criterion re-checked and every mutation cited below re-run by this session.
`git status --porcelain` empty at Step 2 and empty after the last evidence command, so the dirty set
is empty, the intersection with the evidence set (`skills/queue/templates/claim`,
`.claude/backlog/claim`, `tests/claim.test.sh`, `tests/backlog-scripts-installed.test.sh`, `tests/`)
is empty, and this is not advisory. `diff skills/queue/templates/claim .claude/backlog/claim` clean.
The copy executing this session's skill is the 0.9.26 install; the change under test is a script
run from the repo copies, which is what the suite exercises. No `lint:` or `typecheck:` configured.

| Criterion | How it was checked | Result |
|---|---|---|
| AC1 — missing path named, existing one not, claim succeeds | `tests/claim.test.sh` case *0147 AC1*. M4 (report never printed — today's behaviour) → `95 passed, 3 failed` incl. *names the one that does not*; M6 (existence test → `false`) → `94 passed, 4 failed` incl. *and not the one that does*; M7 (warning turned into `exit 1`) → `89 passed, 9 failed` incl. *exits 0 — a path that does not exist is a warning, not a refusal* | PASS |
| AC2 — all-resolving output byte-identical | case *0147 AC2*, `assert_eq` over the whole report. Named mutation M3 (report unconditional) → `95 passed, 3 failed` incl. *the report is byte-for-byte what it was before this ticket* | PASS |
| AC3 — existing directory and matching glob not reported | cases *0147 AC3* (both). Named mutation M1 `-e`→`-f` → `97 passed, 1 failed` (*nothing is reported as fiction at all*); M2 `for m in "$p"` → `97 passed, 1 failed`, same case; M4 reddens *the absent directory is named* | PASS |
| AC4 — existing path held by another claim reported held, not missing | case *0147 AC4*; `add_held` holds the same `some/other/file.md` the item declares. Named mutation M5 (a path any other item names is answered as missing, one branch) → `97 passed, 1 failed`, exactly *an existing path is not fiction just because it is held* | PASS |
| AC6 — whole suite, every file `0 failed` | 31 files run individually (`|| true` form); tallies pasted, e.g. `tests/claim.test.sh: 98 passed, 0 failed`, `tests/next.test.sh: 428 passed, 0 failed`, `tests/close.test.sh: 246 passed, 0 failed`, `tests/backlog-scripts-installed.test.sh: 37 passed, 0 failed`, `tests/sprint.test.sh: 187 passed, 0 failed, 0 skipped`; `grep -cE '[1-9][0-9]* failed'` → `0`. Named change M8 (template edited, installed copy not) → `36 passed, 1 failed`: `claim has diverged from skills/queue/templates/claim` | PASS |
| NFR Compatibility | AC2's equality case; M3 reddens it | PASS |

**Sweep hygiene.** Tree committed (`86a2715`) before mutating; each mutation applied to
`skills/queue/templates/claim` (the copy the harness copies into fixtures), confirmed landed by a
non-empty `git diff --numstat`, restored by that path alone. Control before `98 passed, 0 failed`;
restored copy `cmp`-identical to the pre-sweep copy; control after `98 passed, 0 failed` and
`37 passed, 0 failed`; `git status --porcelain` empty.

**Always-on pass.** Unchanged from `0d96`'s and re-read against the diff at `5d51b9d`: shell only,
no log field, event or egress, no auth or visibility surface, no UI; the new stanza adds no branch,
exit code or write, so nothing is newly reachable.
