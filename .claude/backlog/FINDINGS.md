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
- 2026-09-17 — **An unattended `claude -p` stage cannot write any file under `.claude/`, and no settings rule or permission flag observed so far changes that.** The refusal is *"Claude requested permissions to edit … which is a sensitive file"*, and it stopped a queue sweep mid-run (ids 0165-0171 minted, three item drafts left untracked, `QUEUE.md`/`FINDINGS.md` untouched). Three probes, each a real dispatch: `Write(.claude/backlog/**)` was rejected as a rule shape — *"not matched by file permission checks — only Edit(path) rules are"*; `Edit(.claude/backlog/**)` parsed but the write was still refused; `--permission-mode acceptEdits` was refused identically. Untested and not tried without a person's say-so: `dontAsk` and `bypassPermissions`, which grant far more than one directory. The backlog living under `.claude/` is what puts every stage's own writes behind this check. (`skills/sprint/SKILL.md` Step 3; `.claude/settings.json`; run-20260913T222409Z queue 7bc65dbf)
- 2026-09-17 — **A supervising session leaving auto mode does not reach its dispatched stages: the sensitive-file refusal is identical.** Probed after the user switched their own session out of auto mode, on the reasoning that a prompt might then be answerable — `claude -p` runs as its own process with no channel to the person's terminal, so no mode on the supervisor side can answer a nested session's prompt. The routes that remain are an attended `claude --resume <id>`, or a permission mode that widens authority far past one directory. (`skills/sprint/SKILL.md` Step 3; run-20260913T222409Z queue 7bc65dbf)
- 2026-09-20 — **A guard's stop set that mirrors another function's control flow has nothing asserting the two stay in step.** `gate_contiguous` in `skills/queue/templates/next` ends a gate at anything the rank walk would not step over, and `walk_steps_over` reproduces that walk's three `continue` arms by hand — in-progress, an open blocker, held. A fourth arm added to the walk leaves the gate silently stricter than the walk it is defined against, and only the blocker arm has a fixture (0158 AC3). **This still needs a row**: a case per arm, or a shape that derives one from the other. (`skills/queue/templates/next`; develop 0158, claim b040)
- 2026-09-20 — **Two tickets built in one session can make each other's FRs stale inside that session, and only the second one's tests catch it.** `0168` added `--scope` and enumerated the stages a scope ticket can still be dispatchable at — `develop` and `verify`, correct on the day it was written. `0159`, built ninety minutes later in the same session, made `next: design` dispatchable, so a scope ticket sitting at design read as *finished scope* and fired the findings tail mid-run: the exact failure `0168` exists to prevent, through the stage `0159` opened. The enumeration was invisible to `0168`'s own suite, which had no design row anywhere, and it surfaced only as a red in `0159`'s new case. The develop skill's staleness rules point at *closed* siblings (`DONE.md`, a grep for the symbol); **a sibling that has not reached `verify` yet is not in `DONE.md` and its code is already in the tree**. `0168` FR2's text still names two stages and nothing may edit it but its own claimant. **This still needs a row**: a batch guardrail for enumerations a later ticket in the same batch widens. (`skills/develop/SKILL.md` Step 2; `skills/queue/templates/next` `scope_live`; develop 0159, claim 1150)
- 2026-09-20 — **A committed backlog script and the skill that drives it take effect at different times, so a refusal can land before the instruction that explains it.** 0160 gave `close` a sixth refusal — a `close_by: verify` ticket needs a `Conventions: <path>` line in its QA evidence — and taught `skills/verify/SKILL.md` to write one. `.claude/backlog/close` is a committed file and binds the next session immediately; the skill resolves from `~/.claude/plugins/cache/` at session start, so until a release the next verify session meets a refusal its own instructions never mention. **The window is opened by any ticket whose FRs pair a script refusal with a skill that must satisfy it**, and nothing in `develop` Step 5 or the release checklist asks which half binds first. Mitigated here only because the refusal message names the missing line and the fix. **This still needs a row**: either a rule that such a pair releases atomically, or a refusal that degrades to a warning for one release cycle. (`CLAUDE.md`, *the installed copy is what runs*; `skills/queue/templates/close`; develop 0160, claim eeb0)
