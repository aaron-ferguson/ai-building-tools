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
| 0075 | Anchor a tool edit to the remote, at its start and at its bump | verify | ready |  |
| 0077 | Guard the backlog scripts against a broken embedded awk program | develop | ready |  |
| 0106 | Make touches mean one thing across claim, close and a transient mutation | develop | ready |  |
| 0115 | Make --drift see a row and its item disagreeing, as three files say it does | develop | ready |  |
| 0090 | Close the four contract gaps 0081 and 0082 left in claim, close and handoff | develop | ready |  |
| 0136 | Stop two gates sharing a file through a row neither lead names | develop | ready |  |
| 0131 | Dispatch no new develop gate while a started ticket is still awaiting verify | develop | ready | 0128 |
| 0130 | Propose a sprint scope and dispatch nothing until a person confirms it | develop | ready | 0128 |
| 0129 | Rename orchestrate to sprint and leave the old command resolving | develop | blocked | 0128 |
| 0132 | Let verify batch within a gate that was developed together, with per-ticket evidence | develop | blocked | 0128 |
| 0133 | Close a sprint with a retro and a queue sweep only when the findings earn it | develop | blocked | 0128 |
| 0135 | Record what a sprint was estimated to cost against what it did, and estimate from that | develop | ready | 0128 |
| 0134 | Dispatch a sprint's design sessions alongside develop instead of stopping for them | develop | ready | 0128 |
| 0080 | Let a findings entry's lesson half be removed independently of its work half | design | ready |  |
| 0083 | Decide what a second checkout may do with the backlog | design | ready |  |
| 0110 | Decide the shape of a ticket whose first requirement can kill the rest | design | ready |  |
| 0041 | Write release notes for what a work session delivered | design | ready | 0128 |
| 0052 | Require an acceptance criterion to name the input that would make it red | verify | ready |  |
| 0107 | Require an NFR row to name how it would red | develop | ready |  |
| 0089 | Sweep the guards for assertions that cannot fail | develop | ready |  |
| 0108 | Guard the code conventions this repo's suite does not check | develop | ready |  |
| 0046 | Make the README guard list provably complete | develop | ready |  |
| 0126 | Stop retro restating the by-hand lock rule it drifted from | develop | ready |  |
| 0091 | Make a by-hand backlog write take the lock and prove its commit landed | develop | ready |  |
| 0092 | Prove claim and close hold the lock through their commit | develop | ready |  |
| 0047 | Give the busy-lock procedure a close-time path | develop | ready |  |
| 0045 | Cross the take loop against the held file set in next | verify | ready |  |
| 0060 | Decide how the findings buffer is emptied and gated | design | ready |  |
| 0054 | Give develop and verify a rule for a result taken over a shared dirty tree | develop | ready |  |
| 0065 | Name stream editors in the rule against rewriting QUEUE.md | develop | ready |  |
| 0050 | Decide how file scope works when the prose files are the product | design | ready |  |
| 0093 | Give develop and verify a working recipe for a before-and-after suite comparison | develop | ready |  |
| 0094 | Record why a claimed row was put back | develop | ready |  |
| 0055 | Fill the develop steps that have no case for what now happens routinely | develop | ready |  |
| 0058 | Give verify the outcomes its steps assume can never happen | develop | ready |  |
| 0127 | Say that a deferral is licensed by understanding and never by writing | develop | ready |  |
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
| 0112 | Hoist the line-wrap hazard to the session editing prose, not only the one writing a guard | develop | ready |  |
| 0096 | Make the frontmatter path lists checkable to read and safe to edit | develop | ready |  |
| 0095 | Hoist the shell short-circuit hazard where a guard author will read it | develop | ready |  |
| 0067 | Decide what shape a cross-cutting rename takes in the backlog | design | ready |  |
| 0043 | Make the two size gates fail on a registry entry that no longer resolves | develop | ready |  |
| 0007 | Replace the Owner column with claim directories | develop | ready | 0002 |
| 0006 | Rewrite next to parse by header name and walk ancestors | develop | blocked | 0002 |
| 0008 | Add the graph rules to queue, develop, and verify | develop | blocked | 0002 |
| 0003 | Phase 2 — the readiness gate and outcome reviews | develop | blocked | 0001 |
| 0004 | Phase 3 — extend tracker mirroring with hierarchy and standards | develop | blocked | 0001 |
| 0100 | Give the two findings markers a greppable form and count them | develop | ready |  |
| 0101 | Say what a capture session does when only some repos resolve conventions | develop | ready |  |
| 0069 | Add a live domain-model and decision-record discipline to design and develop | design | ready |  |
| 0070 | Add a structured, feedback-loop-first debugging discipline | design | ready |  |
| 0071 | Add a decision-map mode for work too large or too foggy for one project ticket | design | ready |  |
| 0138 | Decide whether idea capture is a lighter-weight skill than queue's Add, and what triggers it | design | ready |  |
| 0072 | Archive an escalated prototype on its own branch instead of leaving it only in the working tree | develop | ready |  |
| 0113 | Give retro's release chain and its one-line report a form for a pass that edited several repos | develop | ready |  |
| 0097 | Record what a transcript cannot say about thinking tokens | develop | ready |  |
| 0103 | Decide whether the backlog scripts may share a sourced file | design | ready |  |
| 0099 | Return RANKING.md to current state only | develop | ready |  |
| 0102 | Decide what happens when the size-gate regime's two deferred triggers fire | design | ready |  |
| 0098 | Disambiguate the FR citations the 0036 split left behind | develop | ready |  |
| 0109 | Give a human-reported source a resolvable form | develop | ready |  |
| 0116 | Give queue Step 0 a resolution order instead of a scaffold instruction | design | ready |  |
| 0117 | Stop the item-ID citation matcher reading file modes and clock times as citations | develop | ready |  |
| 0118 | Run the privacy guard where a sweep commits, not only where a suite runs | develop | ready |  |
| 0119 | Make a collided self-mutating guard exit non-zero instead of silently printing no tally | develop | ready |  |
| 0120 | Decide how a write no ticket can own appears to the file-scope check | design | ready |  |
| 0121 | Make claim write the timestamp CONCURRENCY.md requires in held-by | develop | ready |  |
| 0122 | Decide whether a mention of the privacy rule may name the thing the rule forbids | design | ready |  |
| 0123 | Give queue a rule for withdrawing a criterion, as it has for withdrawing an id | develop | ready |  |
| 0124 | Split the stop-rather-than-guess refusal out of the conventions ladder that instances it | design | ready |  |
| 0125 | Pin the citation enumeration to its decision record so widening one cannot leave the other stale | develop | ready |  |
| 0137 | Decide whether two develop sessions may run at once, and in what isolation | design | ready | 0128 |

**Read this file with `./next <stage>`, not by eye** — it applies the takeability rules and reads
the graph rather than this cache. Everything that *writes* it is governed by `CONCURRENCY.md` in
the `ai-building-tools` plugin (`references/CONCURRENCY.md` at its root).
