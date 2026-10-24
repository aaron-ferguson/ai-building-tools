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

- 2026-10-18 — **`./claim` and `./next` read only a YAML-array or block-list `expects:`, and silently treat a bare comma list (`expects: a.ts, b.ts`) as no prediction.** In one consumer backlog, an item written that way was offered as "EXPECTS not predicted", and `./claim` reported "declares no expects:" and left `touches:` unset. Several of that backlog's items use the comma form, so file-scope triage is blind for all of them. Either the parsers accept it, or `queue`/the item template refuses to write it (`claim`'s `expects:` awk, `next`'s EXPECTS line).
- 2026-10-17 — **`develop` resolved a contradiction inside an item's own contract and recorded it as a "deliberate asymmetry", instead of routing the item to `design`.** In one consumer backlog, an item's Problem section called a behaviour correct that its AC5/FR5 forbid: a palm ignored during one gesture kind may let the next gesture start before it lifts. The build notes saw the conflict, built half to each side, and sent the item to `verify`, which can only fail it and send it to `design`. That cost a whole verify session. `develop` Step 2 has no explicit "the item disagrees with itself → hand to design" exit. It should have one, at the same weight as `verify`'s *"the ticket owes a decision rather than a choice"*.
- 2026-10-18 — **`sprint-ledger.sh record` counts an account session-limit pause as sprint wall-clock.** In one consumer's run-20261018T011502Z, a verify stage stopped on "You've hit your session limit", and the run logged `limit_hit` at 02:09Z and `resumed` about 12h later. The ledger then recorded `wall_clock_min` 901 against an estimate of 147, from first and last event timestamps. Working time was roughly 170 minutes. That actual is now the prior for the next estimate, which will be inflated about 5x. `record` should subtract each `limit_hit`→`resumed` window (and `stage_killed`→`resumed`) from wall-clock, or report it beside the actual (pointer: tools/sprint-ledger.sh wall-clock derivation; skills/sprint Step 7).
- 2026-10-18 — **`develop` Step 5's mutation advice says "commit, then break it" but never "confirm the break applied", and a mutation that silently does not apply reads as a guard that holds.** In one consumer session, seven BSD-`sed` mutations (patterns using `\&\&` and `\[`) matched nothing, every run came back with zero failures, and the table would have recorded seven mutations "survived" — or, read the other way, seven guards that bite — from runs of unmodified code. It surfaced only because a zero-red result for a mutation that deletes the rule under test was implausible. A string-replacement script that asserts `count(old) == 1` before each run, restores in a `finally`, and captures stderr with stdout (vitest prints its `FAIL` lines there) fixed it. Worth one clause in Step 5: a mutation run is evidence only once the diff it ran against is shown non-empty.
- 2026-10-18 — **An item's `qa_level:` accepts any word: one consumer item carried `qa_level: verify` (a stage name, not a level) from capture through to `develop`, and `./next develop` printed it as `qa verify` without complaint.** Nothing downstream can run "verify" as a level, so the QA session meets it with no instruction. `develop` may only raise the level, and a non-level has no order to raise from, so the session left it and noted it. A `./next --drift`-style check that `qa_level` is one of the declared levels would catch it at capture.
- 2026-10-18 — **No script returns an answered `waiting` row to `ready`, and `/design` Step 1 has no path for one.** In one consumer's sprint, a design session was dispatched on a `next: design, status: waiting` row whose question the author had just answered in the supervising session; `./claim` refused it (`is 'waiting', not ready`) and the session had to hand-edit `status:` in both QUEUE.md and the item under a by-hand lock, commit, then claim — the by-hand multi-file composition CONCURRENCY.md warns leaks. Either `./claim` should accept a `waiting` row when told the answer has arrived (e.g. `--answered`), deleting `## Waiting on` in the same commit, or `/sprint` should flip the row before dispatching a stage onto it.
- 2026-10-18 — **`./claim` and `./next` read only a bracketed `expects:` list; a comma-separated one is treated as absent.** AetherWorks 0113 carried `expects: src/ui/panels/LinkPanel.tsx, src/ui/theme.css, …` (four real paths, written by `queue`/`design`), and `./next develop` printed `EXPECTS not predicted` while `./claim` said "0113 declares no expects:" and left `touches:` unset. Sibling items 0104 and 0105 use the same bare form, so the triage file-scope comparison is silently blind to every one of them. Either the readers accept the bare form, or the writers (and a `--drift`-style check) refuse it — the failure is quiet in the permissive direction.
- 2026-10-19 — **`queue` Step 0 scaffolds a `DONE.md` that no template provides.** The storage layout lists `DONE.md` and `close` refuses without one ("no DONE.md … nowhere to move the row to"), but `skills/queue/templates/` has no `DONE.md`. So a fresh scaffold has to invent its header and table shape, and `close`/`next` then parse whatever was invented. Add a template and copy it in Step 0. (pointer: skills/queue/templates/, close line 88)
- 2026-10-18 — **A verify send-back's *Constraint for develop* tripped a different AC of the same ticket.** AetherWorks 0110 round 1 asked for AC1 spans "on opposite sides of the old gate"; develop explained it in a test comment naming "the retired relay's `MIN_SPAN * 2` gate", which broke AC2's tree-wide `grep -ri relay` contract. A send-back could name which other ACs' mechanical checks the rework must keep green when one is a tree-wide search. One occurrence so far. (pointer: skills/verify, AetherWorks item 0110; forwarded by AetherWorks retro)
- 2026-10-18 — **`next`/`claim`'s `fm_list` parses `expects:` only as `[a, b]` or a `- a` block, so a bare `expects: a.ts, b.ts` reads as empty, silently.** AetherWorks 0104's design hand-off wrote the comma form: `./next develop` printed "not predicted — check this one by hand", the held-file comparison ran against nothing, and `./claim` refused to seed `touches:`. Fails open. Either the parser accepts the comma form or a writer-side check rejects it; at least three other AetherWorks items carry it. (pointer: `fm_list` in skills/queue/templates/next, close and reopen; AetherWorks item 0104; forwarded by AetherWorks retro)
- 2026-10-18 — **sprint SKILL.md's tail-cap snippet passes the whole `./next --findings` line to `--findings`.** `findings="$(./next --findings | head -1)"` yields `FINDINGS  15 entries; …`, and `sprint-ledger.sh tail-cap` dies with `ValueError: invalid literal for int()`; the supervisor had to extract 15 by hand (AetherWorks run-20261018T191111Z). Parse the count, or have `tail-cap` read it (skills/sprint/SKILL.md, Step 6 "Scale the tail caps").
- 2026-10-24 — **`./next`'s `fm_list` drops a comma-separated `expects:` silently**, so the collision check fails open. `fm_list` accepts only the inline `["…"]` list or a `- ` block. A bare `expects: a.ts, b.ts` (the form `templates/item.md`'s `expects:` comment does not rule out, unlike `blocked_by:`'s ONE-form note) reads as empty: `./next develop` prints `EXPECTS not predicted`, and `collision_report` compares nothing, so two windows can land in one file. In AetherWorks, 11 open items use the scalar form (0109, 0117, …). Fix candidates: give `expects:`/`touches:` the same ONE-form note, and have `fm_list` either parse the scalar or have `--drift` report it. (pointer: skills/queue/templates/next `fm_list`, templates/item.md `expects:`; AetherWorks 8b8da81)
