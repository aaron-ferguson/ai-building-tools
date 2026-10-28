---
id: "0065"
title: Name stream editors in the rule against rewriting QUEUE.md
type: bug
next: verify
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
claimed_by: "4922"
claimed_at: 2026-10-28T02:54:33Z
touches:
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
- **2026-10-27 — verify (token c7ec), FAIL → `develop`. The prose is right; five clause rows have
  no guard.** The build notes carry no clause table, so the sweep mutated only the guard's own
  phrases, which `develop`'s *A mutation sweep enumerates from the AC text* rule names as covering
  nothing new. Each mutation below was applied to `references/CONCURRENCY.md`, landed (non-empty
  diff), left `tests/by-hand-lock.test.sh` at 36/0, and removed the AC's phrase from the section
  (gap test, whitespace-tolerant):
  1. **AC2 predicate:** `— and never` before `**a whole-file rewrite through a temp file**` →
     `— but allow`. The temp-file rewrite is now *permitted* and the guard stays green, because its
     phrase omits the prohibition.
  2. **AC2 "the same class":** dropping `: one class` stays green. The AC says "same class" and the
     prose says "one class", so no guard can assert the AC's words.
  3. **AC3 "in terms that would apply to another":** deleting `**An exception is a script, never a
     technique** —` and `, and another would need the same` stays green.
  4. **AC4 "under the lock":** `is made under the lock to a temp file:` → `is made to a temp file:`
     stays green.
  5. **AC4 "unavoidable multi-row":** `**A multi-row rewrite by hand that cannot be avoided**` →
     `**A rewrite by hand**` stays green.
  **The constraint:** every row above needs a guard in `tests/by-hand-lock.test.sh`'s 0065 block,
  scoped to the rule's section, that reds under that mutation. Where the prose only paraphrases the
  AC (rows 2 and 3: "one class" for "same class", nothing at all for "apply to another"), reword the
  prose to the AC's words in this round, per `develop`'s gap-test rule (0180). Each asserted phrase
  goes on one source line. Write the clause table into the build notes this time.
- **2026-10-27 — develop (fe71), re-developed against verify's gaps 1–5.** Commit `69b5856`.
  The rule now uses the ACs' own words, each asserted phrase on one source line:
  `**never in-place stream editing — 'sed -i', 'perl -i'**` (AC1, was "an in-place stream
  edit"); `**never a whole-file rewrite through a temp file** (…), the same class as 'Write'` (AC2
  — the prohibition and "same class" were the unguarded gaps 1–2); `**An exception is a script,
  never a technique.** './claim' and './close' are the exception` / `in terms that would apply
  to another: one process holding the lock across the whole rebuild and its commit.` (AC3, gap 3);
  `**The safe shape for an unavoidable multi-row rewrite under the lock:** write it to a temp file,
  keep it only if the diff is exactly the intended change, … and abandon it otherwise.` (AC4, gaps
  4–5). `tests/by-hand-lock.test.sh`'s 0065 block grows from 4+1 to 9+1 cases, one per clause.
  New guards against the `HEAD~1` prose (scratch copy, restored): 35 passed, 6 failed — every new
  phrase red. `in_window` flattens whitespace, but every phrase is on one line anyway (CLAUDE.md).
  - **Clause table** — every mutation **run** by `/tmp/dev-fe71/sweep.py` on the committed subject,
    restored by `git checkout --` in the same call; "gone" is the gap test (the AC's phrase no
    longer in the flattened section). Control after: 41/0, porcelain clean.

    | AC | Row (AC words) | Mutation | Result |
    |---|---|---|---|
    | AC1 | Given: *Never rewrite 'QUEUE.md' by hand* | heading → '## Never hand-edit the queue' | RED 32/9 (window empty) |
    | AC1 | predicate: names … as prohibited | '**never in-place stream editing' → '**allow …' | RED 40/1, gone |
    | AC1 | object: in-place stream editing | → 'in-place editing' | RED 40/1, gone |
    | AC2 | object: a whole-file rewrite through a temp file | → 'a temp-file rewrite' | RED 40/1, gone |
    | AC2 | predicate (gap 1): named as prohibited | '**never a whole-file' → '**allow a whole-file' | RED 40/1, gone |
    | AC2 | "as the same class" (gap 2) | drop ', the same class as 'Write'' | RED 40/1, gone |
    | AC3 | predicate: what makes the scripts an exception | 'one process holding the lock … commit' → 'being the two scripts' | RED 40/1 |
    | AC3 | subject: the two scripts | ''./claim' and './close' are the exception' → 'They are the exception' | RED 40/1 |
    | AC3 | qualifier (gap 3): in terms that would apply to another | delete the lead sentence and 'in terms that would apply to another:' → 'because of' | RED 40/1, gone |
    | AC4 | object: a safe shape | 'The safe shape for' → 'A shape for' | RED 40/1, gone |
    | AC4 | qualifier (gap 4): under the lock | 'rewrite under the lock:' → 'rewrite:' | RED 40/1, gone |
    | AC4 | qualifier (gap 5): unavoidable multi-row rewrite | 'an unavoidable multi-row rewrite' → 'a rewrite' | RED 40/1, gone |
    | AC4 | shape: kept only if the diff is exactly the intended change | → 'keep it' | RED 40/1 |
    | AC4 | shape: abandoned otherwise | → 'and keep it otherwise' | RED 40/1 |
    | AC5 | every citation of this rule resolves | heading renamed, 'tests/citations.test.sh' | RED 51/5; control 52/0 |
    | AC6 | both files within goal or justified | not re-run: unchanged this round, verify's row stands (reasoned) | 'tests/reference-size.test.sh' 15/0 |
    | FR4 | the incident's diffstat in 'CONCURRENCY-INCIDENTS.md' | 'the diffstat' → 'the commit' | RED 40/1 |

    AC4's three qualifier rows red the one case asserting 'safe shape for an unavoidable multi-row
    rewrite under the lock' — the AC's own words, so a mutation of any of them reds it.
  - Whole suite file-by-file at `69b5856` (only this item dirty): 44 files, every one `0 failed`.
    `qa_level: verify` kept; no `close_by`, so `verify` closes it.

## QA evidence

Conventions: ../ai-building-conventions
Level: `qa_level: verify` (scripted assertions named by the QA plan). There is no lint or
typecheck configured. Commands run:
`for t in tests/*.test.sh; do "$t" || true; done` (`commands.unit_by_file`, every file reporting)
at `7a4451a`, with `git status --porcelain` empty in the same call. Mutations were run with
`python3 .verify-scratch/mutate.py` (scratch, not committed), each restored by path and checked with
`git diff --quiet -- <path>`.
`ac_digest absent — unverifiable` (`./next --ac-digest 0065 --check`).
Dirty set at Step 2: empty. Evidence set: `references/CONCURRENCY.md`,
`references/CONCURRENCY-INCIDENTS.md`, `tests/by-hand-lock.test.sh`, `tests/citations.test.sh`,
`tests/reference-size.test.sh`. Intersection: empty, so the label is not advisory.

**Clause table**

| AC | Row | Mutation | Result |
|---|---|---|---|
| AC1 | Given: the *Never rewrite `QUEUE.md` by hand* section | (the guard's `window`; an empty window reds by construction) | — |
| AC1 | predicate + object: names in-place stream editing as prohibited | `never an in-place stream edit` → `an in-place stream edit is fine` | RED 35/1 |
| AC2 | object: a whole-file rewrite through a temp file | → `a temp-file rewrite` | RED 35/1 |
| AC2 | predicate: named as prohibited (`and never`) | `— and never` → `— but allow` | **GREEN 36/0 — gap** |
| AC2 | "as the same class" | drop `: one class` | **GREEN 36/0 — gap** |
| AC3 | predicate: what makes the scripts the exception | `one process holding the lock across the whole rebuild and its commit` → `being the two scripts` | RED 35/1 |
| AC3 | qualifier: in terms that would apply to another | delete `An exception is a script, never a technique` + `another would need the same` | **GREEN 36/0 — gap** |
| AC4 | predicate/object: a safe shape is stated | `keep it only if the diff is exactly the intended change` → `keep it` | RED 35/1 |
| AC4 | qualifier: under the lock | `is made under the lock to a temp file` → `is made to a temp file` | **GREEN 36/0 — gap** |
| AC4 | qualifier: unavoidable multi-row rewrite | `A multi-row rewrite by hand that cannot be avoided` → `A rewrite by hand` | **GREEN 36/0 — gap** |
| AC5 | every citation of the rule resolves | heading renamed `## Never hand-edit the queue` | RED, `tests/citations.test.sh` 51/5 |
| AC6 | both files within goal or justified | `tests/reference-size.test.sh`'s `references/CONCURRENCY.md` justification case retargeted | RED 14/1 ("25705 bytes, over the 6057 goal") |
| FR4 | incident and its diffstat are in `CONCURRENCY-INCIDENTS.md` | `only signal was the diffstat` → `only signal was the commit` | RED 35/1 |

Controls after the sweep: `tests/by-hand-lock.test.sh` 36 passed, 0 failed;
`tests/citations.test.sh` 52 passed, 0 failed; `tests/reference-size.test.sh` 15 passed, 0 failed.

| Check | How | Result |
|---|---|---|
| AC1 | `tests/by-hand-lock.test.sh` AC1 case, mutation-proved | PASS |
| AC2 | object guarded; the predicate and "same class" are unguarded | **FAIL — gaps 1, 2** |
| AC3 | predicate guarded; the qualifier is unguarded | **FAIL — gap 3** |
| AC4 | predicate guarded; "under the lock" and "multi-row" unguarded | **FAIL — gaps 4, 5** |
| AC5 | `tests/citations.test.sh` 52 passed, 0 failed; reds on rename | PASS |
| AC6 | `tests/reference-size.test.sh` 15 passed, 0 failed; reds without the justification | PASS |
| NFR Documentation | the narrative is in `CONCURRENCY-INCIDENTS.md`, and the FR4 guard reds on it. "The failure in one clause" holds on reading and is unguarded | holds; one half unguarded |
| Suite | 44 files, each `passed, 0 failed` (`commands.unit_by_file`) | green |
| Always-on (`CONVENTIONS_CORE.md`) | prose-only change, commits carry the trailer, no secrets or company material | holds |
