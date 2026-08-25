# Findings — parked, not yet placed

**One or two lines each, dated.** This is a buffer, not a second backlog: it
holds findings whose home is **not local and not yet decided** — a possible row, a suspected skill
or convention problem, a cost pattern nobody has named yet.

**If a finding's home is obvious, write it there instead and do not park it.** A mechanism goes in
a comment beside the code, a rule goes in a test that fails, a unit of work goes to `queue` as a
row. Parking those is how a session ends with nothing written down *and* a growing file.

**Two sweepers empty this file, and they take different things.** `queue` takes the entries that
are **units of work** and specifies and ranks each one properly. `retro` takes the **lessons** and
lands them where they will be read again. **An entry that is both is taken by both** — classifying
at write time would put friction exactly where it is least wanted, at the moment of noticing, so
nothing here is tagged and neither sweeper waits for the other.

**Each sweeper removes only the entries it processed, and commits in the same turn.** Leaving a
processed entry is how the next sweep pays to read it again; removing an unprocessed one is how the
other sweeper's half disappears silently.

Every entry ends as a row, an edit, or a drop with a stated reason — so the normal state of this
file is empty. Entries older than about two weeks are dropped rather than processed: a finding
nobody acted on in two weeks was not worth acting on, and saying so is more honest than re-reading
it forever.

**If this file has grown, that is itself the finding** — retros are not running, or not emptying.

Format: `- YYYY-MM-DD — **what happened.** why it might matter (pointer: file, item id)`

**The date goes outside the bold, and this is load-bearing.** Both sweepers find entries by line
shape, so an entry whose date sits inside the `**` is skipped by a sweep and nobody ever notices.
Two such entries once made `MEASUREMENT.md` publish 26 findings in one sentence and 28 two
paragraphs later, and a retro undercount its own buffer by exactly the same two. Readers match
`^- (\*\*)?20[0-9]{2}-` to stay tolerant of the drift; writers use the canonical form so they
do not add to it.

**Entry order is not guaranteed and nothing should depend on it.** Sessions have appended at both
ends — the dates in this file currently change direction nine times — so a sweeper reads to the
end rather than stopping at the first entry older than its window.

---

- 2026-08-23 — **a vocabulary rename has no shape the backlog can hold.** Renaming the container
  ticket type effort→project touched 27 files across `QUEUE.md`, the item template, two skills, three
  test suites and 21 closed tickets. No `touches:` list can usefully declare that, no single ticket
  owns it, and `claim` protects one row at a time — so a cross-cutting rename is invisible to every
  concurrency mechanism the repo has, which is how it reddened `0005`'s held guard mid-pass. Either
  such a change needs its own convention (announce, land in one commit, re-run the whole suite) or
  the repo should accept that vocabulary is changed only when nothing is claimed (pointer:
  references/CONCURRENCY.md, items/0001 *Notes & decisions* 2026-08-23).
- 2026-08-24 — **every guard in this repo greps prose, and prose wraps — so a phrase that straddles
  a line break cannot be asserted at all.** Writing 0005's guard, `never its dependents` red against
  a template that plainly contained it: the sentence wrapped, so the phrase existed only as
  `never its` + `# dependents` on two lines and `grep` is line-based. The red is indistinguishable
  from a missing rule, and the tempting fix is loosening the assertion to a shorter fragment —
  which is exactly how these checks go vacuous. This project has no other kind of test: ten suites,
  all of them fixed-string greps over markdown that a later editor will rewrap for width. Nothing in
  the tests, the skills or `testing-conventions.md` warns that assertion phrases must fit one source
  line, or that rewrapping a paragraph is a breaking change to whatever asserts on it. Candidates: a
  helper that unwraps comment blocks before matching, or a stated rule that guarded sentences are not
  rewrapped (pointer: tests/graph-fields.test.sh `in_block`, skills/queue/templates/item.md
  `blocked_by:` comment, items/0005 *Notes & decisions*).

- 2026-08-24 — **a ticket's own prose is outside every guard the ticket writes.** 0026's privacy NFR
  forbade publishing paths outside the repo. Its test asserts the harvest *output* and the *record*
  stay clean, and both do — the two store slugs that breached it sat in the ticket's own Problem
  section, which no AC and no test reads. A privacy NFR wants one `git grep` assertion over the whole
  change, not one over the deliverable.

- 2026-08-24 — **`/verify` in this repo resolves to the bundled verify skill, not
  `ai-building-tools:verify`.** The session that verified 0026 loaded the built-in evidence-capture
  skill; this repo's stage protocol had to be read out of `skills/verify/SKILL.md` by hand. A stage
  whose name collides with a built-in is a stage that can silently not run.

- 2026-08-24 — **`./claim --help` and `./close --help` treat the flag as a ticket id.** `./claim
  --help` answers `no row for --help in QUEUE.md`. `./next --help` works and documents every mode, so
  the inconsistency reads as "this script has no help" rather than "you passed a bad id", and the
  scripts are the interface the skills tell every session to use. (pointer: `.claude/backlog/claim`,
  `.claude/backlog/close`)

- 2026-08-24 — **A non-takeable row 1 reads as an instruction, and bare `./next` is what makes it
  read that way.** 0026 sat at row 1 as `waiting` for a day and was read as "the next thing to do" —
  the user asked why we would run that test now. The rank was correct (a waiting ticket keeps its
  rank, deliberately) and `./next develop` correctly stepped over it, but bare `./next` prints
  `ROW 1: … | waiting` with no indication that nothing can take it, right beside the counts. It cost
  a session to explain rather than a script to answer. Candidate: have bare `./next` print the
  topmost *takeable* row alongside row 1 when they differ, which is the question a reader is actually
  asking (pointer: .claude/backlog/next, QUEUE.md's *a blocked or waiting ticket keeps its rank*,
  RANKING.md 2026-08-24 section).

- 2026-08-24 — **`claim`'s success message is stage-blind: it tells every claimant to set `touches:`,
  which is `develop`'s field.** A `verify` claim holds no `touches:` — it reads and runs, it does not
  open a file scope — but the script prints "now set touches: ... before you open anything" regardless.
  The consequence is not cosmetic: `./next` then reports the row to every other session as
  `0027 [b8d3] none declared — assume held, ask`, so a correct `verify` claim is indistinguishable from
  an under-specified `develop` one, and CONCURRENCY's *read an empty `touches:` as held* makes that the
  safe-but-wrong reading (pointer: .claude/backlog/claim success path, references/CONCURRENCY.md
  *The working tree is shared too*, items/0027 AC5).

- 2026-08-24 — **removing a preference from the base suite leaves a follow-up nothing owns.** 0030
  took Notion out of the base tool suite and documented the `external_feedback:` extension point a
  profile plugs into, but *wiring Aaron's own solo projects back up* is named in that ticket's *Out
  of scope* and therefore has no ticket at all. Any solo project with `notion.enabled: true` in a
  live `config.yml` now has a stated wiring path and no one carrying it out. The general shape is
  worth a rule: a ticket that moves a preference behind a profile creates a second, smaller ticket
  by construction — the port — and *Out of scope* is where it silently goes to die
  (pointer: items/0030, references/EXTERNAL-FEEDBACK.md "If you had `notion:` configured").
- 2026-08-24 — **the base suite has no home for a solo profile, only a company one.**
  `CONVENTIONS_CORE.md` resolves preferences through `companies/<name>/`, and the conventions repo is
  public, so a *solo* preference (which feedback product, which personal tooling) has nowhere to live
  that is both private and discoverable. 0030 hit this deciding where `NOTION.md` should move to and
  could only answer "not here"; it deleted the file and pointed at git history instead. Every future
  "move X behind a profile" ticket hits the same wall (pointer: items/0030 FR4, CONVENTIONS_CORE.md
  "Profiles & How Overrides Work").
- 2026-08-24 — **"never rewrite `QUEUE.md` by hand" needs to name stream editors, not just `Write`.**
  Closing 0030 without the scripts, a stray `perl -i -ne` invocation left in the script with an
  unset variable expanded its match to `"\n"` and deleted **every blank line in the file** — the row
  removal itself was correct, so the commit's diffstat (14 deletions for a one-row close) was the
  only signal. `Edit`'s uniqueness check cannot produce this class of damage; an in-place regex over
  the whole file can, and the rule as written reads as being about `Write` and read-rebuild-write.
  Repaired in the next commit. This is the strongest argument yet for 0027 (pointer:
  references/CONCURRENCY.md *Never rewrite `QUEUE.md` by hand*, items/0027, commits 7d5ce6f/1850ef2).
- 2026-08-24 — **a third size gate would trip the DRY trigger that 0028 correctly declined.**
  `tests/reference-size.test.sh` is the second copy of the `offenders`/`pad`/`ok`/`bad` shape;
  `coding-conventions.md`'s Tier-2 rule fires on the *third* instance, so 0028's *Out of scope*
  ruling ("duplicating ~40 lines of `sh` is acceptable here") is right today and expires the moment
  a third prose directory earns a goal. The two copies have already diverged in one way worth
  keeping — the reference gate carries an AC7 grep the skill gate has no equivalent of — so the
  extraction is not a pure lift (pointer: tests/skill-size.test.sh, tests/reference-size.test.sh,
  items/0028).
- 2026-08-24 — **`references/TRACKER.md` is 6,022 bytes, 35 bytes under the 6,057 goal.** The next
  sentence added to it reds the new gate under whatever unrelated ticket happens to be editing it,
  with no reason recorded and the author mid-way through something else. The gate doing its job, not
  a defect — but it means a third reference file is about to need either a relocation or a recorded
  reason, and better to decide that deliberately than at a red (pointer: references/TRACKER.md,
  tests/reference-size.test.sh, items/0028).
- 2026-08-24 — **"diff the mutation before believing either colour" silently gives you nothing when
  the implementation is not committed yet.** `testing-conventions.md` says to confirm a mutation
  landed by diffing the file, and the reflex is `git diff -- <path>`. On the TDD path that diff is
  against HEAD, which still holds the *pre-fix* code, so the mutated line never existed there and the
  grep for it comes back empty — an empty diff that looks exactly like a mutation that failed to
  apply, on a run that was in fact correctly red. It happened here and cost a second pass. The fix is
  cheap and worth naming in the rule: copy the file aside before mutating and `diff` against that
  copy, never against HEAD, whenever the code under mutation is uncommitted (pointer:
  ai-building-conventions/testing-conventions.md "Prove a new guard fails", skills/develop Step 5).
- 2026-08-25 — **a ticket's FRs enumerate what to add; a required *deletion* can live only in an AC,
  and *Out of scope* can read as though it forbids it.** 0034's five FRs describe the new derived
  rule and none says `verify` Step 2 must stop applying the advisory label — only AC2 ("no other
  trigger for the label remains anywhere in the file") requires that bullet to change. Worse, *Out of
  scope* opens "Changing what Step 2 *does*" and lists three things it keeps doing, which on a first
  read looks like Step 2 is untouched; the paragraph does go on to say the label moves, but a session
  working FR-by-FR per develop Step 4 reaches the ACs only after implementing, and the diff it would
  have written leaves two triggers in the file and fails QA. Rule to draw: **when a change relocates
  a decision, one FR should name the site it is relocated *from*, not only the site it moves to** —
  an addition-only FR list cannot express a move, and the AC that catches it fires after the work is
  done (pointer: items/0034 FR2 and its *Out of scope*, skills/verify Step 2, skills/develop Step 2).
- 2026-08-25 — **`develop` Step 5.4 says to clear the claim and take the lock, but the lock helper
  pattern in the docs releases on shell exit — and every Bash call is a new shell.** Routing 0036,
  `mkdir .lock` + `trap 'rm -rf' EXIT` in one tool call released the lock the instant that call
  returned, so the read, the write and the commit spanned three unlocked windows rather than one held
  one. `CONCURRENCY.md` says "hold it for the read, the write and the commit, then release in the same
  turn" and `./claim` gets this right by being a single process; a session doing it by hand cannot,
  unless the whole sequence is one command. Rule to draw: **a by-hand lock must be one tool call from
  `mkdir` to `git commit`, or it is not a lock** — which is a fourth silent leak to add to the three
  `CONCURRENCY-INCIDENTS.md` already lists (pointer: references/CONCURRENCY.md *Lock every write*,
  skills/develop Step 5.4).
- 2026-08-25 — **a mutation that leaves the suite green and a mutation applied to the wrong copy of
  the file produce the same evidence, and `verify` Step 3 has no step that tells them apart.** The
  test harness runs `skills/queue/templates/next`; this repo's own backlog runs
  `.claude/backlog/next`, kept byte-identical by `tests/backlog-scripts-installed.test.sh`. Mutating
  the copy the backlog runs — the obvious one, since it is what `./next` invokes and what the QA
  session has been reading — returns `134 passed, 0 failed`, which is exactly what a check-that-cannot-fail
  returns. One reads "this AC is unverified" and the other reads "I tested nothing", and nothing in
  the run distinguishes them. Step 2 warns about the *installed* copy under `plugins/cache/`; it does
  not cover a second in-repo copy that the harness prefers over the live one. Cheap fix: Step 3 should
  say to confirm the mutation reached the file under test — `grep` the mutated line, or read the
  harness's source variable first (here `NEXT_SRC`, `tests/next.test.sh:23`) (pointer:
  skills/verify/SKILL.md Step 3, tests/next.test.sh, tests/backlog-scripts-installed.test.sh).

- 2026-08-25 — **bundling several findings into one ticket creates a coverage obligation that
  nothing in `queue` Step 5 states, and a dropped entry is invisible at exactly the moment it is
  removed.** Step 5 says "remove only the entries you processed", which is unambiguous when an entry
  maps to a ticket and silent when six map to one. Sweeping the buffer's second batch I built the
  removal list from the clusters rather than from the tickets, then checked each entry against the
  FRs actually written before deleting anything — and three of forty-six were near-misses my bundles
  did *not* cover: the FR-lists-cannot-express-a-deletion entry, the ticket's-own-prose-is-outside-
  its-guards entry, and the confirm-the-mutation-reached-the-file-under-test entry. Each read as
  covered because a *neighbouring* concern in the same bundle was. Nothing prompted that check; had
  I skipped it, three findings would have left the buffer with no ticket and no trace, and the sweep
  would have reported success. A fourth was a clean fit and was landed by amending the ticket
  mid-sweep instead. The rule worth stating: when a ticket is bundled from N entries, the removal
  list is derived from the ticket's FRs, not from the cluster that produced it (pointer:
  skills/queue/SKILL.md Step 5, items/0052, items/0055, items/0057).
