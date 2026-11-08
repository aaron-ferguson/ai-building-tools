# Backlog — ai-building-tools

**Stack ranked: line order is the rank**, and reprioritising means moving the line. There is no
priority column — a priority and a position can disagree, and then neither is authoritative — and
no position number (`CONCURRENCY.md`, *Never rewrite `QUEUE.md` by hand*). Do not add either.

**Two columns, because they answer different questions.** `Next` is the *stage* — which skill acts
on the row. `Status` is the *state* — whether anything can act at all. Merged into one column a
reader cannot filter for "work I can start" without already knowing which values are which. Both
vocabularies are defined once, in the `next:` and `status:` comments of an item's frontmatter
(`templates/item.md`), and are **not restated here**: a restated rule is a rule that drifts, and
this file has drifted from that one before. `blocked` is derived from `blocked_by` and never
authored — this column only caches it, `./next --drift` reports where cache and graph disagree,
and the graph wins.

**Only tasks appear here.** A ticket with children is a *project*: never ranked, claimed or built,
and its row leaves this file the moment it gains one (`templates/item.md`, `parent:`). Completed
tickets move to `DONE.md`; dormant scheduled ones live in `SCHEDULED.md`.

The columns are `ID`, `Title`, `Next`, `Status` and `Parent`, and there are no more: **the `ID`
resolves to `items/<id>-*.md` by glob**, and ownership is not a column (`CONCURRENCY.md`,
*Claim tokens*).

| ID | Title | Next | Status | Parent |
|------|-------|------|--------|--------|
| 0228 | Name the backlog directory .tickets/, since it holds the whole ticket system | develop | in-progress |  |
| 0064 | Make a stage skill say which copy of it is running | develop | ready |  |
| 0066 | Fix the three places the backlog scripts answer the wrong question | develop | ready |  |
| 0215 | Make claim and next read expects and touches through one parser that refuses or accepts the comma form | develop | ready |  |
| 0225 | Make claim write an empty touches key when it has nothing to seed | develop | ready |  |
| 0227 | Make next list the findings entries so no drain matches a buffer's header by hand | develop | ready |  |
| 0214 | Add a profile-declared gate that a stage refuses to pass without its artifact | design | ready |  |
| 0069 | Add a live domain-model and decision-record discipline to design and develop | design | ready |  |
| 0070 | Add a structured, feedback-loop-first debugging discipline | design | ready |  |
| 0071 | Add a decision-map mode for work too large or too foggy for one project ticket | design | ready |  |
| 0138 | Decide whether idea capture is a lighter-weight skill than queue's Add, and what triggers it | design | ready |  |
| 0118 | Run the privacy guard where a sweep commits, not only where a suite runs | develop | ready |  |
| 0164 | Record active and elapsed time and interruptions in the sprint ledger, and estimate them | develop | ready |  |
| 0170 | Stop the marker heartbeat leaving an orphaned sleep child | develop | ready |  |
| 0137 | Decide whether two develop sessions may run at once, and in what isolation | design | ready | 0128 |
| 0149 | Audit sprint efficiency — suite-check dedup, per-agent overhead, and model tiering | design | ready | 0128 |
| 0155 | Make claim and next agree on what blocks a take | develop | ready |  |
| 0156 | Let handoff record a blocker without leaving drift that stops a driver | develop | ready |  |
| 0157 | Make release verify compare the install against the released commit | develop | ready |  |
| 0192 | Stop an unpriced session reading as free in the sprint ledger and the harvest | verify | ready |  |
| 0204 | Route a queue completion that re-specifies a waiting row to develop instead of exiting 4 | queue | ready |  |
| 0226 | Decide whether --drive steps over an out-of-scope waiting or queue row, and which exit wins | design | ready |  |
| 0208 | Make the prototype template's render keep focus and play enter animations once | queue | ready |  |
| 0212 | Stop --drive dispatching develop beside a design session holding one of its files | develop | ready |  |
| 0217 | Stop a note written below the last AC from changing that AC's digest | queue | ready |  |
| 0219 | Make reopen leave a ticket that verify can close when it reopens a develop self-close | queue | ready |  |
| 0220 | Make --drive name one verify session for rows developed together in one gate | queue | ready |  |

**Read this file with `./next <stage>`, not by eye** — it applies the takeability rules and reads
the graph rather than this cache. Everything that *writes* it is governed by `CONCURRENCY.md` in
the `ai-building-tools` plugin (`references/CONCURRENCY.md` at its root).
