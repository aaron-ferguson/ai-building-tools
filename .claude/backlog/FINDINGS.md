# Findings — parked, not yet placed

**One or two lines each, dated, newest at the top.** This is a buffer, not a second backlog: it
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

Format: `- YYYY-MM-DD — what happened, why it might matter (pointer: file, item id)`

---
- 2026-08-23 — **`verify` Step 5's reconcile has the same hole as the script built to encode it.** Its
  wording is "for each one whose remaining `blocked_by` entries are all `done`, set its row and its
  item `status:` to `ready`" — selecting dependents by `blocked_by` alone, with no check that the
  dependent is *currently blocked*. Nothing clears `blocked_by` when a ticket closes, so a closed
  ticket names its blockers for ever and a later close flips it from `done` back to `ready`. The
  in-progress exemption is stated as "no row another session holds", but a dependent may have no row
  at all, and `CONCURRENCY.md` *Claim tokens* puts ownership in the item's `claimed_by:`, not the row
  — so the procedure checks ownership in the one place the protocol says it does not live. A session
  hand-closing per Step 5 makes the same two mistakes `close` does; fixing only the script leaves the
  documented fallback wrong (pointer: skills/verify Step 5 item 3, 0024, 0023 FR7).
- 2026-08-23 — **`queue`'s Step 1 table has no row for a ticket sitting at `next: queue`**, which is
  the one stage `queue` itself owns. Every other stage's skill opens by taking the row at its stage;
  this one routes only on what the user just said, and its stated default for ambiguity is "Add" —
  which has no meaning on a bare `/queue` with nothing to capture. The item template explicitly
  creates these rows ("captured half-baked, **or found stale by a later stage**"), so the inbound
  case exists by design and the skill cannot see it. Found only because the user pointed at 0021 by
  hand. Related: re-specifying a bounced ticket reuses most of Step 2 but must skip the ID claim and
  skip Step 3 entirely (the rank is kept), and nothing says so (pointer: skills/queue Step 1 table,
  templates/item.md `next:`, items/0021).
- 2026-08-23 — **no rule covers an AC that a bounced ticket already verified.** 0021 returned from its
  outcome pass with AC2 and AC3 ticked `[x]` and AC1 red. The re-spec un-ticks both, because a second
  trimming pass invalidates a heading-preservation check and a before/after table measured against
  the first — but that is a judgement call made from scratch, and the opposite reading (verified is
  verified, leave them ticked) would have let a real regression through unchecked. `verify` closes on
  ticked ACs, so which way this goes decides what gets re-run (pointer: skills/queue Step 2,
  skills/verify, items/0021 ACs).
- 2026-08-23 — `verify` Step 2's ownership test cannot see a **claimless writer**. It checks for an
  `in-progress` row under a token you did not mint; `retro` by design holds no ticket, so while it
  landed lessons into `skills/verify/SKILL.md`, `skills/queue/SKILL.md` and `references/CONCURRENCY.md`
  mid-pass, `QUEUE.md` showed exactly one in-progress row — mine — and the field-and-claim check read
  as clean while three files were dirty. Only `git status` caught it, and only because Step 2 is run
  again by habit rather than by instruction (pointer: skills/verify Step 2, skills/retro).
- 2026-08-23 — an **advisory PASS has no way to bank what it verified**. 0024's greens were checked
  against both the committed and the working-tree copy of every file its ACs rest on, so none was
  luck — but Step 7 still forbids closing, and the row goes back to `next: verify` carrying no record
  that the whole pass already ran. The next session re-runs 21 assertions, six mutations and a
  tree-wide grep to reach the same verdict, and the only thing that actually has to change is a dirty
  tree nobody in the pass controls. Either the verdict needs somewhere durable to sit, or advisory
  needs to distinguish "green may be luck" from "green survived both states" (pointer: skills/verify
  Steps 2 and 7, items/0024).
- 2026-08-23 — this repo's own backlog has **neither `next` nor `claim` installed**, so `/develop`'s
  Step 1 ("run `./next develop` rather than reading `QUEUE.md`") had no correct answer and the whole
  queue had to be read. The skill treats the scripts as present; the repo that ships them is the one
  place they are not (pointer: skills/develop Step 1, .claude/backlog/).
- 2026-08-23 — `/develop` Step 1 tells a session to claim with `./claim` and a minted token under
  `.lock`, but this repo's `QUEUE.md` prose now says ownership is the directory `claims/<id>/` and
  needs no lock. Two live protocols, and the item frontmatter still carries `claimed_by:`. Worse:
  **an empty `claims/<id>/` is invisible to git**, so it cannot be "durable the moment it is made"
  per CONCURRENCY.md — it needs a file in it. Input to 0007 (pointer: QUEUE.md prose, 0007).
- 2026-08-23 — the missing-scripts finding above names `/develop` Step 1, but `/verify` Step 1 has
  the identical gap: it says to run `./next verify` and `./claim <id>`, and this repo's backlog has
  neither, so the queue was read by hand and the claim done by hand under `.lock`. A retro fixing
  only the develop pointer would leave verify broken (pointer: skills/verify Step 1, 0023).
- 2026-08-23 — `next`/`claim`'s `fm_list` does not strip YAML `#` comments, so an inline comment on a
  `touches:` entry is returned as list entries and printed as claimed *files* in `./next`'s CLAIMED
  FILES block. Annotating a frontmatter list is a natural thing to do and there is nothing to warn
  you (pointer: templates/next `fm_list`, 0024).
- 2026-08-23 — `develop` Step 5 says run "the project's whole test suite, every runner it has", and
  this project has no runner at all: the suite is `tests/*.test.sh` run by hand, discoverable only by
  `ls`. Neither `config.yml`'s empty `commands:` block nor the skill says where the suite is, so each
  session rediscovers it (pointer: skills/develop Step 5, .claude/backlog/config.yml).
- 2026-08-23 — `develop` Step 1 opens "run `./next develop` rather than reading `QUEUE.md`", and this
  repo's own backlog has no `./next` and no `./claim`: both exist only as `skills/queue/templates/`,
  which `queue` instantiates on first use, and this backlog predates that. The documented fallback is
  to read the queue and apply the same rules by hand — which means reading the `Status` column, the
  stale cache this backlog's whole 0024 exists to stop anyone trusting. It bit immediately: this
  session read 0026 as `blocked`, skipped it, and took row 2; the template reader run afterwards
  offered `TAKE 0026`. The fallback should derive from `blocked_by` explicitly, or the skills should
  say to instantiate the scripts (pointer: skills/develop Step 1, skills/queue/templates/next,
  .claude/backlog/).
- 2026-08-23 — with the scripts un-instantiated, `.claude/backlog/QUEUE.md`'s header now documents
  `./next --drift` as the gate on a backlog where that command does not run. Kept matching the
  template deliberately — diverging the wording to describe a local gap is the two-conventions defect
  0024 forbids — so the fix belongs in instantiating the scripts, not in the prose (pointer: 0024,
  .claude/backlog/QUEUE.md).
- 2026-08-23 — `retro` cites `references/CONVENTIONS.md` with no qualifier, but the installed skill
  directory has no `references/` — the path is relative to the **plugin root**, which `develop` and
  `queue` both say explicitly ("at the plugin root") and `retro` and `verify` do not. Cost a wrong
  turn at Step 0, on the one instruction that says to stop if it does not resolve (pointer:
  skills/retro, skills/verify, skills/develop:30).
- 2026-08-23 — the reflow rule landed in `queue` this pass covers a *grep* over prose, but the same
  break hit an `Edit`: a replacement string quoting "…is edited, after which `verify` checks…" matched
  nothing, because the file wraps between the two words. Every prose edit to these files has the
  defect its assertions have, and nothing warns an editor (pointer: skills/queue qa_level, this
  session).
- 2026-08-23 — a **mutation that silently fails to apply reads exactly like a guard that holds**. Six
  mutations were run against the new `close` guards; two came back green and one of those had simply
  not applied (the `perl` pattern never matched), so the "green" was a report about an unmodified
  file. Nothing in the loop distinguishes the two outcomes. Worse in shell specifically: `perl -pe`
  interpolates `$var` out of the line being mutated, producing a broken mutation whose red proves only
  that the assertions touch that *line*. `testing-conventions.md` tells you to prove a guard can fail
  but says nothing about proving the *mutation* landed — `diff` it (pointer: testing-conventions.md
  "Prove a new guard fails", tests/close.test.sh).
- 2026-08-23 — **FR6's ceiling was already breached before the ticket that had to hold it.** 0020 set
  `CONCURRENCY.md` at 1,500 tokens; 0024 and the retro pushed it to ~1,637, and 0023 was the ticket
  that discovered it, by being the next one required to measure. A ceiling with no gate is found by
  whichever ticket happens to cite it, which is arbitrary. Either the ceiling needs a scripted check
  in `tests/` or the rule needs to say who measures it and when (pointer: 0020 FR4, 0023 AC7,
  references/CONCURRENCY.md).
- 2026-08-23 — the margin under that ceiling is now **7 tokens**, so the next edit to
  `CONCURRENCY.md` breaches it again and the one after that has nothing left to trade. The file's
  compressible prose is spent; further growth has to come out of a *rule*, which no session should
  decide alone (pointer: references/CONCURRENCY.md, references/CONCURRENCY-INCIDENTS.md).
- 2026-08-23 — **a `close` script now exists as a template while this repo's own backlog still has
  none of the three installed**, so the `/verify` session that closes 0023 cannot use the thing 0023
  built. Instantiating one script alone would be worse than none — it would hide the asymmetry the
  earlier findings name — so this is a vote for instantiating all three as one unit of work (pointer:
  the three earlier missing-scripts findings above, skills/queue/templates/).
- 2026-08-23 — **renaming a rule is never a one-file edit.** `CONCURRENCY.md` names its rules and says
  to cite by name, so retitling *The two scripts* to *The three scripts* broke two citations in
  `CONCURRENCY-INCIDENTS.md`. Nothing greps for a stale citation, and a wrong rule name reads as a
  correct one (pointer: references/CONCURRENCY.md:3, references/CONCURRENCY-INCIDENTS.md).
- 2026-08-23 — `develop` Step 1 says to compare a candidate's `expects:` against every `in-progress`
  `touches:`, but **nothing tells a session to check the ticket's own `expects:` against a stage that
  landed after it was written**. 0023's FR1 enumerated a five-step close; 0024 had since made the
  reconcile a sixth step of `verify` Step 5, and building FR1 literally would have automated the
  stale-cache defect 0024 exists to fix. The staleness check in Step 2 is aimed at code that moved,
  not at a *sibling ticket* that moved (pointer: skills/develop Step 2, 0023 FR7, 0024).
- 2026-08-23 — **`develop` has no step for a ticket `verify` failed back to it.** Step 1 takes a
  `next: develop` row and Step 2 says restate the contract from the FRs, NFRs and ACs — but on a
  re-entry the actual specification is the *verdict section* a previous `verify` wrote into the item,
  which named the defect, the reproduction and the suggested fix. Nothing in the skill says to look
  for it; this session found it only by reading the whole item. A ticket that has been round the loop
  reads identically to a fresh one at Step 1, and the expensive half of its contract is in a section
  the skill never mentions (pointer: skills/develop Steps 1–2, 0023).
- 2026-08-23 — **the `CONCURRENCY.md` ceiling can no longer be paid the way it has been twice.** Both
  previous payments came from prose the file's own split assigns elsewhere — restated justifications,
  then this session moving an incident to `CONCURRENCY-INCIDENTS.md`. That route is now spent: the
  incidents are out, and the file sits at ~1,498 of 1,500 tokens. The next rule that has to change
  cannot buy its words from anywhere but another rule. This is the earlier "7 tokens of margin"
  finding arriving, not restating it — the conclusion has moved from *tight* to *no route left*
  (pointer: references/CONCURRENCY.md, 0020 FR4, 0023 AC7).


- 2026-08-23 — verifying 0023: the rule and the script it encodes disagree about what *held* means.
  `CONCURRENCY.md` *A stage writes only the ticket it holds* and `verify` Step 5's hand-close both
  define it as a non-empty `claimed_by:` in the item, and the fix deliberately removed the row clause
  from both. `close` still treats an `in-progress` row carrying no token as held as well (an `||`),
  citing *The working tree is shared too* — so the script is stricter than the rule, and a hand-close
  following the documented fallback would write a dependent the script leaves alone. Both directions
  are defensible; what is not is the two paths differing, which is the shape of the defect this very
  ticket's first verify pass failed on. Fixing it in the rule costs words the AC7 ceiling has no
  margin for, which is why it is parked rather than edited (pointer: references/CONCURRENCY.md,
  skills/verify/SKILL.md Step 5 item 3, skills/queue/templates/close reconcile guard, 0023 FR7).

- 2026-08-23 — **this repo is the one backlog that never gets the scripts it ships.** `develop`
  Step 1 opens with *"Run `./next develop` rather than reading `QUEUE.md`"*, and
  `.claude/backlog/` here holds no `next`, `claim` or `close` — they live in
  `skills/queue/templates/` and are copied into a *new* project's backlog by `queue` Step 0. So the
  project developing them claims by hand, against precisely the rules the scripts exist to
  remember, and the largest avoidable context cost the step names is unavoidable here (pointer:
  skills/develop Step 1, skills/queue Step 0, .claude/backlog/).
- 2026-08-23 — **a by-hand claim cannot be spread across tool calls, and the lock silently says so.**
  `trap 'rm -rf .lock' EXIT` fires when each Bash invocation's shell exits, so a lock taken in one
  call is already gone by the next — the claim looked held and was not. The whole sequence (lock,
  re-read, row edit, frontmatter, commit, release) has to be a single invocation. The skill's steps
  1–5 read as five steps, which is the natural way to run them and the wrong one (pointer:
  skills/develop Step 1, references/CONCURRENCY.md *Lock every write to QUEUE.md*).
- 2026-08-23 — **`QUEUE.md`'s prose documents an ownership protocol this project has not built.** It
  states that a claim is the directory `claims/<id>/` created with `mkdir` and that "claiming needs
  no lock" — 0007's design, and 0007 is unbuilt and blocked on 0005. The implemented protocol is the
  lock plus `claimed_by:`, and `CONCURRENCY.md`'s *A claim must be durable the moment it is made*
  warns explicitly that a `mkdir` claim is invisible to git. A session trusting `QUEUE.md` over the
  skill would claim invisibly and have it carried off by the next commit; `claims/` is empty while a
  row read `in-progress`, which is what the mismatch looks like from outside (pointer:
  .claude/backlog/QUEUE.md ownership paragraph, 0007).
- 2026-08-23 — **0026 cannot be executed by the stage its row names.** Its FR1 wants a fresh project
  taken through `queue → develop → verify` with each skill in its own session, and a develop session
  cannot create sessions — the row needs a person, so it is `waiting` in substance whatever the
  column says. Two things found while checking: its `blocked` was stale (sole blocker 0022 is
  `done`), left alone because the row is not takeable anyway and the fix belongs to whoever takes
  it; and the observed data FR2 wants already exists on disk —
  `~/.claude/projects/<slug>/*.jsonl` carry per-turn `usage` (cache read/creation, output) and a
  `<command-name>` marker naming the skill, so today's own isolated sessions are measurable per
  skill per turn. That is not a *fresh* project, so it satisfies FR2–FR7 but not FR1 as written
  (pointer: items/0026, README.md one-skill-per-session section).
- 2026-08-23 — **a relative-path lock trap leaks the lock, and the leak is invisible until the next
  claim.** The release idiom is `trap 'rm -rf .lock' EXIT`, which resolves against the shell's cwd
  *at trap time*. A claim script that `cd`s to the repo root to commit — the natural shape, since the
  commit needs repo-relative pathspecs — therefore deletes `.lock` in the wrong directory and exits
  reporting success. This session held the backlog lock for ~8 minutes across an entire
  implementation without knowing, and found out only because its own handoff hit a busy lock carrying
  its own token. Two fixes, both cheap: absolute paths in the trap, and a busy-lock report that says
  when the holder is *you* — the existing report shows the token and timestamp, which is enough to
  diagnose only if the reader remembers minting it (pointer: references/CONCURRENCY.md *Lock every
  write to QUEUE.md*, CONCURRENCY-INCIDENTS.md busy/stale paths, skills/queue/templates/claim).
- 2026-08-23 — **a paragraph-scoped grep test scoped by line count drifts out of its paragraph.**
  `tests/batching.test.sh` narrows its assertions to develop's batching paragraph with
  `awk '/one gate per session/{f=1} f{print; if (++n>14) exit}'` — a 15-line window over a 12-line
  paragraph, so it currently reads three lines of the *next* paragraph. Every "in the paragraph"
  assertion is therefore one edit away from passing on unrelated prose, which is the adjacent-
  measurement failure `verify` Step 3 warns about rather than a check wired to nothing. Verified
  today that it still fails correctly when the date is stripped from the paragraph alone, so this is
  latent, not live. A blank-line terminator (`/^$/{if(f)exit}`) costs nothing and cannot drift
  (pointer: tests/batching.test.sh PARA extraction).
- 2026-08-23 — **`verify`'s new batching permission makes its own drift-reporting instruction
  ambiguous, and no AC covers it.** Step 5.3 says to diff `./next --drift` before and after the
  reconcile and "report what was already there rather than owning it". Across a batch the second
  close's "before" report already contains the first close's effects — which *are* yours, from
  earlier in the same session — so the rule that distinguishes your drift from someone else's stops
  distinguishing them. 0025 licensed multi-ticket verify sessions without touching Step 5, and its
  ACs only reach as far as "each ticket closes on its own ACs" (pointer: skills/verify Step 5.3,
  items/0025).
- 2026-08-23 — **the by-hand claim works across Bash invocations if you drop the trap entirely.**
  The parked finding above says the whole lock sequence must be one invocation; the actual culprit is
  the `trap`, not the split. An explicit `mkdir` then an explicit `rm -rf` at the end holds a valid
  lock across several tool calls, which is what a `verify` close needs — its edits go through `Edit`
  for single-row safety and cannot be one shell call. The cost is a lock held for minutes rather than
  seconds, so keep every non-`QUEUE.md` edit outside it (pointer: references/CONCURRENCY.md *Lock
  every write to QUEUE.md*, skills/verify Step 5).
