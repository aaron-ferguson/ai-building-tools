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
| 0085 | Collapse the backlog protocol from a third of every session's turns to one command per stage boundary | verify | ready |  |
| 0081 | Give the hand-off a script, as claim and close have | develop | in-progress |  |
| 0086 | Settle the qa_level vocabulary once — a light tier, and a level a repo with no runner can run | develop | ready |  |
| 0078 | Route a finding by what it is about, not which repo you are standing in | develop | ready |  |
| 0084 | Script the release chain and verify it against the installed bytes | verify | in-progress |  |
| 0075 | Anchor a tool edit to the remote, at its start and at its bump | develop | ready |  |
| 0076 | Make a tool edit run the target repo's suite before it commits | develop | ready |  |
| 0077 | Guard the backlog scripts against a broken embedded awk program | develop | ready |  |
| 0082 | Make claim fail safe on the two paths where it currently fails open | develop | ready |  |
| 0080 | Let a findings entry's lesson half be removed independently of its work half | design | ready |  |
| 0083 | Decide what a second checkout may do with the backlog | design | ready |  |
| 0038 | Add the drive and findings routing modes to next | develop | ready | 0036 |
| 0039 | Build the orchestrate skill and the stage outcome schema | develop | blocked | 0036 |
| 0040 | Harden the supervised loop against a held lock and a budget-killed stage | develop | blocked | 0036 |
| 0041 | Write release notes for what a work session delivered | design | ready |  |
| 0052 | Require an acceptance criterion to name the input that would make it red | verify | ready |  |
| 0046 | Make the README guard list provably complete | develop | ready |  |
| 0047 | Give the busy-lock procedure a close-time path | develop | ready |  |
| 0045 | Cross the take loop against the held file set in next | verify | ready |  |
| 0060 | Decide how the findings buffer is emptied and gated | design | ready |  |
| 0054 | Give develop and verify a rule for a result taken over a shared dirty tree | develop | ready |  |
| 0065 | Name stream editors in the rule against rewriting QUEUE.md | develop | ready |  |
| 0050 | Decide how file scope works when the prose files are the product | design | ready |  |
| 0055 | Fill the develop steps that have no case for what now happens routinely | develop | ready |  |
| 0058 | Give verify the outcomes its steps assume can never happen | develop | ready |  |
| 0056 | Give design a non-UI reading list and complete its write step | develop | ready |  |
| 0059 | Decide what the batching rule actually licenses | design | ready |  |
| 0064 | Make a stage skill say which copy of it is running | develop | ready |  |
| 0062 | Let a ticket's contract express a removal and cover its own prose | develop | ready |  |
| 0048 | Decide which remaining backlog write sites become scripts | design | ready |  |
| 0057 | Add the queue operations that exist in practice and not in the skill | develop | ready |  |
| 0049 | Decide what a claim token guarantees and what enforces it | design | ready |  |
| 0061 | Decide how a session learns the installed plugin differs from this repo | design | ready |  |
| 0066 | Fix the three places the backlog scripts answer the wrong question | develop | ready |  |
| 0063 | Give the prose guards a matcher that survives a rewrap | develop | ready |  |
| 0067 | Decide what shape a cross-cutting rename takes in the backlog | design | ready |  |
| 0043 | Make the two size gates fail on a registry entry that no longer resolves | develop | ready |  |
| 0007 | Replace the Owner column with claim directories | develop | ready | 0002 |
| 0006 | Rewrite next to parse by header name and walk ancestors | develop | blocked | 0002 |
| 0008 | Add the graph rules to queue, develop, and verify | develop | blocked | 0002 |
| 0003 | Phase 2 — the readiness gate and outcome reviews | develop | blocked | 0001 |
| 0004 | Phase 3 — extend tracker mirroring with hierarchy and standards | develop | blocked | 0001 |
| 0069 | Add a live domain-model and decision-record discipline to design and develop | design | ready |  |
| 0070 | Add a structured, feedback-loop-first debugging discipline | design | ready |  |
| 0071 | Add a decision-map mode for work too large or too foggy for one project ticket | design | ready |  |
| 0072 | Archive an escalated prototype on its own branch instead of leaving it only in the working tree | develop | ready |  |

**Read this file with `./next <stage>`, not by eye** — it applies the takeability rules and reads
the graph rather than this cache. Everything that *writes* it is governed by `CONCURRENCY.md` in
the `ai-building-tools` plugin (`references/CONCURRENCY.md` at its root).
