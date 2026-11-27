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
| 0245 | Mint the claim token with od, so ./claim works on a host without xxd | verify | ready |  |
| 0243 | Give each slice of an epic its own file, so claims, locks and revisits work per slice | design | ready |  |
| 0244 | Make sprint judge loops and likely loops itself, instead of ending a run on a bounce count | design | ready |  |
| 0192 | Stop an unpriced session reading as free in the sprint ledger and the harvest | verify | ready |  |
| 0240 | Make a sprint's cost measured, estimated and tunable | develop | blocked | 0128 |
| 0064 | Make the copy of a skill that runs provably the released one | develop | ready |  |
| 0246 | Make sprint refuse to start on a stale main or a stale plugin | develop | ready |  |
| 0238 | Make prototype levels 2 and 3 work inside a consuming project | design | ready |  |
| 0214 | Add a profile-declared gate that a stage refuses to pass without its artifact | design | ready |  |
| 0069 | Add a live domain-model and decision-record discipline to design and develop | design | ready |  |
| 0070 | Add a structured, feedback-loop-first debugging discipline | design | ready |  |
| 0138 | Decide whether idea capture is a lighter-weight skill than queue's Add, and what triggers it | design | ready |  |
| 0239 | Codex test | develop | ready |  |

**Read this file with `./next <stage>`, not by eye** — it applies the takeability rules and reads
the graph rather than this cache. Everything that *writes* it is governed by `CONCURRENCY.md` in
the `ai-building-tools` plugin (`references/CONCURRENCY.md` at its root).
