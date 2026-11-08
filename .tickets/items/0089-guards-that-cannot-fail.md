---
id: "0089"
title: Re-anchor the case "$out" guards that cannot fail
type: bug
next:
status: done
qa_level: unit
size: m
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0052", "0063", "0222", "0223", "0224"]
expects:
  - tests/citations.test.sh
  - tests/reporting.test.sh
  - tests/last-line.test.sh
  - tests/skill-size.test.sh
  - tests/money-in-skill-prose.test.sh
  - tests/reference-size.test.sh
  - tests/abort-announce.test.sh
  - tests/declared-copies.test.sh
  - tests/external-feedback.test.sh
  - tests/item-nfr-red.test.sh
  - tests/scaffold-close.test.sh
  - tests/cost-by-category.test.sh
claimed_by:
claimed_at:
touches:
ac_digest: AC1=80aa6a19 AC2=5f92027e AC3=cee5c2a0 AC4=74c1ed2c AC5=f5ee516c
closed: 2026-10-28
---

## Problem

Three of `0085`'s acceptance criteria shared one defect shape and all three closed the ticket
green. AC8 (`*"work"*`), AC9 (`*protocol*`, `*git*`) and AC10 (`*10000*`) were substring `case`
matches over a tool's **whole output**, satisfied by text the tool prints unconditionally; every
one stayed green under mutations that provably landed. AC10 cannot fail at all — `10000` is a
substring of the `ctx/turn` figures `100000`, `110000`, `115000` and `125000` that the same output
carries.

`testing-conventions.md` names the shape twice — *anchor an assertion to the claim, not the
document that contains it*, and *a number present where the contract is that it is formatted* — and
says a suite with a **known systematic weakness of this shape is swept from a loop, not by reading
for the next instance**.

Every guard in this repo greps prose, and there is no test runner behind them
(`.claude/backlog/config.yml`, `commands.unit`). The suite is the only safety net the repo has, so
the exposure is all 21 files in `tests/`, not the one where it was found. A guard that cannot fail
reads exactly like a guard that passes, and it closed a ticket.

Found while verifying `0085` (pointer: `tests/cost-by-category.test.sh`, item `0063`).

## Functional requirements

This row is the `case "$out"` class of the sweep. The other three classes are their own rows, split
out on 2026-10-27: numeric needles under any other subject (`0222`), whole-file and section-scoped
prose guards plus the named helper instances (`0223`), and the standing guard (`0224`).

- FR1 — Every hit of `grep -n 'case "\$out"' tests/*.test.sh` is examined. Each **presence** needle
  is left as, or re-anchored to, a complete line the subject prints, a field extracted from one, or
  a phrase the subject prints only on the asserted condition — or is deleted with its reason
  recorded in *Notes & decisions*. Each **absence** needle stays matched over the whole output:
  narrowing it to one line weakens it.
- FR2 — Within those hits, a presence needle that is a substring of another value the same output
  carries (`10000` inside `100000`) is re-anchored so the two cannot be confused.
- FR3 — Each re-anchored assertion is **mutation-proved**: the sweep records, per file, the change
  applied to the subject under test that turned the assertion red, and that it went green again on
  revert. An assertion for which no such mutation can be found is not re-anchored — it is deleted.
- FR4 — The sweep is driven from the FR1 grep, not by reading for the next instance, and the list
  of files and hits examined is recorded, so a later reader can tell an examined-clean hit from an
  unexamined one.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The per-file mutation evidence from FR3 is written into this item as the sweep runs, not reconstructed at the end | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given the sweep is complete, when `grep -n 'case "\$out"' tests/*.test.sh` is run, then
  every presence needle is either a complete line the subject prints (or a field extracted from one)
  or a phrase the subject prints only on the asserted condition, and every absence needle is matched
  over the whole output. Red if any presence needle is satisfied by text the subject prints
  unconditionally or is a substring of another value the same output carries — or if an absence
  needle such as `tests/external-feedback.test.sh`'s `*EXTERNAL-FEEDBACK*) bad` is narrowed to a
  single extracted line.
- [x] AC2 — Given `tests/cost-by-category.test.sh`, when the figure the AC10-shaped assertion tests
  is changed in the subject from `10000` to `9999`, then that assertion goes **red**. Red-making
  input: the pre-`df07072` code, where the assertion passed with the figure absent because `100000`
  contains it.
- [x] AC3 — Given each file the sweep re-anchored, when this item's *Notes & decisions* is read,
  then it names for that file the mutation applied and the assertion that went red under it. Red if
  any re-anchored file has no such entry.
- [x] AC4 — Given the FR1 grep, when this item's *Notes & decisions* is read, then every file the
  grep hits is listed as examined. Red if a file the grep hits is absent from that list.
- [x] AC5 — Given the whole suite after the sweep, when `for t in tests/*.test.sh; do "$t" || true;
  done` is run against an unmodified tree, then every file reports `0 failed`. Red if any assertion
  was re-anchored onto a claim the code does not actually make.

## QA plan

- **Why that level:** the change is to the test files themselves and the assertions are the
  deliverable, so the runner that exercises them is the suite. `unit` is this project's whole
  suite (`config.yml`).
- **Specific checks:** run the suite file-by-file (`for t in tests/*.test.sh; do "$t" || true;
  done`) rather than through `config.yml`'s fail-fast `unit` line, so one red does not mask the
  twenty behind it. Then re-apply two of the FR3 mutations at random and confirm the named
  assertion reddens.

## Out of scope

- The rewrap-survival matcher — that is `0063`, and an assertion re-anchored here still breaks on a
  reflow until `0063` lands. Where the two touch the same line, leave the reflow problem alone.
- Writing new coverage. This sweep fixes assertions that cannot fail; it does not add assertions
  for behaviour nothing checks.
- `skills/**` prose. The defect is in the guards, not in the rules they guard.
- Numeric needles under any subject other than `"$out"` (`0222`), whole-file and section-scoped
  guards and the helper instances named below (`0223`), and FR5's standing guard (`0224`).

## Notes & decisions

- **2026-10-27 — re-specified by `queue` (sprint run-20261027T185815Z, on the person's answer to
  the escalation).** The code at `d0c5372` is right and stays: both slices' re-anchors are
  mutation-proved below and the suite is green there. What changed is the contract. **AC1 rewritten**
  to the text the 612d slice proposed, with its absence clause made able to red: the old AC1
  demanded every `case "$out"` hit be over a single extracted line, which would have narrowed the
  whole-output absence assertions and weakened them. **Split**, as both develop sessions
  recommended, one row per class: this row keeps the `case "$out"` class and its history; FR2's
  numeric needles under every other subject are `0222`; FR1's whole-file and section-scoped class,
  plus the helper instances the retro notes below name, is `0223`; FR5's standing guard is `0224`,
  which goes to `design` because what a guard can mechanically refuse, now that whole-output absence
  and complete-line presence are both legitimate, is a decision rather than a reading. Old AC4 (the
  `zz-whole-output` fixture) moved with FR5 to `0224`; new AC4 is FR4's examined-list check. `size`
  drops to `m`: 78 hits across 11 files at `d0c5372`, most of them complete lines already. Routed
  to `develop`: the criteria are now writable and no FR waits on a decision. All ACs unticked.

- Routed to `develop` rather than `design`: the corrective shape is already named by
  `testing-conventions.md` and demonstrated in this repo, so no decision blocks the criteria.
- `size: l` because it is 21 files and FR3 requires a mutation per re-anchored assertion. It is a
  sweep, and the batching rule applies inside it: one session, one loop.
- 2026-09-07 — `retro` absorbed five `FINDINGS.md` entries into this row rather than filing a
  second ticket; the sweep this row already scopes is where they belong. Established, so a claiming
  session need not re-derive it:
  - **The `grep -c` pre-filter has three known blind spots and cannot be the only net.** (1) It is
    line-based, so a phrase wrapping across a line break counts as 1 and reads as safely unique —
    which is exactly the phrase most likely to be duplicated in flowing prose. Count on flattened
    text (`tr '\n' ' ' | tr -s ' '`), as `tests/orchestrate.test.sh`'s `section()` helper does.
    (2) A guard over a *filtered stream* (`fenced "$SKILL" | grep -qF`) is semantically whole-file
    and matches no pattern looking for `grep … "$FILE"`; a filter selecting **every** block of a
    kind is not a scope, only a different whole. (3) A file-level count answers the wrong question
    for a **section-scoped** guard: `0039`'s Dependencies guard greps the flattened `## Requirements`
    section for `orchestrate`, which occurs twice *within that section*, so generalising the one
    sentence carrying the attribution left the suite at 105 passed, 0 failed. **Count within the
    guard's own subject, whatever narrowing it applies.**
  - **`case "$out" in "TAKE      0001"*)` is a prefix match on a multi-line capture, not a line
    match.** Any `COLLIDES`, `SKIP`, `DRIFT` or warning line printed ahead of the regression hides
    it. `printf '%s' "$out" | grep -q '^TAKE      0001'` costs the same and says what was meant.
    Worth a sweep for `case "$out" in` across `tests/`.
  - **Where a behaviour is defended by two independent mechanisms, a mutation removing one proves
    nothing.** `0039`'s AC16 fixture needed *both* the status filter and the `touches:` collision
    check broken before the guard would red; single-mutation verified it against the stronger of
    the two only.
  - **An `assert_contains` on a flag name is matched by the prose explaining the flag.** `next`'s
    `usage()` could drop `--drive` from its synopsis *and* delete its five-line description block
    and stay green, because a later paragraph mentions the flag. Pin the mode's own line.
  - **The enumerated-subjects defect is live in this repo's own guards.** `tests/last-line.test.sh`
    and `tests/reporting.test.sh` carried hardcoded `SKILLS=` lists (now derived);
    `grep -n '^[A-Z_]*=\"[a-z ]*\"' tests/*.test.sh` finds the rest and nobody has run it.
  The generalisable half of all of this landed in `testing-conventions.md` on 2026-09-07; what stays
  here is the repo-specific sweep.

- 2026-09-09 (retro, from `FINDINGS.md` 2026-09-08) — **three more instances for the sweep, each
  verified by mutation at the time it was parked.**
  1. **A guard anchored to a literal that the guarded prose does not use.**
     `tests/orchestrate.test.sh`'s AC25 greps `(rm|rmdir|unlink)[^|]*\.lock` over the fenced blocks,
     but the block it guards opens `LOCK=.claude/backlog/.lock` and says `"$LOCK"` everywhere after.
     A fenced `rm -rf "$LOCK"` leaves the suite at 130 passed while doing exactly what FR15 forbids.
     The delivered prose is clean either way, so this is coverage of the one clause whose whole point
     is that a future edit must not slip it in.
  2. **A guard that checks a citation and not the number beneath it.** AC26 asserts
     `MEASUREMENT.md`'s per-stage means appear in the comment above `stage_budget_usd:`; nothing
     relates that comment to the value. Setting `retro: 99.00` with its `2.51` citation intact
     leaves the suite green. Two things for whoever takes it: the arithmetic could be asserted from
     the cited mean, and the **rounding granularity is unstated** — all three shipped caps are mean
     x 1.5 rounded to the nearest five cents (6.05, 5.45, 3.75), which is self-consistent, but the
     comment says only "times 1.5", so an honest recompute yields 6.04 and 3.76 and reads as drift.
  3. **A guard whose file scope includes `tests/` also covers its own source, and its fixture
     literals become real citations.** `0105`'s item-ID check reported `tests/citations.test.sh` on
     its first run, correctly: the unresolvable id its fixtures need was spelled in an anchored form
     inside a covered file. Fixed there with a variable; the shape generalises to any guard that
     scans the directory it lives in.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** Twelve findings-buffer entries (2026-09-10..12) are more instances of this ticket's class, each found by a mutation that did not redden: `tests/orchestrate.test.sh` (now `sprint.test.sh`) `section()` matching a heading as a prefix, so an absence assertion over an empty extraction is green forever; a `says` token satisfied by a code fence in the same section; `tests/batching.test.sh` `binds()` spanning a sentence break; `tests/falsifiable-acs.test.sh` `window()` whose `!first` clause can never fire (`first = 1` is the fix); `tests/sprint-ledger.test.sh` AC6 awk reporting only inside its last branch, so a missing denominator is invisible (needs an `END` block); `assert_contains "DISPATCH  verify 0102"` passing on a batch (a list assertion is an equality); `paired()` satisfied by a default estimate the tool forges (anchor on the source, not the figure); an error message too shredded to assert on inviting a loosened assertion; `qa-level-once` not seeing a stale *Why that level* rationale; `add_item_blank_scope` silently setting `claimed_by`; fixture titles describing a state their bytes do not build; and low fixture ids colliding with real ids in `develop` Step 2's own-id grep. The general forms are `testing-conventions.md` material; the instances are this sweep's.
- **2026-10-06 (retro, run-20261004T232135Z tail, absorbed from FINDINGS.md).** Two more instances, parked by verify 0161 (2026-09-25): `tests/handoff.test.sh` FR2 "touches: entries written at column 0 are cleared too" calls `assert_no_item_line … '- src/two.ts'`, a pattern beginning with `-`, so BSD grep prints `invalid option --` and the case reports `ok` whatever the file holds — needs `grep -e`/`--` or a fixed-string compare, and a mutation proving it reddens. And `tests/backlog-scripts-installed.test.sh`: removing `reopen` from `SCRIPTS=` stays green (45→37 passed, 0 failed), because `handoff.test.sh` pins only the prefix `SCRIPTS="next claim close handoff`; no guard notices a script dropping out of the install check.
- **2026-10-25 — develop (aab8): a first slice, released back to `develop` unfinished.** The sweep
  is larger than one session: `tests/` now holds **34** files, not the 21 FR4 and `expects:` name
  (a stale figure — the loop is over whatever `tests/*.test.sh` holds, so the contract stands), and
  FR5's guard cannot land until FR1/FR2 are complete, or it reds the current tree. What this slice did:
  - **AC2 — already discharged by `df07072`, proven now (run).** The `*10000*` assertion was
    re-anchored to an exact `marg/turn` cell compare under 0085. The AC's own mutation, in a scratch
    copy, `turnb 2 110000` → `109999` (protocol's appended figure 10000 → 9999): `AC10 — protocol
    reports a marginal footprint of 9999` red, 27 passed / 2 failed; control 29/0.
  - **`tests/sprint.test.sh` — re-anchored in `4766607` (examined: its six `case "$out"` hits).**
    AC13's four harvest assertions now read their own line's field (`bound_field FLOOR|GROWTH|TURNS`,
    `bound_line TURNS`) and compare for equality; AC16's two `next develop` assertions grep the
    `^TAKE      000n ` line. Mutations on the SUBJECT, scratch root, each adding exactly its own red
    to the scratch control (the scratch root is not a git checkout, so 8 unrelated `0165 AC2` cases
    fail there at baseline; the real-tree suite is green):
    - `tools/harvest-usage.sh` growth ×10 (prints 15000) → `the GROWTH line does not read 1500`.
      **The old `*"GROWTH"*1500*` stayed green on 15000 — run** — the FR2 class.
    - floor + 4500 (prints 24500, the last turn) → `the FLOOR line does not read 20000`.
    - TURNS `%.1f` → `%.2f` (prints 2.00) → `the TURNS line does not read 2.0`. **The old
      `*"TURNS"*2.0*` stayed green on 2.00 — run.**
    - `against a budget of` → `against a limit of` → `nothing to judge it against`.
    - `next` printing `SKIP      0002` in place of `TAKE` → `did not offer the free row`; the old
      `*0002*` would match that SKIP line (reasoned from the pattern).
    - The `0001` negative: disabling the held-row skip in the take loop alone did NOT red — the
      row is defended by a second mechanism too (the double-defence case recorded above, run).
      Proved falsifiable instead by injecting `NOTE … \nTAKE      0001 | injected` ahead of the real
      TAKE → `the orphaned claim on 0001 was offered as takeable`. The old prefix match
      `"TAKE      0001"*` would have missed that line behind the NOTE (reasoned).
  - **Examined-clean or examined-and-done so far:** `tests/cost-by-category.test.sh` (AC2 only —
    its other `case "$OUT"` hits at lines 115/119/187 are not yet examined), `tests/sprint.test.sh`
    (the six `case "$out"` hits only; its other whole-output matches are not yet examined).
  - **Remaining worklist, from the loop rather than from reading** (run 2026-10-25):
    - AC1 — `grep -n 'case "\$out"' tests/*.test.sh` still hits 66 times: `citations` 18,
      `reporting` 16, `last-line` 10, `money-in-skill-prose` 8, `skill-size` 6, `reference-size` 5,
      `external-feedback` 3. Most needles there are a complete, specific line (e.g. `'FAIL
      skills/develop/SKILL.md cites "…", which is not a rule'`), which cannot be satisfied by
      unrelated text — but AC1 as written asks for every hit to be against an extracted line, so
      each still needs the `grep`-the-line form and a mutation.
    - FR2 — numeric needles inside a glob, `grep -nE '^\s*\*[^)]*[0-9]{2,}[^)]*\*\)' tests/*.test.sh`:
      ~40 hits outside `sprint.test.sh`, densest in `sprint-ledger` (`*2.00*`, `*10.00*`, `*0.00*`
      — each a substring of a larger figure the same output can carry), `measurement`
      (`*"30.00"*`, `*"35.87"*`), `cost-by-category` (`*0.2550*`, `*0.0525*`), `close-by`.
    - FR1's whole-FILE class (`grep … "$FILE"` over a whole document) has not been looped yet.
    - FR5 last, once the tree carries no instance for it to red on.
  - **Suggest `queue` split this row** (only `queue` may): one row per class above (AC1 `case
    "$out"`, FR2 numeric needles, FR1 whole-file, FR5 guard), each a sitting, with FR5 `blocked_by`
    the other three. As one `l` it has now been claimed once and released partly done.
- 2026-10-27 — retro 2026-10-27 (tail of run-20261025T215324Z), from a FINDINGS.md park, two more guards that cannot fail: (1) `tests/handoff.test.sh` ~line 371, `assert_no_item_line "the column-0 entry is gone" '- src/two.ts'` — the helper runs `grep -Fxq "$2"` with no `--`, so a pattern starting with `-` is an option, grep exits 2 and the helper reads it as absent (stray `grep: invalid option --` at baseline 811130d); fix `grep -Fxq -- "$2"` in it and `assert_item_line`. (2) `tests/backlog-location.test.sh` 0182 AC9: deleting the sentence carrying `before migrating it` left 48 passed; assert that phrase, not `install`.
- **2026-10-27 — develop (612d): a second slice, then handed to `queue` over AC1.** Commits
  `1a71387`, `d0c5372`. Every mutation below was **run**, on the subject, restored in the same
  call, with a control run green after it.
  - **`tests/handoff.test.sh` — `assert_item_line`, `assert_no_item_line` and the QUEUE.md line
    helper passed `"$2"` to `grep -Fxq` with no `--`** (the 2026-10-06 and 2026-10-27 instances).
    Fixed to `grep -Fxq -- "$2"`. Mutation: `skills/queue/templates/handoff`'s skiplist
    `/^[ \t]*- /` → `/^[ \t]+- /` (column-0 entries survive). Fixed guard: `FAIL — the column-0
    entry is gone`. The HEAD~1 copy under the same mutation printed `grep: invalid option --` and
    left that case `ok`. (It is defended twice: `exits 0` reds under the mutation in both copies,
    the read-back refusing the hand-off — so the old case was not the only net, but it could not
    fail.)
  - **`tests/backlog-location.test.sh` 0182 AC9 — `install` re-anchored to `before migrating
    it`**, and the 0221 fixture `NOTE_FULL` given the phrase. Mutation: `CHANGELOG.md`'s sentence
    `**Install this release on every machine that works a repo before migrating it** — … — and
    check` reduced to `Check`. New guard: `FAIL 0182 AC9 — the 0182 entry does not name before
    migrating it`, 56/1. HEAD~1 copy: 57/0 — `install` was satisfied by "installed beside the others".
  - **`tests/backlog-scripts-installed.test.sh` — `SCRIPTS=` derived** as the union of executables
    in `skills/queue/templates/` and `.claude/backlog/`, and `tests/handoff.test.sh`'s literal
    pin on `SCRIPTS="next claim close handoff` replaced by asserting the handoff template is
    executable (the derivation's input). Mutations: template `reopen` moved away → 3 FAIL (`cannot
    parse`, `cannot scan`, `cannot diff`), 52/3; installed `reopen` moved away → 5 FAIL. **Not
    covered, reasoned and run:** `chmod -x` on a template stays 55/0 — the installed copy keeps it
    in the union and no check asserts a template's mode. New coverage, so out of this row's scope.
  - **Examined so far, now across both slices:** `sprint` (six `case "$out"`), `cost-by-category`
    (AC2 only), `handoff` (the line helpers), `backlog-location` (AC9), `backlog-scripts-installed`
    (`SCRIPTS=`). `external-feedback` and `reference-size` read, not changed (see below).
  - **AC1 is wrong as written — proposed for `queue`, not edited.** It requires *every* `case
    "$out"` hit to be against a single extracted line. The remaining hits (now 78: `citations` 18,
    `reporting` 16, `last-line` 10, `skill-size` 9, `money-in-skill-prose` 8, `reference-size` 5,
    `abort-announce` 3, `declared-copies` 3, `external-feedback` 3, `item-nfr-red` 2,
    `scaffold-close` 1) include **absence** assertions — `external-feedback.test.sh:156`
    `*EXTERNAL-FEEDBACK*) bad`, `reference-size.test.sh:234` `*"references/RECORDED.md"*) bad` —
    which are correct *only* over the whole output; narrowing them to one line makes them weaker,
    the opposite of this row's outcome. Most presence needles there are a complete path or line from
    a fixture-fed guard printing a few lines, not text the subject prints unconditionally.
    Proposed AC1: *"Given the sweep is complete, when `grep -n 'case \"\$out\"' tests/*.test.sh`
    is run, then every presence needle is either a complete line the subject prints (or a field
    extracted from one) or a phrase the subject prints only on the asserted condition, and every
    absence needle is matched over the whole output. Red if any presence needle is satisfied by
    text the subject prints unconditionally or is a substring of another value the same output
    carries."*
  - **And the split the 2026-10-25 slice suggested still stands** — this is the second session to
    release the row partly done. One row per class (AC1 `case "$out"` under the corrected text, FR2
    numeric needles, FR1 whole-file, FR5 guard `blocked_by` the other three) is a sitting each.
  - Whole suite run file-by-file at `d0c5372`, clean tree: no file red.
- **2026-10-27 — develop (8dbb), against the re-specified ACs.** Commit `b7de8e7`. Driven from the
  FR1 grep (FR4): `grep -n 'case "\$out"' tests/*.test.sh` at `c6b8483` hit **78 times in 11
  files**. Every hit was opened with its arms and classified; two were re-anchored, none deleted.
  - **Examined (AC4), every file the grep hits, with its classification:**
    - `tests/abort-announce.test.sh` (3: 119, 149, 156) — clean. 120 is the complete ABORTED line,
      its count bounded by `: ` and ` failed`; 150 is an absence over the whole output; 151's
      `3 passed, $fails failed` is the fixture's own tally line, bounded by ` failed`, and the
      `*ABORTED*` arm ahead of it stops an ABORTED line satisfying it; 157 `cleanup ran` is printed
      only when the fixture's trap runs its cleanup.
    - `tests/citations.test.sh` (18: 392, 402, 412, 423, 433, 444, 471, 479, 489, 500, 692, 701,
      711, 721, 733, 743, 752, 762) — clean. Each presence needle is a whole `FAIL`/`INFO`/`SKIP`/
      `COUNT` line, or a `cites "<name>", which is not a rule` / `cites item 0404, which is in no
      table` phrase printed only when that citation fails; `COUNT 1 ids, 1 cited` has both figures
      bounded by fixed text; 711 is an equality. 412, 444, 471, 701, 743 open with whole-output
      absence arms (`FAIL `, the narrative phrase), left whole-output (FR1).
    - `tests/declared-copies.test.sh` (3: 159, 173, 230) — clean. 159 is `expect_red`'s loop: its
      eight call sites (185–254) pass fixture-specific strings the guard prints only in the FAIL
      line for that fixture — run on the AC7 fixture, `skills/queue/templates/handoff` appears
      only in `FAIL — block scope-block differs between …close:369 and …handoff:352`. 173's
      `<name>: N copies, identical` is the `ok   — ` line's field, the count bounded by `: ` and
      ` copies`. 230 is an absence.
    - `tests/external-feedback.test.sh` (3: 134, 153, 155) — clean. The guard prints nothing on a
      clean tree (the `""` arm), so the fixture path appears only when reported; 156's
      `*EXTERNAL-FEEDBACK*) bad` stays whole-output (FR1, AC1's named example).
    - `tests/item-nfr-red.test.sh` (2: 172, 180) — clean; each needle is the report line for its
      fixture item and dimension.
    - `tests/last-line.test.sh` (10: 225, 234, 236, 247, 257, 267, 277, 287, 297, 307) — clean.
      Each presence needle is a whole `FAIL  <file> …` line for the one mutated fixture file; 225
      and 236 are whole-output absences.
    - `tests/money-in-skill-prose.test.sh` (8: 170, 179, 181, 192, 202, 213, 223, 232) — clean.
      Whole `FAIL  <file>:3 carries a $ before a digit` lines; 170, 181, 223 absences; 232's two
      fragments are the one line `FAIL  <root>/skills does not exist`.
    - `tests/reference-size.test.sh` (5: 176, 178, 221, 231, 233) — **176 re-anchored (FR2)**, the
      rest clean: 179's relocation phrase and 221's `remove its stale justification` are printed
      only in the over-goal and stale branches of `offenders`; 232 a fixture path printed only
      when reported; 234 an absence.
    - `tests/reporting.test.sh` (16: 341, 350, 352, 363, 373, 383, 393, 403, 413, 423, 433, 443,
      453, 463, 475, 485) — clean. Whole `FAIL` lines or their prefix up to `at line`, each printed
      only for its fixture's defect; `routes 5 kinds` / `routes 3 kinds` are bounded by `routes `
      and ` kinds`; 341 and 352 absences.
    - `tests/scaffold-close.test.sh` (1: 104) — clean; an absence (`left blank`), whole-output.
    - `tests/skill-size.test.sh` (9: 252, 262, 267, 307, 315, 331, 341, 352, 354) — **252
      re-anchored (FR2)**, the rest clean: 263/268/316 are phrases only the over-goal / stale
      branches print; 308/332/342 pair the fixture's path with the branch's own remedy phrase, and
      each fixture holds one file, so both fragments come from its one line; 332's `$want` figures
      are bounded by `is `/` bytes, `/` past the `; 353 a path, 355 an absence.
  - **Re-anchored (AC3), each mutation run on the subject — the file's own `offenders()` — in a
    scratch copy `tests/.mut-<name>.test.sh` (hidden, so no concurrent `tests/*.test.sh` glob
    reaches it), removed in the same call:**
    - `tests/skill-size.test.sh:253` — `… over the $GOAL goal by 500` → `… by 500 — `. FR2: `by 500`
      is a substring of `by 5000`. Mutation: the overage `$((bytes - GOAL))` → `$((bytes - GOAL))0`
      (prints `by 5000`). New guard: `FAIL AC4 — reported something else: skills/padded/SKILL.md
      is 20690 bytes, over the 20190 goal by 5000 — …`. Same mutation on the `HEAD~1` copy: 45
      passed, 0 failed — the old needle could not see it. Unmutated: 45/0.
    - `tests/reference-size.test.sh:177` — same re-anchor, same mutation. New guard: `FAIL AC2 —
      reported something else: references/PADDED.md is 6557 bytes, over the 6057 goal by 5000 — …`.
      `HEAD~1` copy under it: 15/0. Unmutated: 15/0.
  - **AC2 (run again this session, in `tests/.mut-cbc.test.sh`).** `turnb 2 110000` → `109999`
    makes protocol's appended figure 9999: `FAIL AC10 — protocol reports a marginal footprint of
    9999, not the 10000 it appended`, 27/2; control 29/0. Red-making input: `df07072`'s copy, whose
    `case "$OUT" in *10000*)` was removed in `66a440c`, with its fixture's rises set to 9999
    (`turn 2/3/4` at 109999/119998/129997) — `ok a marginal footprint of 10000 per turn is
    reported`, 10/0: green with the figure absent, because `100000` still prints.
  - **Clause table** (AC text → evidence; all run unless marked):

    | AC | Clause | Evidence |
    |---|---|---|
    | AC1 | Given the sweep is complete, the FR1 grep is run | 78 hits, 11 files, listed above |
    | AC1 | every presence needle is a complete line / field / phrase printed only on the condition | per-file classification above (reasoned per hit; the two exceptions re-anchored) |
    | AC1 | red if satisfied by text printed unconditionally | none found; `handoff` path checked by running the AC7 fixture |
    | AC1 | red if a substring of another value the same output carries | skill-size 253, reference-size 177 — mutated ×10, old green, new red |
    | AC1 | every absence needle matched over the whole output; red if narrowed to one line | no absence arm touched; `external-feedback.test.sh:156` unchanged |
    | AC2 | 10000 → 9999 in the subject reds the AC10-shaped assertion | 27/2, control 29/0 |
    | AC2 | red-making input: pre-`df07072` code passed with the figure absent | `df07072` copy, rises 9999, 10/0 |
    | AC3 | each re-anchored file names its mutation and the red assertion | both entries above |
    | AC4 | every file the grep hits is listed as examined | 11 of 11 above |
    | AC5 | whole suite, file-by-file, unmodified tree, every file `0 failed` | below |
  - **AC5:** whole suite file-by-file at `b7de8e7`, `git status --porcelain` clean but for this
    note's scratch file (untracked, read by no suite): 44 files, every one `0 failed`.
  - `qa_level: unit` kept; `close_by` absent, so `verify` closes it. Out of scope, untouched: the
    uppercase `case "$OUT"` hits elsewhere in `cost-by-category.test.sh` (not FR1's grep; `0222`/`0223`).
- **2026-10-27 — verify (token a38d): PASS.** Every AC re-checked from this session's own runs; table under *QA evidence*.

## QA evidence

### 2026-10-27 — verify (token a38d): PASS

Conventions: ../ai-building-conventions
Level: `qa_level: unit`, `commands.unit` as configured; no lint or typecheck configured. Run in the
reporting form so every file reports, verbatim: `git status --porcelain; for t in tests/*.test.sh;
do "$t" || true; done` (`commands.unit_by_file`) at `4fedb0f` — porcelain empty, all 44 files
`0 failed`. Mutations were run on scratch copies `tests/.mut-<name>.test.sh` (hidden, so no
`tests/*.test.sh` glob collects them; the subject of the size guards is each file's own
`offenders()`), each removed in the same call, with `git status --porcelain` clean afterwards.
`ac_digest matches` (`./next --ac-digest 0089 --check`).
Dirty set at Step 2: empty. Evidence set: the 11 files the FR1 grep hits (listed under AC4),
`tests/cost-by-category.test.sh`, and the whole `tests/` suite (AC5). Fresh capture after the last
check: empty but for this session's untracked `.verify-scratch/`. Intersection: empty — not advisory.

**FR1 grep, re-run:** `grep -n 'case "\$out"' tests/*.test.sh` → 78 hits in 11 files
(`abort-announce` 3, `citations` 18, `declared-copies` 3, `external-feedback` 3, `item-nfr-red` 2,
`last-line` 10, `money-in-skill-prose` 8, `reference-size` 5, `reporting` 16, `scaffold-close` 1,
`skill-size` 9), matching develop 8dbb's list exactly.

**Clause table** — develop 8dbb's rows, reused; every result below was run in this session.

| AC | Row | How checked | Result |
|---|---|---|---|
| AC1 | Given the sweep is complete, the FR1 grep is run | grep re-run | 78 hits / 11 files |
| AC1 | every presence needle is a complete line, a field, or a phrase printed only on the condition | every hit's arms read again; branch-only phrases confirmed at their `echo` sites (`skill-size.test.sh:187/191/194`, `reference-size.test.sh:114/117`); numeric needles bounded by fixed text on both sides (`tally: 1 passed`, `md 2 times`, `routes 5 kinds`, `: N copies`) | holds |
| AC1 | red if satisfied by text printed unconditionally | spot mutation: `skill-size` over-goal branch drops `$RELOCATE` → 263 and 268 both red (43/2); `citations.test.sh:213` `which is not a rule` → `which is fine` → 393 and 403 red (50/2) | RED, as classified |
| AC1 | red if a substring of another value the same output carries | overage `$((bytes - GOAL))` → `…0` (prints `by 5000`): `skill-size` 44/1, `reference-size` 14/1; the same mutation on each `b7de8e7~1` copy stays 45/0 and 15/0; controls 45/0, 15/0 | RED; old needles green |
| AC1 | every absence needle matched over the whole output; red if one is narrowed | each absence arm's `out=` read back: all 15 are the subject's whole output (`mentions`, `offenders`, `audit`, `item_audit`, `conventions_audit`, `close … 2>&1`, the fixture's `2>&1`); `external-feedback.test.sh:156` `*EXTERNAL-FEEDBACK*) bad` unchanged; `b7de8e7` touches only the two presence needles | holds |
| AC2 | the figure 10000 → 9999 in the subject reds the AC10-shaped assertion | `turnb 2 110000` → `109999`: `FAIL AC10 — protocol reports a marginal footprint of 9999, not the 10000 it appended`, 27/2; control 29/0 | RED |
| AC2 | red-making input: pre-`df07072` code passed with the figure absent | `df07072`'s copy, rises set to 9999 (turns 2–4 at 109999/119998/129997): `ok a marginal footprint of 10000 per turn is reported`, 10/0 | green with figure absent — confirmed |
| AC3 | each re-anchored file names its mutation and the red assertion | *Notes & decisions* read: `sprint` (4766607), `handoff`, `backlog-location`, `backlog-scripts-installed` (1a71387/d0c5372), `skill-size`, `reference-size` (b7de8e7), `cost-by-category` (AC2) — each with its mutation and the case that reddened | holds |
| AC4 | every file the grep hits is listed as examined | 11 of 11 in develop 8dbb's *Examined* list | holds |
| AC5 | whole suite, file-by-file, unmodified tree, every file `0 failed` | `commands.unit_by_file` at `4fedb0f` | 44 files, `0 failed` |

| Check | How | Result |
|---|---|---|
| AC1 | every hit re-read, both red clauses mutation-proved, absence arms checked whole-output | PASS |
| AC2 | mutation red 27/2; red-making input green 10/0 | PASS |
| AC3 | notes name mutation and red assertion for every re-anchored file | PASS |
| AC4 | 11 of 11 files listed | PASS |
| AC5 | 44 files `0 failed` | PASS |
| NFR Documentation | per-file mutation evidence written into the notes slice by slice (2026-10-25, two on 2026-10-27), dated as it ran; holds on reading, **unguarded** (no check could red on it) | holds; unguarded |
| Newly reachable | test-only change; nothing made reachable | none |
| Always-on (`CONVENTIONS_CORE.md`) | `4766607`, `1a71387`, `d0c5372`, `b7de8e7` carry the trailer; no secrets or company material | holds |

No release note: the change is to the guards only, and no session running these skills behaves
differently.
