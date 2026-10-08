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
- 2026-10-06 — **In a driven retro, `Monitor` refused both forms of a wait on a background suite run** ("brace with quote character", then "quoted text can't be checked") before any path question arose, and this harness blocks a foreground `sleep`, so the bounded `for …; sleep 10` poll the retro just wrote into `verify` Step 3 may itself be refused; a bounded python `time.sleep` loop in one foreground Bash call worked. The wait recipe wants a form tested under `claude -p` (retro run-20261004T232135Z tail; skills/verify/SKILL.md Step 3).
- 2026-10-07 — **`CHANGELOG.md`'s preamble is false on its first version section**: it says "Each version ends with `### Did not change`, written by the release session", and `## 0.9.37` (633c4e3) has none, because `tools/release --bump` does not refuse a behaviour-changing bump without one — the line is left to a release session's memory, the prose-over-enforcement shape `CONVENTIONS_CORE.md` names. 0191 passed only on its QA plan's fallback (two entries happen to say what stayed the same). Either `tools/release` refuses a bump with entries but no `### Did not change` under `## Unreleased`, or the preamble stops promising it; also, 0191's QA plan attributes the line to `--no-behaviour-change`, which per `tools/release:66-70` writes a different line (verify abe1 of 0191; tools/release, CHANGELOG.md).
- 2026-10-08 — **Scaffolding a fresh backlog leaves `./close` unusable: `skills/queue/templates/` has no `DONE.md`**, yet SKILL.md Step 0 says to scaffold "by copying every template above" and lists DONE.md in the storage layout and among the project-owned files seeded at scaffold. `close` exits "no DONE.md … nowhere to move the row to" and needs a table header with an `ID` cell; the capturing session had to invent one (columns read from `close`'s awk: ID, Title, Type, QA, Closed). (pointer: skills/queue/templates/, skills/queue/SKILL.md Step 0, templates/close)
- 2026-10-08 — **`harvest-usage.sh` has no rate for `claude-opus-5-5`, so `sprint-ledger.sh record` wrote every USD and token actual as `unpriced`** and the develop gate's observed cost as USD 0.00 against a predicted 0.00. The first sprint on quantum-catan therefore scored its estimate (USD 7.66) against nothing. The RATES line lists an `opus 5` rate, but the resolved id `claude-opus-5-5` matched no entry (154 unpriced turns), and a 0.00 observed figure reads as data rather than a gap. Either map the id or make `record` refuse to print a priced 0.00 beside `unpriced` (sprint run-20261008T021734Z; tools/harvest-usage.sh, tools/sprint-ledger.sh).
- 2026-10-08 — **The sprint Step 1 probe, as written at `--max-budget-usd 0.25`, returned `Error: Exceeded USD budget (0.25)`** on a fresh project with no setting change; at 1.00 it returned the object. This is the startup-floor failure the skill warns about for USD 0.05, now at the figure the skill itself prescribes for the probe (sprint run-20261008T021734Z; skills/sprint/SKILL.md Step 1).
- 2026-10-08 — **The sprint skill's cost model says the supervisor's per-turn floor is "roughly 20k tokens, fixed"; `harvest-usage.sh --run` measured 76,019** on quantum-catan (growth 8,116/cycle, 7.0 turns/cycle against the budget of 3). Its CLAUDE.md, the imported CONVENTIONS_CORE.md and the MCP/skill listings put the floor near 4× the stated figure, so the "three turns per cycle" arithmetic undercounts every turn. Either re-derive the floor from harvests, or say it is per-host (sprint run-20261008T023251Z; skills/sprint/SKILL.md, "What this costs").
