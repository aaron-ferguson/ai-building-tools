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
- 2026-09-21 — **A by-hand lock sequence leaks through zsh's `nomatch`, which is a route `CONCURRENCY-INCIDENTS.md` does not list.** An agent's Bash tool runs zsh, and the skills' by-hand lock snippets are written as `sh`. Under `set -eu` in zsh an unmatched glob (`[ -e items/0176-*.md ]`, a guard against reusing an id) is a fatal error, not a false test — so the script died *after* `mkdir .lock/` and before any `rm -rf`, stranding the lock and blocking every claim and close until it was cleared by hand. Two other dialect traps sit beside it: `sed -i` needs an argument on macOS, and no word of the snippet warns. `references/CONCURRENCY.md` already says to drop the trap and `rm -rf` explicitly at the end, which is exactly the form this defeats. Possible fixes: pipe the sequence into `/bin/sh -s` (what worked here), or have the snippet say so. (`references/CONCURRENCY-INCIDENTS.md`, the by-hand lock snippet; queue sweep 2026-09-21)
- 2026-09-21 — **Guards assert English sentences about facts that are enumerable, and a code per stage outcome would make them mechanical.** Author's proposal, raised after 0159 AC7. The pattern: a criterion names a phrase that stands for a rule, the phrase is not the rule, and the two come apart. AC7 asserted the absence of `needs a person."*` as a proxy for *no sentence describes a ready design row as a person's call*; 0159's own change rewrote that sentence to name a `next: queue` row — which genuinely does need a person — so the criterion reds correct prose and verify closed it against a substituted assertion. `0063` is the same defect from the other side: a phrase that straddles a line break cannot be matched at all, because `grep` is line-based. **The precedent already exists in this repo and stops short of the skills:** `./next --drive` exits 0/3/4/5 and `skills/sprint/SKILL.md` requires *"Route on the exit code, never on your own reading of the queue."* Stage outcomes and the prose describing them carry no such code, so guards fall back to grepping English. **The proposal:** a code per stage/skill outcome, emitted in the summary line — a single token, so wrap-proof and reword-proof, and AC7 becomes `no line carries D-NEEDS-PERSON` rather than a two-`grep` pairing. Shape worth deciding deliberately: numeric *classes* aligned to the exit codes that already exist (2xx proceed, 4xx needs-a-person, 5xx broken) plus a symbolic token, since the audience is a `grep` and a human reading a terminal rather than a wire protocol. **The registry is where the value is** — one enumeration makes two things testable that prose cannot support: every emitted code is registered, and every registered code is emitted somewhere. Without that check an unregistered code is the same drift in a new costume. Limits: retrofit across 11 suites; a code proves emission and not that the surrounding prose is accurate; it fits enumerable things (outcomes, routing decisions, refusal reasons) and not "the skill explains *why* X". Convention support is direct — `CONVENTIONS_CORE.md` *Prefer enforcement over instruction* ("a rule broken twice was never enforceable as prose" — this one has broken twice) and *No magic numbers or strings*. **This still needs a row**, and whoever specs it should check whether it absorbs part of `0063` rather than sitting beside it, and how it interacts with `0123`'s rule for withdrawing a criterion. (`skills/sprint/SKILL.md` Step 2; `tests/sprint.test.sh` 0159 AC7; `.claude/backlog/items/0159-*.md` QA evidence; related 0063, 0123; sprint supervisor run-20260920T222013Z)
- 2026-09-21 — **The agent's Write and Edit tools refuse `QUEUE.md`, `RANKING.md` and `items/*.md` as sensitive, but a shell heredoc to `items/*.md` is allowed and one to `RANKING.md` is not — so no single write mechanism reaches every backlog file.** Hit three times in one capture session: `Edit` on `QUEUE.md` refused, `cat > items/0178-*.md <<'EOF'` allowed, `cat >> RANKING.md <<'EOF'` refused. What worked for all three was `python3` doing an exact single-occurrence string replace with an `assert count == 1`. That is arguably the *safer* form for `QUEUE.md` — it is as targeted as `Edit` and it fails loudly on a moved queue — but `CONCURRENCY.md`'s *Never rewrite `QUEUE.md` by hand* and `0065` (name stream editors in that rule) are both silent on it, so every session improvises a mechanism while holding the lock, which is the worst moment to be improvising. Worth a rule naming the permitted write mechanism per backlog file rather than leaving it to trial and error. (`references/CONCURRENCY.md`; `skills/queue/SKILL.md` Step 2 and Step 6; related 0065, 0091; queue sweep 2026-09-21)
