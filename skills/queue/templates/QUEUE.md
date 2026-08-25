# Backlog — <Project>

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
|  |  |  |  |  |

**Read this file with `./next <stage>`, not by eye** — it applies the takeability rules and reads
the graph rather than this cache. Everything that *writes* it is governed by `CONCURRENCY.md` in
the `ai-building-tools` plugin (`references/CONCURRENCY.md` at its root).
