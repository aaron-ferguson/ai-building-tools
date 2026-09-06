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

- 2026-09-05 — **`queue` Step 0's byte-comparison drift check reports a false positive on `item.md` every time.** The step says to check "every executable in this skill's `templates/`, plus `item.md`" against the backlog's copies, but `item.md` is consumed at write time and has no installed copy — there is no `.claude/backlog/item.md` for any project — so a literal `diff` of the named file list reports DIFFERS on it in every backlog, forever. The four executables compared cleanly here; only `item.md` was noise. Either the step names `item.md` as compared against the *last-written item's* shape, or it says outright that `item.md` has no installed counterpart and is excluded from the byte comparison (pointer: `skills/queue/SKILL.md` Step 0, "Compare the bytes, not a version string").
- 2026-09-06 — **The mutation-sweep rule enumerates decision sites, and a decision's *content* is computed one layer below them.** `develop`/`verify` and `testing-conventions.md` now say to build the list from "every call site of the function that decides" plus every NOTE-and-continue. On 0038 that rule was followed exactly and still missed all thirteen branches of `takeable_develop`, `gate_from` and `depth_stopper` — the helpers that produce `--drive`'s DEPTH line, which is AC29's entire subject. Eight were free to delete with the suite green, including one that let AC29's own fixture pass because it asserted the stopper's **id** while the deleted arm changed only its **reason**. The general form that would have caught them is about output, not control flow: *every branch whose deletion can change any character the mode prints is a site, whether or not it decides anything* — enumerate backwards from the printed line rather than outwards from the ladder (pointer: `testing-conventions.md` line 16, item 0038 *Re-entry 2026-09-06 (third)*).
- 2026-09-06 — **A mutation-sweep driver that asserts before it restores poisons the next run's baseline, and only the control mutation catches it.** A driver that validated the mutation site before the restore step left a mutation in the working tree when that validation failed mid-run; the next run copied the mutated file as its baseline, and every reading after that was measured against the wrong file. It surfaced only because the no-op control diffed clean and reported "mutation did not land". Two additions to the sweep rule: restore in a `finally` rather than on the happy path, and the control's job includes catching a **baseline that already contains a mutation**, not only an unstable harness — which the conventions currently do not say (pointer: `testing-conventions.md` line 16, "Run one no-op mutation as a control").
