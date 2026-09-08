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

- 2026-09-07 — **`retro` has no answer for a workspace holding several backlogs, and picked one by
  judgement.** Invoked from `/Documents/AI`, which is not a repo and has no backlog, with four
  beneath it: this repo (22 entries, 2.75x threshold), `ai-building-conventions` (3), `Probation`
  (4, all invalidated) and `jury-config` (0). Step 1 says "`.claude/backlog/FINDINGS.md` is the
  input, and the only one" — singular, and there is no resolution order for the plural case, no
  equivalent of `CONVENTIONS.md`'s numbered ladder, and nothing saying whether a cadence retro
  sweeps one buffer or all of them. Swept all four on freshness and threshold, which was defensible
  and was invention. Note the interaction with `findings_threshold`: it is per-project, so four
  buffers each at 6 entries never trips a gate while the workspace holds 24 unswept findings
  (pointer: `skills/retro/SKILL.md` Step 1, `references/CONVENTIONS.md`'s resolution order as the
  shape this lacks).
- 2026-09-07 — **The line-wrap hazard bites the author, not only the guard, and it did so on the
  edit that landed the rule about it.** Minutes after landing *"count on flattened text: a
  line-based count returns one for a phrase that wraps across a line break"* in
  `testing-conventions.md`, an anchored edit to `skills/develop/SKILL.md` failed because the anchor
  `Same discipline the backlog already applies` is stored as `Same\ndiscipline …` — `str.find`
  returned -1 and the assertion fired. This repo's `CLAUDE.md` records the hazard for *grep in a
  guard*; nothing records it for *anchored editing of these files*, which is how every prose change
  here is made. An anchor must be chosen from within one source line, the same discipline as an
  assertion, and the failure is at least loud where a guard's is silent (pointer:
  `CLAUDE.md` "rewrapping a guarded paragraph is a breaking change", `skills/retro/SKILL.md` Step 4).
- 2026-09-07 — **`retro` Step 5's release chain and one-line report assume the pass edited one
  repo.** This pass edited three — this repo (skills, references, tests, backlog),
  `ai-building-conventions` (`testing-conventions.md`, root `FINDINGS.md`) and `Probation` (buffer
  only). Step 5 says commit each in its own repo, which is clear; the *release* half is not, because
  `tools/release` exists here and nowhere else, and the prescribed one-line report
  (`Skills changed — ran tools/release, restart required.`) has no form for "released one of three,
  pushed the other two, third needs nothing". Reported it in full instead (pointer:
  `skills/retro/SKILL.md` Step 5 and Step 7).
