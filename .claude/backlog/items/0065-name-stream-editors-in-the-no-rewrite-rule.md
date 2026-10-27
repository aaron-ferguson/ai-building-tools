---
id: "0065"
title: Name stream editors in the rule against rewriting QUEUE.md
type: bug
next: develop
status: in-progress
qa_level: verify
size: s
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0027", "0030"]
expects:
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - tests/citations.test.sh
claimed_by: "7c03"
claimed_at: 2026-10-27T20:10:53Z
touches:
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - tests/citations.test.sh
---

## Problem

`references/CONCURRENCY.md`, *Never rewrite `QUEUE.md` by hand*, reads: "`Edit` the one row you are
changing. Never `Write`, never read-rebuild-write". Confirmed still current. As written the rule is
about two things — the `Write` tool, and reading the file into memory and writing it back — and a
reader takes it as covering those.

**An in-place regex over the whole file is neither, and it is the one that caused real damage.**
Closing 0030 without the scripts, a stray `perl -i -ne` invocation left in the script with an unset
variable expanded its match to `"\n"` and deleted **every blank line in the file**. The row removal
itself was correct, so the commit's diffstat — 14 deletions for a one-row close — was the only
signal. Repaired in the next commit. `Edit`'s uniqueness check cannot produce that class of damage;
`sed -i`, `perl -i` and an `awk`-to-temp-file-and-`mv` all can.

The gap is live in this session's own work: three `QUEUE.md` inserts this week were made with
`awk` writing to a temp file under the lock, which the rule as written does not address either way.
Each was guarded by refusing the write unless the diff was exactly the expected added lines and zero
removed — a mitigation invented per use, because the rule names no technique and offers no safe
form.

## Functional requirements

- FR1 — *Never rewrite `QUEUE.md` by hand* names in-place stream editors — `sed -i`, `perl -i` — and
  whole-file rewrites through a temp file as the same prohibited class as `Write` and
  read-rebuild-write, so the rule covers the technique that actually caused the damage.
- FR2 — The rule states what makes `./claim` and `./close` the exception in terms that apply to any
  future exception: they hold the lock across the whole rebuild, and they are one process.
- FR3 — Where a whole-file rewrite is genuinely the only available form — a multi-row insert under
  the lock — the rule or `CONCURRENCY-INCIDENTS.md` names the safe shape: verify the diff is exactly
  the intended change before the write is kept, and abandon it otherwise.
- FR4 — The 0030 incident and the diffstat that was its only signal are recorded in
  `CONCURRENCY-INCIDENTS.md` rather than in the rule, per the split 0020 made.
- FR5 — The rule name is unchanged, or every citation of it is updated in the same change and
  resolves under `tests/citations.test.sh`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule keeps the failure it prevents in one clause and the narrative moves to `CONCURRENCY-INCIDENTS.md`, which is the compression rule that file's own size justification is built on | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `references/CONCURRENCY.md` *Never rewrite `QUEUE.md` by hand*, when read, then
  it names in-place stream editing as prohibited.
- [ ] AC2 — Given the same rule, when read, then it names a whole-file rewrite through a temp file
  as the same class.
- [ ] AC3 — Given the same rule, when read, then it states what makes the two scripts an exception
  in terms that would apply to another.
- [ ] AC4 — Given `references/CONCURRENCY.md` or `CONCURRENCY-INCIDENTS.md`, when read, then a safe
  shape for an unavoidable multi-row rewrite under the lock is stated.
- [ ] AC5 — Given `tests/citations.test.sh`, when it runs, then every citation of this rule
  resolves.
- [ ] AC6 — Given `tests/reference-size.test.sh`, when it runs, then both files are within their
  goals or carry a recorded justification.

## QA plan

- **Level:** verify — the deliverable is prose in two reference files and no test runner applies;
  the scripted assertions are the scoped greps below plus the citation and size guards.
- **Why this level:** nothing executable changes.
- **Specific checks:** each grep **scoped to the named rule's section**, matching a phrase short
  enough to sit on one source line. `tests/citations.test.sh` and
  `tests/reference-size.test.sh` both run — `references/CONCURRENCY.md` already carries a size
  justification, and this ticket adds to it.

## Out of scope

- Adding a fourth script so the multi-row insert has a compliant path. That is 0048.
- Changing what `./claim` or `./close` do.
- Auditing the repo's history for other stream-editor writes.

## Notes & decisions

- Routed to `develop`: the rule's gap and the class it needs to name are both stated, and the safe
  shape FR3 asks for has been used successfully three times this week.
- Sized `s`. It is Tier 2 rather than Tier 5 because the damage it prevents is silent — a correct
  row removal alongside an incorrect whole-file edit, where the only signal was a diffstat nobody is
  required to read.
- 2026-10-27 — develop (token 7c03), built in `8f391fd`. *Never rewrite `QUEUE.md` by hand* now
  names `sed -i`/`perl -i` and the temp-file rewrite as one class with `Write` and
  read-rebuild-write (FR1), states the exception as *one process holding the lock across the whole
  rebuild and its commit* (FR2), and gives the safe shape — under the lock, to a temp file, kept
  only if the diff is exactly the intended change (FR3). The 0030 narrative is a new
  `CONCURRENCY-INCIDENTS.md` entry, *The stream edit that deleted every blank line* (FR4). Rule
  name unchanged, so its four citations still resolve (FR5; `tests/citations.test.sh` 52/0).
- **Guards: `tests/by-hand-lock.test.sh`, one case per AC1–AC4 plus FR4**, each scoped to its
  section with the file's own `window`/`in_window` helpers and each phrase on one source line
  (the QA plan's "scoped to the named rule's section"). Placed there, not in a new file, because
  that suite's subject is by-hand backlog writes. Red before the prose: 31 passed, 5 failed.
- **Mutation sweep (run), on the subject, restored in the same call** — deleting or rewording each
  guarded phrase reddened exactly its own case and nothing else: AC1 `never an in-place stream edit
  — \`sed -i\`, \`perl -i\`` → `never an in-place edit`; AC2 `a whole-file rewrite through a temp
  file` → `a temp file`; AC3 → the old `holding the lock while they rebuild`; AC4 `keep it only if
  the diff is exactly the intended change` → `keep it`; FR4 `the diffstat` → `the commit`, and the
  heading's `rule: *Never rewrite …*` renamed (window empty, reported). Control 36/0.
- AC6: `tests/reference-size.test.sh` 15/0 — both files already carry recorded justifications.
- Whole suite run file-by-file at `8f391fd`, clean tree: no file red.
