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

**Emptying this file is `queue`'s and `retro`'s job and their skills carry the rules**: who takes
which entries, what is expired unprocessed, and why a sweeper removes only what it processed. The
normal state of this file is empty, and **if it has grown, that is itself the finding**.

---

- 2026-08-24 — **a third size gate would trip the DRY trigger that 0028 correctly declined.**
  `tests/reference-size.test.sh` is the second copy of the `offenders`/`pad`/`ok`/`bad` shape;
  `coding-conventions.md`'s Tier-2 rule fires on the *third* instance, so 0028's *Out of scope*
  ruling ("duplicating ~40 lines of `sh` is acceptable here") is right today and expires the moment
  a third prose directory earns a goal. The two copies have already diverged in one way worth
  keeping — the reference gate carries an AC7 grep the skill gate has no equivalent of — so the
  extraction is not a pure lift (pointer: tests/skill-size.test.sh, tests/reference-size.test.sh,
  items/0028).
- 2026-08-24 — **`references/TRACKER.md` is 6,022 bytes, 35 bytes under the 6,057 goal.** The next
  sentence added to it reds the new gate under whatever unrelated ticket happens to be editing it,
  with no reason recorded and the author mid-way through something else. The gate doing its job, not
  a defect — but it means a third reference file is about to need either a relocation or a recorded
  reason, and better to decide that deliberately than at a red (pointer: references/TRACKER.md,
  tests/reference-size.test.sh, items/0028).
- 2026-08-25 — **`develop` Step 5.4 says to clear the claim and take the lock, but the lock helper
  pattern in the docs releases on shell exit — and every Bash call is a new shell.** Routing 0036,
  `mkdir .lock` + `trap 'rm -rf' EXIT` in one tool call released the lock the instant that call
  returned, so the read, the write and the commit spanned three unlocked windows rather than one held
  one. `CONCURRENCY.md` says "hold it for the read, the write and the commit, then release in the same
  turn" and `./claim` gets this right by being a single process; a session doing it by hand cannot,
  unless the whole sequence is one command. Rule to draw: **a by-hand lock must be one tool call from
  `mkdir` to `git commit`, or it is not a lock** — which is a fourth silent leak to add to the three
  `CONCURRENCY-INCIDENTS.md` already lists (pointer: references/CONCURRENCY.md *Lock every write*,
  skills/develop Step 5.4).

- 2026-08-25 — **a parked finding's factual claims decay while it waits, and `queue` Step 5 has no
  re-verification step — it says specify the entry, not check it.** Two of twelve in this batch had
  moved by the time they were swept, in opposite directions. The prose-wrapping entry offered two
  candidate fixes, "a helper that unwraps" or "a stated rule that guarded sentences are not
  rewrapped"; the rule *looked* landed because this repo's `CLAUDE.md` carries it, and a grep showed
  `testing-conventions.md` contains no rewrap rule at all and no suite has an unwrapping helper — so
  the whole defence was one project's own documentation, and both candidates were still open. The
  `/verify`-collides-with-a-built-in entry went the other way: its named instance could not be
  confirmed from inside the session, while the identical collision was live on `design`, which
  nothing had reported. Both tickets came out different for the check — 0063 kept both candidates,
  0064 was written against the class and explicitly does not rest on the reported instance. Nothing
  asked for either check. The sharp version: an entry states a fact about the tree, the tree moves,
  and a sweep that specifies faithfully ships a ticket built on a stale premise — which reads
  exactly like a well-specified one (pointer: skills/queue/SKILL.md Step 5, items/0063, items/0064).

- 2026-08-25 — **a claim released in the working tree but not committed reads as neither held nor
  free, and no mode reports it.** `0037`'s row says `in-progress` in the committed `QUEUE.md` while
  its item file, dirty and uncommitted, has `claimed_by:` cleared and `status: waiting`.
  `CONCURRENCY.md`'s *A stage writes only the ticket it holds* defines held as "a non-empty
  `claimed_by:` in the item, and nothing else", so the item reads free; the row reads taken;
  `./next develop` printed `0037 [no token] none declared — assume held, ask`; and `./next --drift`
  said "no drift" because it only compares the Status column against `blocked_by`. The rule that
  makes a claim durable is stated for the *claim* and not for the *release*, so a release is
  invisible in exactly the same way a claim would be (pointer: references/CONCURRENCY.md, items/0049,
  items/0066).
- 2026-08-25 — **checking "the output is unchanged" needs the HEAD copy of a suite run from inside
  the repo, and nothing says so.** 0053's AC1 is a byte-comparison against today's output, so the
  obvious move is `git show HEAD:tests/x.test.sh > $SCRATCH/x.sh && sh $SCRATCH/x.sh`. Every suite
  resolves `ROOT` from its own location, so the scratch copy exits 2 with "no claim script at
  …/scratchpad/skills/…" — which is not a red, just a different error, and a session in a hurry
  reads it as one. The copy has to land inside the repo tree (`tests/.head-x.sh`, dot-prefixed so
  the `tests/*.test.sh` loop does not pick it up) and be removed in the same turn. Third session in
  a row to hand-build throwaway comparison scaffolding, which is the finding 0053 itself came from
  (pointer: skills/develop/SKILL.md Step 5, items/0053).
