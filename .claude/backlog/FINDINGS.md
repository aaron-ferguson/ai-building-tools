# Findings — parked, not yet placed

**One or two lines each, dated.** A buffer, not a second backlog: it holds findings whose home is
**not local and not yet decided** — a possible row, a suspected skill or convention problem, a cost
pattern nobody has named yet.

**If a finding's home is obvious, write it there instead and do not park it.** A mechanism goes in a
comment beside the code, a rule goes in a test that fails, a unit of work goes to `queue` as a row.
Parking those is how a session ends with nothing written down *and* a growing file.

Format: `- YYYY-MM-DD — **what happened.** why it might matter (pointer: file, item id)`

**The date goes outside the bold, and this is load-bearing.** Every sweeper and `./next --findings`
find entries by line shape, so an entry whose date sits inside the `**` is skipped and nobody ever
notices — two such entries once made `MEASUREMENT.md` publish 26 findings in one sentence and 28 two
paragraphs later. Readers match `^- (\*\*)?20[0-9]{2}-` to tolerate the drift; writers use the
canonical form so as not to add to it. **Entry order is not guaranteed** — sessions have appended at
both ends — so a sweep reads to the end rather than stopping at the first entry outside its window.

**The date is UTC**, like `claimed_at:` in an item's frontmatter. Two sessions working the same hour
either side of midnight otherwise write different dates and both are defensible — and `retro` Step 1
expires entries on age, so the ambiguity lands on the one decision the date is actually read for.

**Refer to a sibling entry by item id or file path, and never by quoting it.** A sweeper removes the
entry it processed and cannot know another entry quoted it, so the quote resolves to nothing while
still reading as though the evidence is at hand — worse than a dead link, which at least announces
itself. An id or a path survives the removal, and a quoted phrase is not a key anything could check.

**A sweeper marks an entry on the way out with a head token, immediately after the date:**

```
- 2026-09-05 [->0060] — **what happened.** why it might matter (pointer: file, item id)
```

`[->NNNN]` means a row now carries this entry's work half; `[->none]` means a pass read the entry and
established that no destination exists yet. It sits at the head so a large buffer partitions with one
`grep` on `\[->`, and after the date so both line shapes above still match — trailing prose was tried
and bought the next sweeper nothing, because partitioning still meant reading every entry to its end.

**The noticer never writes the token.** It means *a sweeper dispositioned this*, and classifying an
entry at the moment of noticing is exactly the friction this buffer exists to avoid. The cheap hint —
the row the parking session was already holding — goes in the `(pointer: …, item NNNN)` clause, which
is not a classification.

**The token does not change what the gate counts.**
`./next --findings` counts every entry, marked or not: a count that fell as markers accumulated
would go quiet precisely when deferred and handed-over entries pile up, which is when the gate's
whole job is to be loud. The old trailing-prose form
stays readable — nothing rewrites an entry it is not processing.

**Emptying this file is `queue`'s and `retro`'s job and their skills carry the rules**: who takes
which entries, what is expired unprocessed, and why a sweeper removes only what it processed. The
normal state of this file is empty, and **if it has grown, that is itself the finding**.

---

- 2026-10-25 — develop 0195 (7871): **`CHANGELOG.md`'s header says every entry is written by `verify` through `./close --note`, yet `queue` writes tickets whose FRs/ACs require the `## Unreleased` note to exist before the close (0195's Documentation NFR, 0216 FR7/AC9).** An AC verify must check before closing cannot be satisfied by a note the close itself writes, so develop wrote the notes and told verify not to pass `--note` — a per-ticket workaround. Either `queue` Step 2 stops writing CHANGELOG ACs (the note is verify's), or the header admits develop-written notes; today the two contradict.
- 2026-10-25 — verify 0195/0216/0110 (9eba/60da/daba): **a dispatch named three tickets from three separate develop gates (7871, 3c97, 844a) as one verify batch, and verify's batch rule ("nothing licenses widening the batch past the membership a develop gate already fixed") has no line for a user-named set that is not a gate.** Handled as three sequential single-ticket passes, one claim, one evidence table and one close each, mutations in a per-ticket worktree. Separately: `.git/` is a sensitive path for Write, so a sweep script cannot live beside a worktree under `.git/`; a repo-root `*.log` (gitignored) worked as the in-directory sweep output file that config.yml asks for.
- 2026-10-25 — develop 0169 (9fa0): **`./close`'s scope report reads each `touches:` entry as a literal path, so a glob entry reports itself as "declared but untouched" and every file it matched as "touched but undeclared"** — 0169 declared `"tests/*.test.sh"` for a change to all 34 suites and the close listed all 34 as undeclared. Neither `develop` Step 1 nor `CONCURRENCY.md` says whether a glob is a valid `touches:` entry (only the exclusive claim's `"*"` is named), and `./next`'s held-file comparison presumably has the same literal reading, so a glob reservation may reserve nothing. Decide: expand globs in `claim`/`next`/`close`, or forbid them in `touches:` and say so. This still needs a row.
- 2026-10-25 — sprint run-20261025T164527Z: **`--drive --scope` filters design rows by the confirmed scope but not develop leads.** After the first gate closed, `--drive` named `develop 0196` (unconfirmed, higher rank) twice, while confirmed rows 0169 and 0046 were still takeable; the first gate had also pulled in unconfirmed 0177 and pushed 0169/0046 out at `gate_max_rows`. The supervisor's only options were to dispatch off-scope or route against `--drive`'s answer, so a person had to pick the gate. Decide whether `--scope` should pick the lead from in-scope rows first and refuse to add off-scope joiners, the way it already does for design.
- 2026-10-25 — sprint run-20261025T164527Z: **Step 5 never says an `outcome` event carries the stage outcome's own fields flat** (the `tickets[]` objects with `verdict`/`next`/`status`, and `findings_parked`), but `tools/sprint-ledger.sh record` reads exactly those. A supervisor that logged ticket ids only and nested the object under `outcome` got a ledger block reading `CLOSED none` and `FINDINGS parked 0` for a run that closed 5 and parked 3, with exit 0 and no warning. It was caught by eye and fixed before commit. Either the skill states the shape, or `record` reds on an outcome event whose tickets carry no verdict.
- 2026-10-25 — design 0172 (dcfa): **`./handoff`'s scope note named another session's file as "touched but undeclared" by this design pass.** `handoff 0172 dcfa develop` reported `.claude/backlog/items/0182-…md`, which only `0bc8cfb Claim 0182 [8e9a]` touched (a concurrent session, landed between this claim and this handoff). The note seems to diff the range since the claim rather than the claimant's own commits, so in a multi-session backlog it blames whoever hands off next. It is labelled "a note, not a gate", but a sprint reading it would widen the wrong ticket's `touches:`. Decide whether it filters to commits carrying the token.
- 2026-10-25 — design 0190 (a309): **`tests/skill-size.test.sh`'s "0035 AC4/FR6" loop, which reds a justification carrying a byte count, silently leaves `skills/sprint/SKILL.md` and `skills/retro/SKILL.md` out of its file list** — so the sprint reason's "~2,100 bytes" was never checked, and a byte count in prose went stale exactly as FR6 predicted. 0190 adds sprint to the loop; retro is still outside it. Separately, once 0190 lands, the other five recorded skill files (develop, queue, prototype, retro, verify) carry argued-at sizes seeded at their build-commit size rather than re-argued: develop is 50,862 bytes and queue 48,538, both well past where 0035 argued them. This needs a row to re-argue those reasons against their current sizes.
- 2026-10-25 — design 0183 (a32e): **`./claim` at `next: design` says "Set [touches:] to what design will write", but the field outlives the stage and `develop` builds against it.** A design pass writes only its own item file, so following the instruction literally leaves the build with a one-path scope; I set it to the build's files instead, and `./handoff` then reported all six as "declared but untouched" by this pass. Decide whether design's `touches:` means the design pass's scope or the build's — they differ on every row. (Also: I declared `.claude/backlog/items/0177-*.md`, a glob, which line 59's literal-path reading will mis-report at close.)
- 2026-10-25 — design 0145 (6e1a): **`./next`'s TAKE loop reads an empty `touches:` on a held row as holding nothing, which is the reverse of `CONCURRENCY.md`'s ownership rule.** `collision_report` compares only against `touches:`, and only `"*"` short-circuits, so a held develop row with an empty field collides with no candidate. The CLAIMED FILES block meanwhile prints "assume held, ask", and `design_conflict` already falls back to `expects:`. 0145 settled the attribution reader (the scope report) and left this ownership reader out of scope. It needs a row deciding whether `collision_report` falls back to a held develop row's `expects:`, the way `design_conflict` does, and what a held design/verify row holds. 0145's answer for those is only their item and row.
- 2026-10-25 — develop 0177 (b472): **`tests/sprint.test.sh` exited non-zero once inside the whole-suite loop and was 368/0 on an immediate rerun.** The loop captured no FAIL line for it (the only `FAIL` text was a case *name*, `a FAIL line survives…`), so the cause is unknown: a concurrent session's transient state or a real flake. Worth a row if it recurs; record the exit status and the tail next time.
- 2026-10-25 — develop 0183 (2672): **88 of the 97 items at `next: develop` or `next: verify` carry the pre-0107 NFR table with no *How it would red* column**, so `tests/item-nfr-red.test.sh` can read nothing in them and only counts them. 0107 added the column to the template and nobody back-filled the open items. Each of those rows is, by the template's own words, "not a commitment" until it names how it would red. This needs a row to decide whether open items get back-filled (a queue sweep) or the guard reds on a missing column. It also asks whether the 67 `next: develop` rows are still live at all: many are from August.
- 2026-10-25 — develop gate (0182, 04e8): **0182's AC7 allowlist contradicts its FR2.** The scripts must name `.claude/backlog` to recognise the legacy location, and AC7 permits that string only in `migrate`. Handed to `queue` with proposed AC7 text in the item's notes. The design pass wrote both and did not cross-check them. Worth a check in `design`'s criteria accounting: does any AC's allowlist forbid what an FR requires?
- 2026-10-25 — **A note appended below the last AC is hashed into that AC's digest.** queue re-specify of 0182: develop's stop note sat after AC10 in `## Acceptance criteria`, so `./next --drift` reported AC10 changed though its text was untouched; moving the note to *Notes & decisions* restored `d0d0b2b8`. Either `--ac-digest` should end an AC at a non-`- [ ]` bullet, or develop's re-entry guidance should say where a stop note goes. **Recurred 2026-10-26** on the same ticket: the 7bff build note landed after AC10 again, a day after the first move (fixed by e50b7c4) — the guidance gap reproduces, so prose alone is not holding it.
- 2026-10-26 — `touches: "*"` written as an inline scalar is read by `next`'s `fm_list` as NO scope (`none declared`), so an exclusive claim silently collides with nothing; only the list form `touches:\n  - "*"` registers. `claim` and CONCURRENCY.md never say which form, and a session reaching for the documented `"*"` writes the inline one (develop 0182).
- 2026-10-26 — verify 0182 (1166): **the harness's protected-path list includes `.git`, so a scratch file written under `.git/` is refused as a "sensitive file", exactly as under `.claude/`.** A pass staging its QA evidence in `.git/vfy-*.md`, to keep it out of `git status`, was refused. A `python3` append straight into the item landed. 0182's design note lists `.git` in the same list, but no skill says a scratch path must avoid both, and `.git/` is the obvious "invisible to status" place to reach for.
