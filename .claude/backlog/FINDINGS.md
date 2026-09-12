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


- 2026-09-09 (retro) — **Step 2 forbids the destination work that Step 1 requires, for the
  *absorbed* disposition specifically.** Step 2 says to present a *provisional* destination and wait,
  because checking one properly is wasted on a finding the user rejects; Step 1 says a deferral must
  name a destination you have opened, since a wrong pointer costs the next pass full price. For
  *landed* those coexist — the file is obvious and the grep can wait. For *absorbed* the row **is**
  the destination, and there is no way to propose "this already has a home" without having opened the
  item to know it does. This pass opened five item files before the gate and found the proposal
  materially changed by two of them: `0043` turned out to be the right home for a finding proposed as
  a new row, and `0118` already owned half of another. Both readings are defensible and the skill
  does not say which wins (pointer: `skills/retro/SKILL.md` Steps 1 and 2).
- 2026-09-09 (retro) — **`retro` Step 4 tells a session to file a row and never says how to claim the
  id, and `next_id` alone is not enough to get it right.** Filing six rows this pass, an id was
  written into a skill file and a commit message from the neighbourhood of `config.yml`'s `next_id`
  without reading `items/` — and it collided with `0141`, a row created earlier the same day. The
  bump was correct; the *reading* of it was not, and nothing in the step prompts the check. `queue`
  Step 2 owns id allocation and `retro` files rows without citing it, which is the cited-never-
  restated rule failing by omission rather than by drift: no rule was restated, so nothing looks
  wrong (pointer: `skills/retro/SKILL.md` Step 4 *Filed*, `skills/queue/SKILL.md` Step 2,
  `.claude/backlog/config.yml` `next_id`).
- 2026-09-09 — **an acceptance criterion asked for a red-making state that reaching would itself be
  the defect.** 0143 AC3 wanted the guard's redaction exemption proved by a tracked file carrying a
  wrapped internal name, so that dropping the exemption reds the repo — but any such file is a
  committed name, which the same item's Security NFR forbids. The two clauses are individually
  reasonable and jointly unsatisfiable, and nothing in `queue`'s AC form catches it: the AC names a
  red-making input, which is exactly what the form asks for. A privacy guard is the general case —
  its tree-level evidence is always the thing it exists to prevent — so the claim has to be carried
  by assembled samples and the substitution recorded beside the check (pointer: `skills/queue/SKILL.md`
  AC form, `tests/falsifiable-acs.test.sh`, item 0143 AC3).
- 2026-09-09 (verify) — **The entry above is wrong, and the general lesson is that an
  *unreachability* claim in build notes needs re-running exactly like a mutation table does.**
  `0143` AC3 was recorded as unsatisfiable at tree level, because reaching it "means COMMITTING a
  name". It does not: a throwaway `git worktree` plus `PRIVATE_NAMES_FILE` pointed at a **synthetic**
  list makes the fixture tracked without staging anything in the checkout and without any real name
  existing, and this pass drove AC3 both ways in about a minute — green on a wrapped placeholder,
  red on `EXEMPT_PREFIX=''`. `verify` Step 3 says "never trust a mutation you did not run" and
  `develop` Step 5 has nothing for the mirror case, so a *substitution* offered in place of a check
  reads as settled where a discharged mutation reads as re-runnable — and the build note went
  further, telling the QA pass to "read AC3 as satisfied by that control or bounce the
  substitution", i.e. naming the two options and not the one that was available. The recurring
  shape: an environment constraint stated as a construction constraint (pointer:
  `skills/verify/SKILL.md` Step 3, `skills/develop/SKILL.md` Step 5, item 0143 AC3).

- **2026-09-10 — `./claim <id>` makes no file-scope check, so an explicitly named ticket is claimed
  straight through a full collision.** `develop` Step 1 says to compare a candidate's `expects:`
  against every in-progress `touches:` before claiming, and the only thing that prints that
  comparison is `./next <stage>` — which reports it for the row *it* offers, not for the id you
  asked for. Invoked as `/develop 0130`, `./next develop` printed `CLAIMED FILES … 0131 [78c7]`
  about its own candidate `0142`, and `./claim 0130` then granted a row whose four `expects:` paths
  are the same four `0131` holds, with no warning of any kind. The claim was released a minute
  later, unused. Either `claim` owes the check for the id it is given, or `./next <stage> <id>`
  owes it for the id it is asked about — today neither does, and the session that follows the skill
  literally is the one that collides (pointer: `.claude/backlog/claim`,
  `skills/queue/templates/next`, `skills/develop/SKILL.md` Step 1).

- 2026-09-10 [->0150] (design) — **`design` Step 4 tells a session to write an item file and commit, and
  never names the lock.** `references/CONCURRENCY.md` requires it for *every* write to the backlog
  directory, item files included, and `develop` and `verify` name it five and four times each;
  `skills/design/SKILL.md` names it zero times (repo and the installed 0.9.23 copy are identical, so
  this is not install drift). Step 4's unclaimed path is the whole point of the skill and is the
  largest by-hand item write outside those two skills — this session made its edits unlocked before
  noticing, and the sequence would have read as correct afterwards. Same shape for the claim: Step 4
  says "you write it" without saying that `./handoff` demands a token, so the session has to work out
  on its own that it must `./claim` first (pointer: `skills/design/SKILL.md` Step 4,
  `references/CONCURRENCY.md` *Lock every write to the backlog directory*).

- **2026-09-10 — a BACKGROUNDED mutation sweep runs `git checkout` against the working tree you are
  still editing in the foreground, and `develop` Step 5 recommends both halves separately.** Step 5
  tells a session to background a long sweep and wait on a sentinel (`until grep -q`), and tells it
  to mutate-and-restore with `git checkout -- <path>`. Combined, the sweep issues `checkout` on its
  own schedule while the foreground session edits other files — and a `checkout` of a path the
  foreground later edits destroys that edit with no error, a green suite, and nothing to notice it
  by. Observed on this ticket: a six-mutation sweep ran `git checkout -- skills/queue/templates/next`
  six times while the session worked on two other files, and was safe only by the accident of which
  files came next; a later foreground `checkout` on that same path then did delete an uncommitted
  refactor of it. Step 5's "mutate only what is committed" is the right rule and is stated for the
  foreground case only — a sweep that is asynchronous needs the stronger form, which is that it must
  run in a throwaway worktree or hold paths the session has finished with (pointer:
  `skills/develop/SKILL.md` Step 5).
- 2026-09-10 (verify) — **a build note's mutation claim was wrong for the second time in two days,
  and both times the wrong half read exactly like the right ones.** `0130`'s note says *"a guard
  drives the cap and the tail count, and mutating the ranking to first-seen reds it"*. Cap and tail
  redden; the ranking does not — the cap fixture's insertion order happens to put the hub first, so
  ranked and first-seen produce the same block and nothing tests rank. The 2026-09-09 entry above
  records the same shape for `0143`'s unreachability claim. `verify` Step 3 already says to re-run
  any mutation you would cite, and it worked both times — what is missing is anything on the
  *writing* side: `develop` invites a mutation table and nothing asks the author to distinguish a
  mutation they ran from a property they reasoned about, which is the one thing the reader cannot
  tell from the table (pointer: `skills/develop/SKILL.md` build notes, `skills/verify/SKILL.md`
  Step 3, item 0130).
- 2026-09-10 (verify) — **mutating a duplicated script silently tests nothing, and the tree gives no
  signal.** `.claude/backlog/next` and `skills/queue/templates/next` are byte-identical by
  requirement, and `tests/next.test.sh` copies the *template* into its fixture. A first sweep
  mutated the backlog copy: seven mutations, `303 passed, 0 failed` every time, `git diff` non-empty
  every time, and nothing distinguishing that from seven real gaps. Nothing guards the two copies
  for equality either, so mutating one reddens no drift check. `verify` Step 3 names this trap
  ("it reached the copy the harness runs") and points at `testing-conventions.md`; what it does not
  say is how to *find* which copy that is before starting, which for a fixture-copying harness is a
  grep of the test file (pointer: `skills/verify/SKILL.md` Step 3, `tests/next.test.sh:23`, item
  0146 — *when a required duplication earns a drift guard*).
- 2026-09-10 (develop) — **a prose guard keyed on a section name the file does not have is red when
  it asserts presence and green forever when it asserts absence.** `tests/orchestrate.test.sh`'s
  `section()` matches `## <want>` as a PREFIX, so the headings are `Step 2 — The cycle` and a guard
  written against the subject (`"The cycle"`) extracts nothing. Asserting presence, that reds a
  correct file and the session fixes it in a minute; asserting absence, it passes over an empty
  string and can never fail — the unfalsifiable guard `testing-conventions.md` names, reached by a
  typo rather than by a bad assertion. Nothing in the harness reports an empty extraction, and the
  three suites carrying this pair copy it byte for byte (pointer: `tests/orchestrate.test.sh:104`,
  item 0131).
- 2026-09-10 (verify) — **a `says <file> <section> <token>` guard over prose is satisfied by a code
  fence in the same section, so the paragraph it was written for can be deleted green.**
  `tests/orchestrate.test.sh`'s AC11 pair asserts `--started` and `cumulative` inside
  `Step 2 — The cycle`. Deleting the whole `**--started` is how the run keeps its promise…**`
  paragraph leaves `--started` in the section's `sh` fence one line up, so only the `cumulative`
  assertion reds: `154 passed, 1 failed`. Reverting the file's whole change reds both, which is why
  the mutation at the AC's altitude looks conclusive. The grip a token-presence guard has on prose
  is the section minus its code blocks, and no harness here draws that line (pointer:
  `tests/orchestrate.test.sh:1534`, `skills/orchestrate/SKILL.md` Step 2, item 0131).
- 2026-09-10 (design) — **a ticket's `relates:` is written once and the tickets that later block on
  it are invisible from inside it.** 0059 was written 2026-08-25 and lists `relates: ["0025",
  "0026", "0050", "0058"]`. 0132 and 0137, created 2026-09-09, both carry `source: user` and both
  govern the answer — 0132 `blocked_by: ["0059"]` with an AC that reds explicitly on the shape this
  session had already decided, written and committed. The edge exists, and it points the wrong way
  for the reader: `design` Step 2 sends you to prior art, the design system, the conventions and the
  ticket's own evidence, and nothing sends you to `grep -l '"0059"' items/*.md`. Caught only because
  the corrected `QUEUE.md` scrolled past on an unrelated write and a newer row's title mentioned
  batching. A one-line reverse-edge check belongs in `design` Step 1 or 2, where the contract is
  read (pointer: `skills/design/SKILL.md` Step 2, items 0059, 0132, 0137).
- 2026-09-10 [->0150] (design) — **`design` Step 4's write path names no lock and no script, and the one
  script that fits refuses the case.** The step says to set `next:`/`status:` and "commit by
  pathspec in the same turn" for an *unclaimed* ticket, but every write is inside
  `.claude/backlog/` and `CONCURRENCY.md` exempts nothing; `./handoff` cannot be the vehicle
  because it demands a claim token and `in-progress` on both row and item, which an unclaimed
  design row is not. So the correct procedure is: take the lock by hand, single-row `Edit` on
  `QUEUE.md`, commit, release — and the step states none of it, where `retro` Step 4 states all of
  it for the same directory. This pass wrote both item files before taking the lock and only then
  noticed (pointer: `skills/design/SKILL.md` Step 4, `references/CONCURRENCY.md` *Lock every write
  to the backlog directory*, `.claude/backlog/handoff`).
- 2026-09-10 (design) — **two rows carried the same open design question and nothing connected
  them, and the stage reader offers the wrong one first.** 0060 and 0080 both ask whether a findings
  entry gets a marker and whether `./next --findings` should count a marked one; neither named the
  other in `relates:`, and `./next design` offers 0080 — so `/design` invoked with no id settles the
  narrower row, leaves the broader one, and a later pass re-litigates. `queue` Step 2 has no
  duplicate-question check for a row routed to `design`, and a design question is exactly the kind of
  duplicate that cannot be spotted from a title (pointer: `skills/queue/SKILL.md` Step 2, items 0060
  and 0080).
- 2026-09-10 (develop) — **`develop` Step 5's live-run check matches its own command line, so it
  always reports a live run.** The step says to check `pgrep -f <runner>` before starting a whole-suite
  run. Here the runner is `tests/*.test.sh`, so `pgrep -f 'test.sh'` matched the very shell command
  containing that string and printed "LIVE RUN" with nothing running. A session obeying the step waits
  on a process that is itself, or — worse — learns to disregard the check. The step needs a pattern
  that excludes the caller (`pgrep -f` plus `grep -v $$`, or matching the runner's own process name)
  (pointer: `skills/develop/SKILL.md` Step 5, *a whole-suite run is a shared resource*).
- 2026-09-10 (develop) — **a test fixture helper named for its scope silently sets ownership too.**
  `add_item_blank_scope` in `tests/next.test.sh` hardcodes `claimed_by: "bb22"`, so a case using it to
  build an *unheld* candidate that declares no paths gets a HELD one — and the take loop skips held rows
  before any collision is computed, so the case goes green for a reason unrelated to what it asserts.
  It cost one wrong red here and was only caught because the expected failure arrived with the wrong
  message. A helper that sets a field outside its name should say so in its name or take it as an
  argument (pointer: `tests/next.test.sh` `add_item_blank_scope`).
- 2026-09-10 (develop) — **a mutation sweep cannot relocate the test script, because `ROOT` is derived
  from its own path.** `testing-conventions.md` says to confirm a mutation reached *the copy the harness
  runs*; the obvious way to point a suite at the other copy is to `sed` its `*_SRC` line into a scratch
  file and run that. Here every suite computes `ROOT="$(cd "$(dirname "$0")/.." && pwd)"`, so the
  relocated copy resolves `ROOT` to the scratch directory and dies with "no next script at …" — which
  reads like a broken mutation rather than a broken harness. The working form is to mutate the template
  in place and restore it in the same turn (pointer: `tests/next.test.sh` `ROOT=`, `develop` Step 5).
- 2026-09-10 (verify) — **`claim` reads any `*` character in an `expects:` entry as an exclusive
  claim, where `next` reads the same entry as an ordinary path.** `claim`'s detector is
  `rest ~ /\*/`, so a ticket declaring `expects: - "skills/*/SKILL.md"` is refused with "its expects:
  declares \"*\", an exclusive claim over the whole tree" whenever anything else is held; `next` uses
  `contains_word '*'` and correctly treats that same glob as one path. Verified live against a
  fixture backlog. Latent, not live — no item's `expects:` carries a `*` today — and it fails closed,
  but the refusal misdiagnoses the row and the two scripts disagree about what the field means. The
  fix is one word-match, in both copies (pointer: `.claude/backlog/claim` exclusive detector,
  `.claude/backlog/next` `contains_word`, 0067 FR5/FR6).
- 2026-09-10 (verify) — **`next` offers an exclusive-claim row for the taking that `claim` will then
  refuse.** With another row held, `./next develop` printed `TAKE 0001 … EXPECTS *` and named the
  holder two lines below it; `./claim 0001` then refused on 0067 FR6's precondition. Both FR5 and FR6
  key on a *held* `"*"` row, so nothing covers a *takeable* one while others are held — `next` has
  the information and does not gate on it. A `--drive` loop picks that row and takes its exit code
  from a refused claim (pointer: `.claude/backlog/next` `collision_report` / take loop, 0067 FR5).
- 2026-09-10 (verify) — **`/verify` resolved to the CLI's built-in `verify` skill again, not
  `ai-building-tools:verify`** — the second recorded occurrence of 0064's class, after the one 0064's
  Problem section records from 0026. The built-in ran a full runtime-observation pass and produced a
  PASS report, then stopped: no claim, no AC ticks, no `## QA evidence`, no close, and the row sat at
  `next: verify, status: ready` looking untouched. It was caught only because the human asked why the
  ticket had not closed. The two skills are unrelated jobs sharing one short name — the built-in ships
  with the CLI (`bundled-skills/<cli-version>/…/verify`, carrying `examples/cli.md`) — so no version
  bump or install check can ever make this visible; 0064's FR1 self-naming line is the only thing that
  would have (pointer: `skills/verify/SKILL.md` opening, items/0064 FR1).

- 2026-09-10 (develop) — **`develop` Step 2 tells you to `grep -rn "<your id>"`, and this  repo answers with test fixtures.** Grepping `0059` returned four hits, all of them fixture rows  inside `tests/close.test.sh` (`| 0059 | Checklist performed | verify | in-progress | 0000 |`) and  none of them about item 0059. The check is cheap and correct, but in a repo whose suite builds  synthetic backlogs its signal-to-noise is inverted: every low id collides, and a session that  skims the hits could equally read a fixture as a sibling citation or dismiss a real one as a  fixture. Fixture ids in a backlog-shaped fixture want a form no live row can take. This still  needs a row; no ticket in QUEUE.md covers it (pointer: `tests/close.test.sh`, `skills/develop`  Step 2 "Grep your own id as well as the symbols").

- 2026-09-10 (verify) — **`tests/batching.test.sh`'s `binds` helper matches across a sentence
  boundary, so it does not do what its own comment claims.** The helper exists to tell "shared scope
  is *why a batch pays more*" from a paragraph that merely contains both phrases in unrelated
  sentences, and 0059's build notes credit it as "what makes AC2 falsifiable at all". Verifying 0059
  falsified that: rewriting develop's sentence to `Rows must share a file scope (their `expects:`
  overlap) or a parent slice. Orientation in the code is why a batch pays more` — scope restored as a
  condition on entry, the pre-0059 shape — left the guard at **39/39**, because the bounded span
  `expects:.{0,120}parent slice.{0,40}why a batch pays more` happily spans the full stop between the
  two sentences. AC2 is still guarded, but by the `says` on `not a test the rows must pass first`,
  which reds when the coherent regression drops it (38/1); the span assertion contributes nothing the
  presence assertion does not. This is `testing-conventions.md` line 15's own rule — *Anchor an
  assertion to the claim, not to the document that contains it* — recurring one level down: the span
  is anchored to a *window* of characters rather than to the sentence, and a character budget is a
  guess at sentence length exactly as a line count was a guess at paragraph length (the mistake the
  same file's `extract` comment records fixing at 0032). Left uncovered deliberately per `verify`
  Step 3, *a mutation that does not redden is a result to publish*. Needs a row (pointer:
  `tests/batching.test.sh` `binds()` and the AC2 block).
- 2026-09-10 (develop, 0060) — **a size guard can sit four bytes from its goal, and nothing in
  `develop` tells you to look before you write.** `references/REPORTING.md` was 6053 bytes against
  `tests/reference-size.test.sh`'s 6057; the ticket required a rule in it, so the guard was destined
  to red at the very end of the work. Step 3 says to grep the project's guards for the *mechanism*
  you are introducing, which does not reach a *budget* on a file you are merely growing — and the
  budget check is one `wc -c`. Same shape as the "grep the figure an FR reprices" rule Step 2
  already carries, arriving from the size guards instead (pointer: `skills/develop/SKILL.md` Step 3,
  `tests/reference-size.test.sh`, item 0060).
- 2026-09-10 (develop, 0060) — **a NEGATIVE prose assertion whose phrase straddles a line wrap is
  green on arrival and proves nothing.** `CLAUDE.md` warns that rewrapping a guarded paragraph is a
  breaking change; the unwritten half is that *writing* one has the same hazard, and that only the
  negative direction is silent about it — a positive assertion fails loudly and is fixed at once,
  while an absence check returns exactly the colour you wanted. Caught here only because the guard
  was run before the prose it asserts on was written. Three instances in one session, one in
  pre-existing prose and two in prose written the same hour (pointer: `CLAUDE.md` *Tests*,
  `tests/findings-buffer.test.sh`, item 0060).
- 2026-09-10 (develop, 0142) — **`handoff` refuses to write `blocked`, so the state it leaves behind
  is drift — and since 0142 that state stops a driver.** A develop stage that cannot get the tree
  green and adds a `blocked_by` entry leaves the row at `ready` over an open blocker: `handoff`
  rejects `blocked` as "derived from blocked_by and never authored", and `develop` Step 5 says the
  same in as many words. `./next --drift` calls exactly that class 2 drift, and `--drive` now
  escalates on it. So the documented hand-off shape and the drift class list disagree, and the run
  the tooling itself produced is the one that stops. One of the two has to move — either `handoff`
  writes the `blocked` cache when the item's `blocked_by` says so, or the class stops firing on a
  row whose column is merely un-refreshed. 0142's *Out of scope* reserves the class list to 0115 and
  0141, so this is neither ticket's to settle alone. Needs a row (pointer: `.claude/backlog/handoff`
  status validation, `skills/develop/SKILL.md` Step 5, `--drift` class 2, item 0142).
- 2026-09-10 (develop, 0142) — **a fixture whose words describe ownership while its bytes describe
  drift stays green until something starts reading the difference.** Three cases in
  `tests/next.test.sh` scaffolded a row at `in-progress` over an item with an empty `claimed_by:` —
  titled "Held by a session", "Still held", "Held by another session" — which 0140 settled is not
  held by anybody and 0115 class 5 calls drift. Nothing red, because no reader crossed the two until
  `--drive` did. The tell is cheap and general: a fixture's title is a claim about the state it
  builds, and the two drifted apart the moment a *neighbouring* ticket sharpened what the state
  means (pointer: `tests/next.test.sh` `add_ticket_held`, items 0115, 0140, 0142).
- 2026-09-10 (verify, 0142) — **one test file indents its tally, and the anchored grep a batch run
  uses then reports it as no tally at all — which `verify` Step 3 names as the tell of a collided
  self-mutating guard.** Twenty-eight of twenty-nine files print `N passed, M failed` at column one;
  `tests/cross-cutting-change.test.sh:190` prints `printf '\n  %s passed, %s failed\n'`. Sweeping
  the suite with `grep -E '^[0-9]+ passed'` therefore flagged the one green file as the one shape a
  QA session is told to treat as red, and it cost a re-run to clear. The tally line is a machine
  interface between the suite and every reader that batches it, so its format is a contract; nothing
  asserts it (pointer: `tests/cross-cutting-change.test.sh:190`, `config.yml` `commands: unit`,
  `verify` Step 3's missing-tally rule). Needs a row.

- 2026-09-10 — **a fixture name written into a ticket's own prose becomes tracked content, so the
  privacy guard's "clean tree" case is not clean.** 0148 drove `tests/measurement.test.sh` with a
  synthetic name list; the well-formed-list-and-no-leak combination failed, correctly, on a match in
  `items/0148-*.md` itself, because the item's reproduction block quotes the very name the fixture
  uses. Any guard that searches the tracked set has this coupling with the prose describing it, and
  the failure reads as a defect in the guard rather than as the fixture matching the ticket. The
  session rebuilt the fixture on a name absent from the tree and lost a drive doing it. Cheap rule
  if it recurs: a name-shaped fixture is assembled in the test and never spelled in the item
  (pointer: `tests/measurement.test.sh` falsification controls, items/0148 QA plan, items/0143 FR1).

- 2026-09-10 (develop, 0129) — **renaming a skill leaves every OPEN sibling ticket's `expects:`
  pointing at the path it moved from, and no rule says who may fix it.** The rename moved
  `skills/orchestrate/` and `tests/orchestrate.test.sh`; eight `ready` items (0041, 0054, 0089,
  0132, 0133, 0134, 0135, 0137) still name the old paths in `expects:`. 0067's rule permits a
  rename to rewrite open unheld items, but it is written about the backlog's own *vocabulary*, and
  *A stage writes only the ticket it holds* points the other way for a product rename — so the
  session performing one has two applicable rules and no tie-break. The damage is bounded, because
  `develop` Step 1 requires `touches:` to be `expects:` checked against the code rather than copied,
  so the claiming session meets a path that does not exist and corrects it. What is unbounded is
  `./next`'s file-scope triage, which compares the two fields verbatim and so compares against paths
  nothing can ever hold (pointer: `references/CONCURRENCY.md` *A change that touches every file*,
  items/0067 FR3, `develop` Step 1). Needs a row.

- 2026-09-10 (develop, 0129) — **a guard whose subject is a word is a match for its own sweep, and
  the obvious fix is the one that blinds it.** AC2 asserts that the retired name survives nowhere on
  the live surface; written as a plain `grep -rl`, `tests/sprint.test.sh` matches itself, and
  excluding the guard file makes the file most likely to carry a stale citation the one file the
  sweep cannot see. Assembling the word at runtime — `OLD="orch""estrate"` — costs one line and
  keeps the file inside its own sweep. Worth a line in `testing-conventions.md` beside the existing
  "a check that filters for a set and then asserts over it" rule, which is the same failure reached
  by the other route (pointer: `tests/sprint.test.sh` 0129 block).

- 2026-09-10 (verify, 0129) — **`tools/release verify` compares the install against `HEAD`, not
  against the released commit, so it goes red on every backlog commit that lands after a release.**
  AC6 names it as the check that the version bump re-extracted the bytes. Run one release and three
  claim commits later, it reported `FAILED -- the install does not hold 7726456` with three
  differing paths — `.claude/backlog/QUEUE.md`, `items/0107-…` (another session's claim) and
  `items/0129-…` (this stage's own claim) — plus `record FAILED -- gitCommitSha is 59d4b2d but the
  verified commit is 7726456`, where 59d4b2d is in fact the released commit and the record is
  correct. Every one of those is backlog state, none is product, and in a repo where two sessions
  claim rows continuously the tool is red within minutes of the release it exists to verify. The
  substituted check that answers the real question costs one worktree: `git worktree add --detach
  <path> <released-sha>` then `diff -rq <path> <install>` — 230 paths identical, only `.in_use`
  extra. Either the tool should take the released SHA as an argument, or it should compare only
  tracked paths outside `.claude/backlog/`. Needs a row (pointer: `tools/release`, `CLAUDE.md`
  *When asked to release*, items/0129 AC6).

- 2026-09-10 (develop, 0107) — **`./next <stage>` prints a row as TAKE and prints, in the same
  breath, the held set that row collides with.** `./next develop` offered `0132`, whose `expects:`
  names `skills/orchestrate/SKILL.md`, directly under `CLAIMED FILES — 0129 [841c] none declared;
  predicted by expects: skills/orchestrate/SKILL.md … — assume held, ask`. Takeability's fourth test
  compares against a held row's `touches:`, and `0129`'s is empty, so the *predicted* set the script
  computes and prints for a human is not fed back into its own COLLIDES test. `CONCURRENCY.md` says
  to read an empty `touches:` on an in-progress row as *its files are held*, so the script contradicts
  the protocol it implements — and it fails in the direction that steers a session INTO the
  collision, since TAKE is the line a session acts on. The same call would have handed `0133`, `0134`
  and `0135` too, all of which name that file. Needs a row (pointer: `.claude/backlog/next`,
  takeability's fourth test; `references/CONCURRENCY.md`, *The working tree is shared too*).

- 2026-09-10 (develop, 0107) — **the paragraph-window helper in `tests/falsifiable-acs.test.sh`
  carries a guard clause that can never fire.** `window()` reads
  `inw && $0 ~ endre && !first { exit }` with the body then setting `first = 0`. `first` is unset
  (falsy) on entry and `0` (also falsy) ever after, so `!first` is true on every line and the clause
  protects nothing — its evident purpose, stopping the window exiting on its own opening line when
  that line also matches the end regex, is not achieved. Nothing currently triggers it because no
  case pairs a start phrase with an end regex the start line satisfies, which is exactly why it will
  be trusted by whoever writes the case that does. `first = 1` is the fix. Needs a row (pointer:
  `tests/falsifiable-acs.test.sh`, `window()`).

- 2026-09-10 (develop, 0107) — **four open tickets carry `expects:` paths that the `0129` rename
  deleted, and nothing in the lifecycle re-points them.** `0132`, `0133`, `0134` and `0135` all name
  `skills/orchestrate/SKILL.md`, and `0134` also names `tests/orchestrate.test.sh`; both paths are
  gone since `bb8b778` renamed the skill to `sprint`. `queue` writes `expects:` at capture and only a
  claiming session rewrites it, so a rename leaves every unclaimed row downstream pointing at
  nothing — which both defeats the file-scope check (a path that cannot collide with anything) and
  is the reservation-of-a-nonexistent-path problem `0147` is already ranked for, arriving from the
  other direction. `CONCURRENCY.md`'s *A change that touches every file* rule says a rename rewrites
  the items of tickets that are open and unheld; that did not happen here. These still need a row —
  none was written, and a stage may only write the ticket it holds. Needs a row (pointer:
  items/0132, 0133, 0134, 0135 `expects:`; `references/CONCURRENCY.md`; items/0147).


- 2026-09-11 (verify 0052) — **a glob AC is unverifiable in a repo where sessions run concurrently,
  and `0052` is the ticket that predicted it about itself.** `AC7` reads "given the whole suite, when
  `for t in tests/*.test.sh` runs, then every suite passes". Over one pass the dirty set intersecting
  that glob changed three times as claim `9265` built `0133`: `tests/next.test.sh` at `400 passed, 13
  failed` (an in-progress TDD red — `393 passed, 0 failed` when pinned at `f3101f3` in a worktree),
  then `.claude/backlog/config.yml` changing underneath the pass, then `tests/sprint.test.sh`. Seven
  of eight ACs verified green with landed mutations; the eighth cannot be settled at all, so the
  ticket goes back at `next: verify` having had everything *about itself* proved. The buffer already
  carries the 2026-08-30 entry saying "a glob names no input" and naming this very AC; the build
  read it and left the glob. The lesson is not that the rule is missing but that **a rule which
  arrives as a note in Notes & decisions does not change the contract** — `FR2`'s list was never
  extended to carry the glob shape, so nothing asked at queue time and nothing refused at build time.
  Needs a row (pointer: items/0052 `AC7` and `FR2`; skills/queue/SKILL.md's acceptance-criteria step).

- 2026-09-11 (verify 0052) — **`verify` Step 7 is self-contradictory on which capture derives the
  advisory label.** It says the label is computed "from Step 2's capture, whatever the tree says now",
  and two paragraphs earlier requires a fresh verdict-time capture precisely because "clean at Step 2
  is not a statement about the tree at verdict time", citing `0085` where six files went dirty
  mid-pass. Read literally, a pass that starts clean can never be advisory no matter what appears
  later — which is exactly this pass, and would have closed a ticket on a suite run nobody can
  reproduce. The prohibition on "re-deriving" plainly means *do not relabel from the extra
  mutation-restoration read*, but the sentence does not say so. Needs a row (pointer:
  skills/verify/SKILL.md Step 7).

- 2026-09-11 (verify 0052) — **the declared `unit` command cannot be piped without silently
  discarding its verdict.** `config.yml`'s `for t in tests/*.test.sh; do "$t" || exit 1; done` puts
  the loop's exit status on the left of any pipe, so `… | tail -60` reports the exit code of `tail`
  — `0`, always — while also hiding 27 of 29 files' output. The config comment already warns that
  this line is fail-fast and that files should be run individually to attribute a red; it does not
  warn that the obvious way to keep the output readable destroys the signal entirely. Needs a row
  (pointer: `.claude/backlog/config.yml` `commands.unit`).
- 2026-09-11 (develop 0133) — **the script guards run the TEMPLATE copy, not the installed one, and
  editing only `.claude/backlog/<script>` reds nothing.** `tests/next.test.sh` sets
  `NEXT_SRC="$ROOT/skills/queue/templates/next"` and copies that into every fixture;
  `claim`/`close`/`handoff` presumably do the same. A correct implementation written into the copy a
  session has open reads as a guard wired to nothing — the run came back byte-identical, 13 failures
  before and after, with no cue that the edit had not been exercised. `backlog-scripts-installed`
  catches the divergence afterwards, but only once both copies are committed. Worth a line at each
  `*_SRC` saying which copy the harness runs (pointer: `tests/next.test.sh:23`).
- 2026-09-11 (develop 0133) — **two guards constrain a cost figure in skill prose, and no step sends
  a session to either before it writes one.** A `$` before a digit is banned outright
  (`money-in-skill-prose.test.sh`: the harness substitutes it as an invocation argument), and the
  obvious fix — bolding it as `**USD n.nn**` — enrols the figure in `sprint.test.sh` AC14's
  reconciliation against `MEASUREMENT.md`'s cost-per-closed-ticket column, which reds any derived
  figure that is not one of those. `develop` Step 3 says to grep the project's guards for *the
  mechanism you are about to introduce*, and quoting a number does not read as a mechanism. Needs a
  row, or a line in the skill's own house rules (pointer: `skills/sprint/SKILL.md`, `develop` Step 3).
- 2026-09-11 (verify 0052) — **the worktree `verify` Step 2 prescribes makes `tests/citations.test.sh`
  fail for an environmental reason that reads exactly like a red.** `config.yml`'s
  `conventions.path: ../ai-building-conventions` resolves from the repo root, so a worktree taken
  under the scratchpad has no sibling conventions directory and the guard reports *"no conventions
  directory resolved from config.yml — filename resolution not checked"*, exit 1, while the same
  file is green in the checkout. The fix is one `ln -s` beside the worktree, and it is the exact
  analogue of the `node_modules` symlink Step 2 already names — but the skill names only that one,
  and the whole point of the worktree is to let a session trust a red it did not cause. A session
  that stops here hands a correct ticket back to `develop` over its own scaffolding. Needs a row, or
  a clause at Step 2's worktree recipe naming the conventions directory alongside `node_modules`
  (pointer: `skills/verify/SKILL.md` Step 2, `.claude/backlog/config.yml` `conventions.path`).
- 2026-09-11 (develop 0144) — **`tests/measurement.test.sh` is red on `main` over a home-directory
  path published in a closed ticket's QA evidence table, and the leak is committed rather than
  in-flight.** The guard names
  `.claude/backlog/items/0052-acceptance-criteria-must-be-falsifiable.md:294` — an evidence row
  quotes a guard's own failure message verbatim, and that message embeds the absolute path of the
  conventions repo under `/Users/<name>/...`. Landed at `2be673f` (`Close 0052 [d3b6]`), present at
  every commit since, and **not yet pushed**, so redacting it costs nothing today and costs a
  history rewrite once it is. **This repo is public** (`CLAUDE.md`), and the redaction the guard
  itself accepts is `/Users/<name>/`. Two consequences beyond the leak: `tools/release`'s gate uses
  the FAIL-FAST `unit` command, so this reds the next release; and a `verify` session pasting a
  guard's real output into an evidence table is the ordinary way to satisfy the evidence rule, so
  nothing warns that the paste is the thing the privacy guard forbids. Needs a row — the redaction
  is another ticket's closed item file and `CONCURRENCY.md`'s *A stage writes only the ticket it
  holds* forbids this session doing it — and plausibly a line in `verify` Step 7 saying a pasted
  tally is redacted before it is written (pointer: `tests/measurement.test.sh`,
  `skills/verify/SKILL.md` Step 7).

- 2026-09-11 (verify 0133) — **a single-line mutation that stays green can mean redundancy rather
  than a gap, and `verify` Step 3 gives no way to tell the two apart.** `age_gate_crossed` carries
  two empty-buffer guards and `tally_age` a third; removing any ONE left 413/413 green, which reads
  exactly like the uncovered AC the step tells you to publish. Removing all three reddened AC1's
  case immediately. Three sweep runs at ~2min each to reach a fact one conjunction-aware pass would
  have found: after a silent mutation, widen to every line that could make the AC true before
  concluding it is unguarded (pointer: `skills/verify/SKILL.md` Step 3, item 0133).

- 2026-09-11 (develop, 0135) — **`tools/harvest-usage.sh --run` computed its FLOOR over the whole
  transcript directory, not over the run's sessions.** `report_run_bound` globs `*.jsonl` and takes
  `contexts[0]` as "the first turn's context, before any run state exists" — but on a shared store
  that is whichever session sorts first alphabetically, which is very often not one of the run's at
  all. The three figures `0039` AC13 asks for are a bound on *a supervised run*, and two of the
  three (FLOOR and GROWTH) were being read off unrelated sessions. Fixed in passing here, because
  `0135` FR3 added the `--session` filter the fix needed; recorded because the defect predates this
  ticket by two and nothing would otherwise say so. Needs no row — but it is the second time a
  figure in this repo has been computed over a **live store** rather than a pinned set, and the
  first (`MEASUREMENT.md`, repaired by `0051`) has a convention written about it that this code
  never had applied to it. Worth a sweep for the third (pointer: `tools/harvest-usage.sh`,
  `report_run_bound`; `MEASUREMENT.md`, *A date window is not a pin on a live store*).

- 2026-09-11 (develop, 0135) — **four open tickets still carry `expects:` paths the `0129` rename
  deleted, and the finding recording that has itself gone one sprint unactioned.** The 2026-09-10
  entry above (develop, 0107) names `0132`, `0133`, `0134` and `0135`; `0135` was corrected by this
  session because it claimed it, and the other three are untouched, because a stage may only write
  the ticket it holds. The compounding part is the shape, not the count: `./next develop` offered
  `0135` as `TAKE` with an `expects:` naming a path that **exists nowhere**, and a path that exists
  nowhere collides with nothing — so a stale `expects:` makes a row read as *clear* exactly when
  nobody can tell whether it is. That is the same failure direction as the held-file gap already
  recorded, arriving from the other side. Still needs a row (pointer: items/0132, 0133, 0134
  `expects:`; `.claude/backlog/next`, takeability's fourth test; `references/CONCURRENCY.md`,
  *A change that touches every file*).

- 2026-09-11 (develop, 0135) — **`develop` Step 5 tells a session to wait on a live whole-suite run
  with `pgrep -f <runner>`, and this project has no runner to name.** The suite is
  `for t in tests/*.test.sh`, so the only live process is `sh` running a file whose name changes
  every second; `pgrep -f 'tests/.*test.sh'` matches the loop's own children and races its own
  check. The rule is right and its mechanism does not exist here. What this session did instead was
  run the sweep in the background and read the output file, which answers "is it finished" without
  answering "is someone else running one" at all — the question the step actually asks. Needs a row
  (pointer: `skills/develop/SKILL.md` Step 5, the `pgrep` sentence; `CLAUDE.md`, *Tests*).

- 2026-09-11 (verify 0144) — **this repo keeps two copies of every backlog script, and the suites run
  the TEMPLATE, not the installed copy — while `CLAUDE.md`'s most memorable sentence says the
  opposite.** `tests/close.test.sh` sets `CLOSE_SRC="$ROOT/skills/queue/templates/close"` and copies
  that into each fixture, so a mutation applied to `.claude/backlog/close` lands a real non-empty
  diff, reaches a file that exists and is executable, and leaves the suite at `240 passed, 0 failed`.
  That reads as *this guard cannot be made to fail* — the exact verdict `verify` Step 3 tells a
  session to publish as a gap — when it means *you mutated the copy the harness does not run*.
  `CLAUDE.md` opens with **"The installed copy is what runs"**, which is true of skills and false of
  these scripts, so the document a session reads first points it at the wrong file.
  `testing-conventions.md` carries the general rule ("confirm the mutation reached the copy the
  harness runs") and nothing here names which copy that is. Caught only by noticing that the id-only
  mutation reddened nothing while the same mutation applied to the template reddened two assertions.
  Needs a row (pointer: `tests/close.test.sh:25` `CLOSE_SRC`, `tests/handoff.test.sh`; `CLAUDE.md`,
  *This project is the tool its sessions are running*).

- 2026-09-11 (verify 0135) — **"the cell is populated" is not "a figure was estimated", and an AC1
  guard written the first way cannot see the red AC1 names.** `tests/sprint-ledger.test.sh`'s
  `paired()` asserts a non-whitespace estimate cell beside a numeric actual. `tools/sprint-ledger.sh`
  defaults three of its four `--estimate-*` figures to `0`/`0.00`/`unsourced`, so a `record` run with
  a flag omitted writes a fabricated estimate that satisfies `paired()` exactly. Blanking the cell
  outright reddens four assertions; filling it with a lie reddens none. The generalisable half is
  that a guard for *a figure was supplied* has to anchor on the **source**, which a default cannot
  forge, rather than on the figure, which it trivially can. Needs a row (pointer:
  `tests/sprint-ledger.test.sh` `paired()`; `tools/sprint-ledger.sh` `parse()` defaults;
  `testing-conventions.md`, mutation at the AC's altitude).

- 2026-09-11 (verify 0135) — **the repo's whole-project gate is red on a committed file, and the
  release gate is fail-fast over the same line.** `tests/measurement.test.sh` reports
  `128 passed, 1 failed`: its privacy guard finds a home-directory path published in
  `.claude/backlog/items/0052-…md:294`, landed at `7fdd367` by that ticket's own QA-evidence table —
  a verdict quoting a tool's output verbatim, where the tool prints an absolute path. So the shape
  `verify` Step 7 now asks every session to write into its item is itself a route for a
  home-directory path into a public repo, and `tools/release` step 5 runs `commands.unit`, which is
  `|| exit 1` — the repo currently cannot release. Nothing to do with `0135`; found because
  `qa_level: unit` runs every file. Needs a row (pointer:
  `.claude/backlog/items/0052-acceptance-criteria-must-be-falsifiable.md:294`;
  `tests/measurement.test.sh` privacy guard; `references/REPORTING.md`; `CLAUDE.md`, *Tests*).

- 2026-09-11 (develop, 0135) — **`CONVENTIONS_CORE.md`'s *use types* is a principle, and every tool
  in `tools/` is `sh` wrapping an inline `python3` heredoc with no hints.** `sprint-ledger.sh`,
  `harvest-usage.sh`, `classify-turns.sh` and `cost-by-category.sh` are all the same shape.
  `0135`'s build note called the deviation "a preference rather than a principle" and `0135`'s verify
  pass correctly rejected that reading — the core file enumerates *use types* among the principles,
  which no project may override downward. But the question is which of two things is true of the set:
  the four tools are owed type hints, or `sh`-wrapping-`python3` is a shape the principle was never
  written for and the conventions repo should say so. Retyping one tool inside the ticket that
  happened to touch it makes that one the outlier and settles nothing, which is why the verify pass
  declined it and this session did too. **This still needs a row; no row exists.** (Pointers:
  `tools/*.sh`; `CONVENTIONS_CORE.md`, *Code* → *Use types*; items/0135 verify verdict 2026-09-11.)

- 2026-09-11 (verify 0045) — **`./next --help` counts the collision test as the third of four, and
  it is the fourth.** The takeability paragraph lists four tests — stage, `blocked_by`, the item's
  claim, the held-file intersection — then says *"A row held out on that **third** test is reported
  as COLLIDES"*. It was the third when `0045` wrote it; `0140` inserted the claim test ahead of it
  at `7f54025` (2026-09-09) and renumbered nothing. Nobody is misled today because only one test
  reports COLLIDES, but the number is the only thing tying the paragraph to the list, and the next
  insertion breaks it silently in the same way. The generalisable half: **an ordinal into a list in
  the same paragraph is a cross-reference no guard reads**, and prose here is the product — name
  the test rather than its position. Needs a row (pointer: `skills/queue/templates/next` `usage()`,
  the *"Takeable means four things"* paragraph; `.claude/backlog/next` takes the same fix under
  `tests/backlog-scripts-installed.test.sh` AC2).

- 2026-09-11 (verify 0045) — **one repo-wide red, two opposite verify verdicts a day apart, decided
  by whether the ticket happened to write a whole-suite AC.** `tests/measurement.test.sh`'s privacy
  guard is red on `.claude/backlog/items/0052-…md:294` (already parked above, verify 0135). Verify
  `0135` recorded it *"PASS for this ticket"* and closed; verify `0045` must record it **FAIL**,
  because `0045` AC8 says *"Given the whole suite … then every suite passes"* in as many words and
  ticking it would assert something false. Same red, same day, same repo, and neither session was
  wrong under its own contract. `verify` Step 5's fifth shape covers *a red whose cause is another
  ticket's landed change* and routes it to `develop` — which here means a session holding `0045`
  editing a **closed** ticket's file to clear a defect that already owes its own row. The
  generalisable half is a gap between two rules that each read complete: **`queue` may write an AC
  over a whole-project gate the ticket does not own**, and `verify` has no branch for *green on its
  own contract, blocked on a foreign committed red* — the honest state is `blocked_by` a row that
  does not exist yet, which no stage is scripted to create. Needs a row (pointer: `skills/verify/SKILL.md`
  Step 5 fifth shape and Step 2's whole-project-gate paragraph, which handles the *dirty* case and
  not the *committed* one; `skills/queue/SKILL.md` acceptance-criteria step; `0045` AC8).

- **2026-09-11 — `claim`'s exclusive-claim detector reads any `*` in an `expects:` entry as
  `expects: "*"`, so a legitimate glob declares a whole-tree claim.** The test is
  `if ($0 ~ /\*/) { print "yes"; exit }` over each bullet — it asks whether an asterisk appears
  anywhere in the entry, where the rule it enforces is about an entry that *is* `"*"`
  (`references/CONCURRENCY.md`, *A change that touches every file takes an exclusive claim*).
  Probed while building `0147` FR3, which requires a glob to resolve like any other path: a fixture
  declaring `expects:\n  - tests/*.test.sh` with one other ticket held was refused with *"its
  expects: declares \"*\", an exclusive claim over the whole tree"*. The failure is quiet in the
  worst direction — it reads as a correctly-enforced precondition, and the session's honest
  response is to wait for a holder that has nothing to do with it. `0147` is scoped to the
  missing-path report and deliberately did not touch this. Needs a row (pointer:
  `skills/queue/templates/claim` and `.claude/backlog/claim`, the `exclusive="$(awk ...)"` block;
  `tests/claim.test.sh` 0067 AC7 cases, which pin the refusal and its scope but use `"*"` bare and
  so never reach the over-match).

- **2026-09-11 — a `verify` send-back names one constraint, and `develop`'s re-entry reads that
  constraint as the whole scope, so a sibling instance of the identical defect in the same function
  survives the bounce.** `0135` was sent back for `parse()` defaulting the estimate flags, which
  wrote a fabricated figure into a committed public ledger. The re-entry fixed exactly that and
  nothing else — correctly, by the letter of `skills/verify/SKILL.md` Step 5 (*name the constraint,
  never a menu*) and `skills/develop/SKILL.md` Step 2 (*this section **is** the specification on a
  re-entry*). But the same file's `harvest()` swallows a non-zero exit from `harvest-usage.sh` and
  returns `(0.0, 0)`, so `record` against a missing transcripts directory appends
  `| usd | 9.99 | 0.00 |` and `observed USD 0.00`, carrying `harvest-usage.sh over 1 session id(s)
  @ <stamp>` as the source of a number harvest-usage.sh never produced — the same fabrication, the
  same file, the other column, and a *false* citation rather than a missing one. Two passes of this
  ticket each looked straight at `harvest()` and neither examined it, because the first was writing
  a constraint and the second was discharging one. The generalisable half: a send-back is a
  *minimum*, and neither skill says so — `verify` could ask for the **defect class** beside the
  instance where one is visible, and `develop`'s re-entry could be told to sweep the enclosing
  function for siblings before declaring the constraint discharged. Needs a row (pointer:
  `skills/verify/SKILL.md` Step 5, *Name the constraint, never a menu*; `skills/develop/SKILL.md`
  Step 2's re-entry paragraph).

- **2026-09-11 — a structural guard that fires only inside its last branch cannot see that branch
  absent.** `tests/sprint-ledger.test.sh`'s AC6 awk reports a ratio missing a stamped side from
  within the `/^ *denominator /` rule, so deleting the numerator line reds (the denominator rule
  still runs and finds `n == 0`) while deleting the **denominator** line is invisible: nothing runs,
  nothing prints, `53 passed, 0 failed`. The asymmetry is not obvious from reading the awk, and it
  is the shape every "A must be followed by B and C" check in this repo takes. The general rule is
  that such a check needs an `END` block, or a reset that reports the pending record when the next
  anchor or EOF arrives. Found by mutation while verifying `0135`; named in that ticket's send-back
  so it is fixed there, parked here because the shape is repo-wide (pointer:
  `tests/sprint-ledger.test.sh` `RATIOBAD`; `testing-conventions.md` on guards that cannot fail).

- 2026-09-12 (verify 0147) — **an acceptance criterion whose fixture is another live ticket's
  frontmatter can be stale before it is written, and nothing in the loop can see it.** `0147` AC5
  asked that `./claim 0075` name `tests/skill-prose.test.sh` as not existing. It cannot, for two
  independent reasons: `0075`'s `expects:` no longer carries that path, and `0075` is `done`, so
  `claim` exits 1 at `no row for 0075 in QUEUE.md` before any report. The path was corrected by the
  **same develop park that filed `0147`** — the criterion was false at the moment its author wrote
  it. A fixture built inside a test is checked by running the test; a fixture that is another
  ticket's file is checked by nobody, and it moves. Two passes paid: `develop` built five of six ACs
  and recorded the sixth as unbuildable, and this `verify` cannot close a ticket whose
  implementation is sound and fully mutation-tested. Cheap rule if it recurs: an AC citing another
  ticket's mutable frontmatter either pins those bytes into a fixture or is written against one.
  Needs a row (pointer: `skills/queue/SKILL.md` acceptance criteria; `tests/falsifiable-acs.test.sh`;
  items/0147 AC5).

- 2026-09-12 — **`--drive`'s develop gate is still formed on `expects:`/parent overlap, which is no
  longer what `develop`'s prose says its batching condition is.** `0059` settled develop's condition
  as *takeability at the stage* and demoted shared scope to "why a batch pays more"; `gate_from` in
  `.claude/backlog/next` still groups by parent-or-shared-file, so the tool and the skill now
  describe different develop batching units. That is precisely the tool/prose disagreement `0132`
  existed to remove, surviving on the other side of the gate. It may well be correct — a `--drive`
  gate is a *conflict* unit and a human session's batch is a *cost* unit, which is an argument for
  two different rules — but nothing anywhere says so, so the next reader meets two conditions and no
  reconciliation. `0132` could not touch it: "changing how develop gates are formed" is its stated
  Out of scope. Needs a row (pointer: `.claude/backlog/next` `gate_from`; `skills/develop/SKILL.md`
  batching paragraph; items/0059 FR1, items/0132 Out of scope).

- 2026-09-12 — **`assert_contains "DISPATCH  verify 0102"` cannot tell one dispatched row from a
  batch, so every pre-`0132` dispatch assertion in `tests/next.test.sh` is green under
  over-batching.** `DISPATCH  verify 0102 0103 0104` contains the expected substring. It did not
  matter while the script only ever printed one id; it does now. `0132` added an `assert_eq` for its
  own cases and left `0131`'s alone rather than rewriting another ticket's criteria, and `0132`'s
  own cases do cover the regression — so this is a redundancy question, not a hole. Cheap rule if it
  recurs: an assertion about a *list* is an equality on the whole line, never a containment of one
  member (pointer: `tests/next.test.sh` 0131 AC1/AC3; `testing-conventions.md`, assert membership
  never cardinality).

- 2026-09-12 — **`0132` FR4 tells every batched verify to run the suite file-by-file, and in this
  repo that run exceeds an agent's default 120s tool timeout — the rule as written gives no
  recovery.** 30 files in `tests/`; `for t in tests/*.test.sh; do "$t" || true; done` ran past the
  timeout and had to be re-run backgrounded, then waited on. `skills/verify/SKILL.md` names the
  sentinel-plus-`until grep -q` recipe only in Step 3, for a quantifier sweep, so a session meeting
  the timeout on FR4's reporting run has to rediscover it — and the obvious wrong recovery is to
  fall back to the fail-fast `config.yml` line, which is exactly the `0084` masking FR4 exists to
  stop. Needs a row (pointer: `skills/verify/SKILL.md` Step 2 batch-reporting paragraph and Step 3's
  sentinel recipe; `.claude/backlog/config.yml` `commands.unit`).

- 2026-09-12 — **`develop` Step 2 tells you to probe an external tool's interface before building on
  a ticket's claim about it, and the same probe is what tells a refusal from a measurement — but
  nothing says so.** `0135`'s verdict required `harvest()` to `die()` on a failed harvest while
  leaving the empty store recording `0.00`. The two are one character apart in the calling code and
  opposite in meaning, and only a three-second probe separates them (missing dir → exit 2, stderr;
  empty dir → exit 0, `TOTAL … 0.00`). Step 2's probe paragraph is framed entirely around a *stale*
  claim ageing out; the case where the claim is current and the probe is what defines the fix's
  boundary is not named. Cheap addition, and the failure it prevents is a refusal widened onto a
  real measurement (pointer: `skills/develop/SKILL.md` Step 2, *the same holds for any claim a
  ticket makes about an external tool's interface*).

- 2026-09-12 — **A guard against a subprocess's failure mode may be unreachable through the real
  subprocess, and no skill names the stub-copy recipe that reaches it.** `sprint-ledger.sh` resolves
  `harvest-usage.sh` relative to its own directory, so the "exit 0 with unparsable stdout" swallow
  cannot be produced by the real tool at all. Copying the tool under test beside a stub sibling is
  two lines and keeps the copy fresh from the original each run, but a session that does not think
  of it will guard the reachable half and leave the other as an assertion nobody ever runs — which
  reads identically to coverage. `testing-conventions.md` covers mutating *the copy the harness
  runs* and not deliberately running a copy to reach an unreachable path (pointer:
  `testing-conventions.md`, *prove a new guard fails*; `tests/sprint-ledger.test.sh` no-TOTAL case).

- 2026-09-12 — **An error message's own readability can make its guard unfalsifiable, and the guard
  is what catches it.** `sprint-ledger.sh`'s first refusal quoted the unparsable output as
  `" / ".join(stdout.split()[:20])`, shredding every phrase across word boundaries, so an assertion
  on text the stub really had printed could not match. The correct reading is that the *message* was
  wrong, not the assertion — but the cheaper move is to loosen the assertion to a word, and that
  yields a guard which passes on a message no human can act on. Worth a line wherever the "assert
  the message, never the status" rule already sits: a message you cannot write a phrase assertion
  against is a message nobody can read (pointer: `testing-conventions.md`, *`exits non-zero` is
  satisfied by the silent refusal*).

- 2026-09-12 — **`qa-level-once` guards a duplicated `**Level:**` line but not a stale
  `**Why that level:**` rationale, and a prior verdict read the silence as agreement.** `0135`'s
  frontmatter was raised to `qa_level: unit`; its QA plan still opens *"no runner applies"*, which is
  the argument for `verify`. The item declares the level exactly once, so `tests/qa-level-once.test.sh`
  is green and `verify` Step 2's drift rule — written against two *declarations* — has nothing to
  fire on. A verify session reading the prose first can reasonably run the lower level and never
  learn the frontmatter disagreed. Two prior verdicts recorded *"frontmatter and QA-plan prose agree;
  no drift"* when the rationale had in fact never been updated. The cheap fix is for whoever raises a
  level to rewrite the rationale in the same edit, and for the guard to notice a rationale naming a
  different level than the frontmatter (pointer: `skills/verify/SKILL.md` Step 2, *the frontmatter
  field is the authority*; `tests/qa-level-once.test.sh`).
- 2026-09-12 — **`retro` Step 1 still says "Leave the work entries where they are" after 0060 made it the terminal sweeper.** Step 4 says no entry survives the pass that read it and that a pure unit of work is filed, not handed back; a retro following Step 1 literally leaves read work entries in the buffer, re-opening the cost 0060 closed. Also, three sessions wrote "a queue pass should withdraw 0080" and none did — `design` settled it by withdrawing, which its Step 4 does not name as an outcome (pointer: `skills/retro/SKILL.md` Step 1 vs Step 4; `skills/design/SKILL.md` Step 4; items 0060, 0080).
- 2026-09-12 — **`develop`'s hand-back-to-design branch says "release the claim and stop", but the
  checks that reach it run before the claim exists — and `handoff` will not move a row without a
  token.** Step 2's two staleness rules (a figure a ticket quotes about a file it does not own; a
  missing *decision* rather than missing detail) are deliberately placed at selection and
  contract-restatement, and Step 1 says explicitly to run the staleness grep *before* claiming. On
  `0134` the NFR's false claim about another ticket's tool was visible from a five-minute read of
  `tools/sprint-ledger.sh`, with nothing claimed. The branch's instruction then has no correct
  action: there is no claim to release, and `.claude/backlog/handoff` requires `<id> <token>` and
  refuses a token that is not yours, so the only supported route to `next: design` is to claim a row
  purely in order to hand it straight back. That is a real claim and a real commit for a session that
  will write no code, and it reads in the log as work started. Either the branch should say to claim
  first and name why, or `handoff` needs a path for an unclaimed row (pointer: `skills/develop/SKILL.md`
  Step 2, *if what is missing is a decision rather than detail*, and Step 1, *run the staleness grep
  before you claim*; `.claude/backlog/handoff` usage).

- 2026-09-12 [->0150] (design) — **`design` claims only at Step 4, so the whole Step 2–3 pass runs on an
  unheld row, and on 0134 another session (`d08c`, commit `8d38048`) claimed it mid-pass.** `./next
  design` offered 0134 as `TAKE`; this session read the ledger tool, the run-log schema and the
  measurement convention, reached a decision, and found the row `in-progress` only when it went to
  write — so Step 4's claimed path applied and the pass could only be handed back. Two design
  sessions reasoning over one ticket is `develop`'s FR5 failure in the stage that has no claim step
  before its spend. The 2026-09-10 entry above asks Step 4 to claim; this asks for it at Step 1, or
  for `./next design` to skip a row another design session has been offered (pointer:
  `skills/design/SKILL.md` Step 1 and Step 4; `references/CONCURRENCY.md` *Claim tokens*).
- 2026-09-12 (queue) — **`queue` Step 2's re-specify path says to un-tick touched ACs but is silent on a criterion that is *dropped*: renumber or keep a gap.** 0147 dropped AC5 and kept AC6's number, so its QA evidence and notes still resolve, reasoning from the withdraw rule for ticket ids. Nothing states that for AC ids, and `close` ticks by line form, not sequence, so a gap is harmless but undecided (pointer: `skills/queue/SKILL.md` Step 1 *Re-specify*; item 0147).
- 2026-09-12 (develop) — **`design` rewrote an item's acceptance criteria as a numbered list, and nothing in that stage checks the one form `close` can tick.** 0083's ACs landed as `1. **Given**…` in `470ba67`, which took `tests/item-ac-form.test.sh` red on a held item until `develop` converted them. The guard caught it, but only at the next whole-suite run and on another stage's time; `design` Step 4 writing ACs is the place a checkbox reminder or a run of that guard belongs (pointer: `skills/design/SKILL.md` Step 4; `skills/queue/templates/item.md`; item 0083).
