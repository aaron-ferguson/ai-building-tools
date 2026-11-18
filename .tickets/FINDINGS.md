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

- 2026-11-06 — **prototype's level-3 stop has no correct answer when the base product is the repo the skill runs in.** AetherWorks 0027 required real-component fidelity on `src/ui/screens/HowToPlay.tsx`; with no `prototype:` block the config table says stop, though nothing would be invented (ticket pins the file, stack is the repo's). Proceeded on a throwaway branch instead; the skill could say "a ticket-pinned path in the current repo stands in for `prototype.root`". (pointer: skills/prototype/SKILL.md Configuration table + Step 5 path rule; AetherWorks item 0027)

- 2026-11-09 — **`./claim` commits onto whatever branch is checked out, with no check that it is the shared branch.** A design pass on AetherWorks 0136 began on a `prototype/` branch one commit ahead of `main`, and the claim, the decision and the hand-off all landed there. On `main` the row still reads unclaimed at `next: design`, so a second session working from `main` could claim it, and the claim protocol's single-holder guarantee does not reach across branches. CONCURRENCY.md refuses a linked worktree (*A second checkout never writes the backlog*) but says nothing about a non-default branch in the primary checkout. Candidate: `claim`, `handoff` and `close` refuse, or at least warn, off the branch the backlog is shared on. (pointer: references/CONCURRENCY.md, the five scripts; AetherWorks item 0136)

- 2026-11-15 — **design Step 4 has no correct answer when the design ticket's own FRs require amending sibling items.** A consuming project's design ticket (queue-authored) carried "FR4 — amend items B and C to match, restamp their `ac_digest` in the same commit as the decision". CONCURRENCY.md *A stage writes only the ticket it holds* forbids it, and `./claim` cannot take B or C (both `blocked`). Handing B/C's edits back to `queue` costs the round trip the skill exists to avoid, and leaves the decision and its consequences in different commits. Proceeded by writing B and C under the backlog lock after confirming both had empty `claimed_by:` (the *unheld* test the retro section uses), in one commit with the decision. Candidate: either name this as a second narrow exception (unheld, non-done dependents named in the item's own FRs), or have `queue` stop writing such FRs. Also: Step 4 says hand off to `develop`, but a decision-only ticket (`qa_level: verify`, nothing to build) was handed to `verify` instead — the skill could say so. (pointer: skills/design/SKILL.md Step 4; references/CONCURRENCY.md *A stage writes only the ticket it holds*)
- 2026-11-16 — **queue has no path for sending an open `next: verify` ticket back to `design` when the user reopens one of its decisions.** Step 1 covers re-specify (`next: queue`) and `./reopen` (done → verify only); a consuming project needed verify → design for a design ticket whose answer the user overturned before close, so the `next:` field and the QUEUE row were edited by hand under the lock. Either name the operation in Step 1 or let `./handoff`/a script do it unclaimed. (pointer: skills/queue/SKILL.md Step 1; templates/reopen)

- 2026-11-17 — **queue cannot satisfy `qa_level: review` within its own commit boundary.** Filing three decision tickets at `review` in a consuming project with no `review: checklist:` configured, the level would be refused downstream; the config template's example path is `docs/review-checklist.md`, but queue Step 6 restricts every committed path to `.tickets/`. Proceeded by writing the checklist at `.tickets/review-checklist.md`. Candidate: the template example points inside `.tickets/`, or queue Step 2 names this case. (pointer: skills/queue/templates/config.yml `review:` block; skills/queue/SKILL.md Step 6)

- 2026-11-18 — **`references/CONCURRENCY.md`'s claim-token snippet `head -c2 /dev/urandom | xxd -p` fails on this Linux container: `xxd: command not found` (exit 127).** Same class as 0232 (a macOS-assumed tool in a prescribed shell form); `od -An -N2 -tx1 /dev/urandom | tr -d ' \n'` worked. Noticed by `queue` minting 0232/0233; not filed — held for confirmation per `retro` Step 4.
