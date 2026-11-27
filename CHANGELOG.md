# Changelog

What a session running these skills will do differently, by released version. It is written for
whoever installs this plugin: the sessions that run it, and the people who drive them.

**What to do:** update the plugin install and start a new session, since skills resolve once at
session start. An entry says so where anything more is needed.

Each entry is written by the `verify` session that closed its ticket, through `./close --note` — or
by `develop` where the ticket's criteria require the note before the close, and then verify passes
no `--note` — and leads with the behaviour; a ticket number in parentheses is provenance. `tools/release --bump` moves
`## Unreleased` under the version it bumps. Each version ends with `### Did not change`, written by
the release session, because only a whole-release view can say it.

## Unreleased

## 0.9.51 — 2026-11-27

- `queue` and `design` now say that `./next --ac-digest <id>` prints the whole `ac_digest:` line, key included, so it replaces the item's line; substituting it after the key doubled the key.
- `queue`'s *Merging tickets into one outcome* now says to carry an absorbed ticket's NFR rows in the template's current shape, adding the *How it would red* cell a row written before that column lacks.
- New `./capture <draft> <top|above:<row-id>|below:<row-id>> [--ranking <file>]` mints the id from the disk, writes the item, stamps `ac_digest:`, inserts the row, appends the ranking and commits, as one call; `./capture --restamp <id>` re-stamps and commits an unclaimed item's edited criteria. `queue` Step 2 (Add), Step 1 (Re-specify, Amend) and Step 3 (the placement), and `retro` Step 4 (Filed) now call it instead of minting and editing by hand.
- New `./rank <id> <top|above:<row-id>|below:<row-id>> [--ranking <file>]` moves one row, appends the reasoning to `RANKING.md` and commits, refusing a row in progress. `queue` Step 4 (Rerank) now calls it instead of two hand edits.
- New `./withdraw <id> <reason> [--into <absorbing-id>]` marks the item withdrawn, removes its row, re-points every open `blocked_by:` naming it and commits, refusing a claimed item. `queue` Step 1's *Withdrawing a ticket* and *Merging tickets into one outcome* now call it.
- New `./park "<entry>" [--repo <checkout>]` appends one dated `FINDINGS.md` entry and commits it, refusing an entry holding a home path when the destination repo is public. The park step of `queue` (Step 7), `develop` (Step 7), `verify` (Step 6), `design` (Step 5), `prototype` (Step 8) and `retro` (Step 6), and the supervisor's park in `sprint` Step 9, now call it instead of a by-hand lock.
- New `./drain <date> <removed|marked:<row-id>|held> [<row-id>] [--line <n>]` removes, marks or holds exactly the `FINDINGS.md` entry `./next --findings-list` names, and commits. `queue` Step 5 (removing and marking swept entries) and `retro` Step 4 (emptying the buffer, *Held*) now call it.
- `queue` Step 7 and `retro` Step 6 now tell a session whose commit lands in a public repo to run that repo's privacy guard, `tests/measurement.test.sh` in this plugin's, before reporting. `develop` Step 1 and Step 5 and `verify` Steps 1 and 5 no longer describe a by-hand claim, close or hand-off, and `references/CONCURRENCY.md` names the writes still made by hand under the lock.
- `./handoff` with status `ready` on an item whose `blocked_by:` still names an open ticket now writes `blocked` to the row and the item, as the cache `next` derives, and says so; `--drift` no longer reports the row and `--drive` no longer escalates on it. `blocked` is still refused as an argument (0242 S4).
- `./next --ac-digest` now ends a criterion's text at the first line that is neither blank nor indented, so a note written at column 0 below the last criterion no longer changes that criterion's digest, and an indented line after a blank one still counts. `--check`, `close` and `--drift` accept a stamp in either the new or the old form, key by key, so upgrading reports no drift; every new stamp is written in the new form (0242 S5).
- `./reopen` on an item recording `close_by: develop` now writes `close_by: verify` in the same commit and names the change in the dated reopen note, so the verify pass the reopen is for can `./close` it instead of being refused as the wrong stage. `close_by: verify`, or no key, is left as it was (0242 S6).
- `./next --drift` and `--drive` now report an open row whose `expects:` names a path that exists nowhere in the repo, one line per entry, unless the entry carries a `# new` comment; a glob counts when it matches at least one path. **After upgrading, `--drive` escalates on every open row whose `expects:` names a missing, unmarked path: correct the path, or mark it `# new` if the ticket creates it** (0242 S15).
- `./claim`, `./handoff`, `./close` and `./reopen` now refuse, before taking the lock and writing nothing, when the checkout is not on the branch the backlog is shared on, or has a detached `HEAD`. That branch is `shared_branch:` in the backlog's `config.yml` if set, else `origin/HEAD` if it is a symbolic ref, else `main`. **After upgrading, a project that shares its backlog on a branch other than `main` and has no `origin/HEAD` needs one `shared_branch: <name>` line in its `config.yml`**, or its first claim refuses and names that line (0242 S7).
- A `design` decision that changes what another item must say now records it under `### Sibling consequences` in the item it holds and hands that item to `queue`, never editing the sibling; `queue` re-reads each sibling, folds the change in (reopening a `done` one), or sends the decision back to `design`. `./next --drive` dispatches that queue pass on an in-scope row rather than escalating it as a stale contract, under the same `bounce_max` (0242 S13).

## 0.9.50 — 2026-11-27

- `next --drive` re-dispatches `develop` when a verify fail hands a row back to `next: develop`, instead of exiting 4, printing a `NOTE` that names where verify's diagnosis is. The bound is `bounce_max:` in `config.yml` (absent means 2; `0` restores escalate-on-every-bounce), counted from the supervisor's `--bounces <id>=<n>`; past it the bounce escalates (0234).
- `next --drive` dispatches a `queue` repair when a verify or develop session hands an in-scope row to `next: queue`, under the same `bounce_max` and count; an out-of-scope row, or one with no `--scope`, still escalates as a stale contract. A re-entry into `design` spends the same allowance (0234).
- `/queue`'s Re-specify tells a repair (correcting a contradictory, unmeetable or drifted criterion of an outcome the ticket keeps) from a narrowing (removing or weakening an AC, moving scope out); a narrowing in a session with no person in it is not written but handed off as `waiting` (0234).
- `/sprint` is run to drive toward an outcome, not to a date, a time or a budget: no sprint-wide budget or deadline is proposed or enforced (the person's direction, 2026-11-26), superseding 0.9.49's `budget_usd`/`deadline` envelope. Each stage session carries a projected cap, shown to the person in the proposal before dispatch, as a runaway catch; the supervisor may raise one or add a session the outcome needs, logging `cap_raised` first. A cap kill is still an escalation (0234).
- `tools/sprint-ledger.sh envelope` no longer stops a run on budget or deadline: it is an account-headroom gate printing `CONTINUE`, or `WAIT … resume after <iso>` (exit 3), from the run log's `headroom` readings, and stops nothing when headroom is not visible. `/sprint` dispatches stages with `--output-format stream-json --verbose`, reads the outcome through the new `outcome --stream` mode and logs `reading --stream`'s `headroom` line after every stage; a `WAIT` waits and resumes, never ending the run (0234).
- One develop session at a time, in every project: `./claim` refuses a develop claim while another develop row is held under a different token, naming the holder (a gate's later rows pass the first claim's token), and `next --drive` waits (exit 6) instead of dispatching develop beside a running develop. Design and verify still run beside it (0234, was 0137).
- `/sprint` Step 3's marker heartbeat stops with `pkill -P "$BEAT"; kill "$BEAT"`, so it no longer orphans the `sleep` its loop was blocked on (0234, was 0170).
- `tools/release` updates every install recorded for the plugin at its own scope — `user`, and each `project` or `local` entry from its own directory — where it used to run one bare `claude plugin update` that, inside a checkout enabling the plugin, moved only that project's entry. `tools/release verify` checks every recorded install and fails naming the scope and path of any that is stale; an entry whose project directory no longer exists is skipped and reported.

## 0.9.49 — 2026-11-19

- `design` hands a decision-only ticket (`qa_level: verify` or `review`, nothing to build) to `verify` rather than `develop`.
- The `config.yml` template's `review: checklist:` example now points inside `.tickets/`, the only place `queue` commits, so a `review` ticket's checklist can be created by the stage that files it.
- A ticket can be one outcome worked across many sessions: `templates/item.md` gains a `## Progress` section of ordered slices (each `— discharges AC…`, `— discharges none` or `— unspecified`) and a `slice:` field. `./handoff <id> <token> <stage> --slice S<n>` ends a leg: develop → develop ticks AC-less slices, develop → verify ticks nothing, and a verify pass handed back with `--slice` ticks the leg. It refuses a leg holding an AC on develop → develop, an `unspecified` slice (naming `design`), and any dirty path in the item's `touches:`. `./close` on a sliced ticket refuses while an earlier slice is unticked and ticks the closing leg with the ACs. A ticket with no `## Progress` behaves as before (0231).
- `develop` works a sliced ticket a leg at a time: it commits each slice as it lands, continues into the next only when that slice shares open files and the leg is short of the break-even `MEASUREMENT.md` prices, and reports `PROGRESSED` (outcome verdict `progressed`, with `slice: {done, next}`) when a leg of AC-less slices ends with slices left (0231).
- `verify` checks a sliced ticket once per leg — that leg's ACs plus the whole suite, ticking no AC — and hands a pass back with `--slice`; the leg holding the last slice is the closing verify and checks every AC (0231).
- The stage outcome schema accepts verdict `progressed`, which requires `slice.next`, and `tools/validate-json-schema.py` supports `if`/`then`/`else` (0231).
- `next --drive` routes legs: after a leg ends it dispatches the next leg's `develop` or the leg's `verify` instead of escalating, finishes a started sliced ticket before opening another row, and names every row one develop gate built in a single `DISPATCH verify` line (0231).
- `next --drive` no longer halts a run on a `waiting` row while other in-scope work is takeable — it prints a `NOTE` and moves on, exiting 4 only when nothing in scope is — and steps over out-of-scope `waiting` and `next: queue` rows, so they no longer mask the findings gate's exit 5. A develop gate or leg waits (exit 6) on a running design session holding any of its files in `touches:` or `expects:` (0231).
- `./handoff … waiting` refuses a `## Waiting on` that is not a whole decision brief — Outcome, Where it stands, What needs you, Options with two or more `#### Option` entries, Recommendation, What to do, If no answer — naming what is missing. Rows already waiting are not re-checked, and `./next --waiting` prints the brief's *What needs you* line (0231).
- `/sprint` sizes a run by a budget and an end time the person confirms instead of a three-to-five ticket count, recorded as `budget_usd` and `deadline` on `scope_confirmed`, and asks `tools/sprint-ledger.sh envelope` before every dispatch, ending at a clean boundary on `STOP`. Every outcome that leaves a row waiting sends a one-line notification pointing at the brief, and every escalation is written as that brief (0231).
- `/design`, run where no one can be asked, prepares a decision that turns on taste or is an architecture or security choice — spikes, options, a recommendation as a decision brief — and leaves the row `waiting`; it never records the decision (0231).
- `/queue` amends the open ticket whose outcome new work serves before minting an id, gains a Merge operation (withdraw each absorbed ticket with a pointer, quote reported evidence verbatim, re-point `blocked_by:`), and waits for a claimed ticket's leg to release rather than amending it (0231).
- The sprint supervisor's lock-age check now works on Linux: it reads the lock's mtime with GNU `stat -c %Y` first and falls back to BSD `stat -f %m`, where it used to error before deciding aged or fresh (0232).

### Did not change

`retro` and `prototype`, `./claim`, `./migrate` and `tools/release` are as they were. A ticket with no `## Progress` section is worked, handed off and closed exactly as in 0.9.48, and rows already `waiting` are not re-checked against the new brief rule.

## 0.9.48 — 2026-11-08

- `verify` re-syncs a backlog's stale scripts when `./next` answers `unknown stage: --ac-digest`, rather than recording the digest as unverifiable and passing.
- `sprint` validates the last stdout line opening `{` rather than the whole stream, so a CLI warning printed ahead of the outcome (the sign-in expiry notice) no longer reads as a failed stage, and relays that warning to the person. Dispatch helpers live under `.tickets/runs/` beside the captures, so a paused run can still dispatch.
- The ticket directory is `.tickets/` at the repo root, named for the whole ticket system it holds — the backlog is `QUEUE.md` inside it. `.backlog` (0.9.44 to 0.9.47) is now a second legacy location beside `.claude/backlog/`: the scripts work at either until 2026-12-31, printing one stderr line naming that location and `./migrate`, and refuse a repo holding more than one. `./migrate` moves either to `.tickets/` as one commit, and no longer counts a `claimed_by:` left on a `done`, `withdrawn` or `rejected` item as a claim. `next` resolves a tools repo's findings buffer at `.tickets/` first. **Install this release on every machine that works a repo before migrating it**, and check with `tools/release verify` (0228).

## 0.9.47 — 2026-11-01

- `retro` has a fifth disposition, *held*: a finding that needs work but has not been confirmed by a project that uses these tools moves to `.backlog/FINDINGS-HELD.md` instead of becoming a row. Nothing counts, reviews or expires that file; a later pass greps it when a confirmed finding matches and files the two together. Both `retro` and `queue`'s findings sweep now file a row only on that confirmation, or when the user asks.
- This repo's own sessions no longer add guards that grep prose: a rule that must hold exactly goes in a script that refuses, and an existing prose guard that reds on a correct rewording is deleted rather than re-anchored (`CLAUDE.md`, *Tests*; `testing-conventions.md`).

## 0.9.46 — 2026-10-31

- prototype now starts generic and loads the company profile once the work is clearly a company project, then settles a Step 0 before drawing anything: the base product (or none, for a net-new idea), design system, product needs, tech stack, release phase, scope, and the tickets the prototype must match.
- prototype now builds every level mobile-first with nothing on screen without a reason, uses the design system first, calls out any departure from it or from the product's rules in the ticket, keeps the prototype and its tickets in lock step, and asks before pressure-testing load or volume.
- prototype level 2 now says whether it starts from a base product (copying that product's shell and patterns) or net new (the template); level 3 builds in the base product's own stack rather than assuming Angular.

## 0.9.45 — 2026-10-28

- The citations guard now resolves the conventions path from the main checkout, so running the suite in a worktree outside the checkout's parent directory (a temp directory, say) no longer reports a conventions red that no ticket owns (0189).
- The rule against rewriting `QUEUE.md` by hand now names in-place stream editing (`sed -i`, `perl -i`) and whole-file rewrites through a temp file as the same prohibited class as `Write`, says a script is an exception only by being one process holding the lock across the rebuild and its commit, and gives the safe shape for an unavoidable multi-row rewrite under the lock: keep it only if the diff is exactly the intended change, abandon it otherwise (0065).
- Where a file cannot have one writer, the session is the single writer: rows sharing a file are worked by one session (one develop gate, or one after another), a stage where every takeable row collides is a designed wait — claim nothing, report the holders, stop or take non-colliding work at another stage — and a `develop` session never opens or widens `touches:` into a `verify`-held file mid-session (`references/CONCURRENCY.md`, *The working tree is shared too*; 0050).

## 0.9.44 — 2026-10-27

- `sprint` reads an item's `close_by:` before re-verifying a ticket its develop session closed: a `close_by: develop` close is the declared exception, not self-certification. It waits out a drift exit on a row a running design session holds, and a resume prompt asks the session to check its claim and tree rather than asserting them.
- `design` cross-checks the criteria it writes against each other and the tree before handing off: no AC may forbid what an FR requires, and a detector an FR specifies is run over the tree before an AC requires the tree green.
- `verify` closes without `--note` when `develop` already wrote the ticket's note under `## Unreleased` because the criteria required it before the close.
- `tests/backlog-scripts-installed.test.sh` now fails when an embedded awk program's closing line carries anything after its quote but a `)`, whitespace and a double-quoted argument, or nothing, and when a line inside such a program begins with `"` or `)`. An apostrophe pasted at the head of an awk body line used to break `close` under a green guard; rewrap a body line that trips the second rule (0139).
- A helper copied between backlog scripts or test suites is now a declared copy, wrapped in `# copy-begin: <name>` / `# copy-end: <name>` lines in place of the old "Change one, change N" comments. A session editing a marked block must edit every copy: `tests/declared-copies.test.sh` reds on any copy that differs and says where they all are, and it also reds on a function defined in two or more script templates with any definition outside a marked block. `next`'s header-reading helper is renamed `name_row_column`, since it is not a copy of `claim`'s and `handoff`'s `column_named` (0146).
- `close` and `handoff` now report scope on a claim whose `touches:` is empty, which is the normal shape for a `verify` or `design` pass: every path the pass changed outside backlog bookkeeping is named as undeclared, or the report says only bookkeeping changed. `touches: "*"`, inline or as a list entry, prints as the exclusive claim covering every path. Only commits naming the ticket id or carrying its `[token]` are counted, and the report says how many others it left out. `claim` now tells a non-building stage that `touches:` stays empty rather than asking it to fill the field (0145).
- `develop` Step 4 now requires a refusal a ticket adds to a backlog script template, which a skill change in the same ticket satisfies, to be self-sufficient: its stderr names what is missing and the fix, it refuses before anything is written, and the ticket's test runs the script into it — so a session whose installed skill predates the refusal can still act on it (0172).
- The backlog moves to `.backlog/` at the repo root, out of `.claude/`, whose path segment the harness refuses writes under as a sensitive file. Every skill and reference names `.backlog/`; the scripts still work at the legacy `.claude/backlog/` until 2026-12-31, printing one stderr line naming `./migrate` there, and refuse a repo holding both. `./migrate`, a new script installed beside the others, moves a legacy backlog as one commit and refuses while the lock, a foreign claim or a sprint marker is held. **Install this release on every machine that works a repo before migrating it** — a skill from an earlier release finds no backlog in a migrated repo — and check with `tools/release verify`. A refused backlog write now follows one section every stage reads, `references/CONCURRENCY.md` *When a backlog write is refused*: split the call first, `python3` on the legacy path, never leave the lock held, quote the exact refused commands (0182).
- A freshly scaffolded backlog can now close its first ticket: `queue` ships a `DONE.md` template whose columns are the ones `close` fills, so no project has to invent one (0196).
- A sprint-dispatched retro no longer stops when a repo it would edit is behind the remote: it carries on over the repos that are current, leaves findings bound for the stale repo in FINDINGS.md rather than re-routing them, and reports each skipped repo, its divergence and the outstanding pull (0177).
- The skill-size guard now fails when a skill already recorded as over the size goal grows more than 5,000 bytes past the size its reason was argued at. The fix is to re-argue the reason at the new size, or relocate content. The sprint skill's reason has been re-argued at its current size. (0190)
- Verify records an NFR row as unguarded, never ticked, when its named check stays green under a mutation of the requirement; the item template says a filename alone is not a How it would red answer; and a new guard, tests/item-nfr-red.test.sh, fails any open item whose filled NFR row leaves that cell empty or a bare file reference (0183).
- A sprint that is interrupted and resumed now keeps its run id. Step 1 retakes the supervisor's own marker at any age and logs `supervisor_resumed`. A run whose stale marker is taken over is ended once, as `superseded`. The resume cap gives back the re-paid context floor, read from `harvest-usage.sh --legs`. `sprint-ledger.sh record` replaces the run's block instead of appending a second one (0175).
- Every skill's park step now says the FINDINGS.md append takes the backlog lock, and a by-hand lock's commit must name its paths literally and confirm `git status` clean before releasing (0091).
- At a busy lock during a close, verify now keeps retrying instead of stopping, holding its evidence in the item's QA evidence section until the lock clears or goes stale (0047).
- When a whole-suite result comes back, `develop` now reads `git status --porcelain` before trusting it. It names three causes of a red that are not the session's own: another session's uncommitted work, another session's deliberate red, and a measurement that moved mid-run. The fix it names is a run in a throwaway worktree at the session's own last commit. A red the tree is supposed to have is handed on with evidence, and a ticket that measures the machine records the snapshot it pinned. Before handing off, `develop` confirms none of its own paths are still uncommitted, and `verify` Step 2 points back at that rule. `CONCURRENCY.md` now says plainly that a `touches:` collision warns neither session (0054).
- A retro session now takes the by-hand backlog lock in whichever form `references/CONCURRENCY.md` permits, including holding it across several reviewable calls, instead of being told the whole write must be one shell invocation (0126).

## 0.9.43 — 2026-10-25

- `develop` and `retro` now fast-forward a behind checkout whose incoming commits are backlog-only — clean tree, ahead of nothing, every incoming path under `.claude/backlog/` — and report the repo, the SHA before and after and the incoming paths, rather than stopping the pass; any other behind state still stops (`CONCURRENCY.md`, *A behind checkout fast-forwards only over backlog commits*) (0216).
- `develop` no longer edits a criterion it finds wrong or impossible, even to correct it: it records which `ACn`, why and the proposed text in *Notes & decisions* and hands the ticket to `queue` (0195).
- `queue` and `design` now stamp `ac_digest:` from `./next --ac-digest <id>` wherever they write criteria, and `./next --drift` (so `--drive`, on exit 4) reports a stamped digest the criteria no longer match, naming each criterion changed, added or removed (0195).
- `close` and `verify` refuse criteria that differ from their `ac_digest:` stamp — `verify` sends the ticket to `queue` as a stale contract — and an item with no stamp closes with an `ac_digest absent — unverifiable` line rather than reading as a match (0195).
- `queue` now files work that should exist only if a measurement clears as a gate ticket alone, carrying the template's new `## Kill criteria` section (thresholds, a `**Verdict:**` line, an `**If it clears:**` prose outline). The decided work is not filed as FRs or as a `blocked_by` dependent, and the gate's criteria assert only that the verdict was recorded, so it closes `done` on a kill (0110).
- README's "Run every guard" block now names every tests/*.test.sh with a description, and tests/citations.test.sh fails on a suite the block omits, a name with no suite behind it, or a line with no description (0046).

## 0.9.42 — 2026-10-25

- A finding about a skill, reference file or backlog script now routes to the tools repo's `.claude/backlog/FINDINGS.md` with the root explicitly ruled out, so a session no longer falls back to a local park because the tools root has no buffer.
- `develop` now sends an item whose Problem section contradicts its own FRs or ACs to `design`, rather than building half to each side and calling it a deliberate asymmetry.
- `sprint`'s tail-cap snippet now passes `tail-cap` the findings count alone, so scaling the retro and queue caps no longer dies with a `ValueError`.

## 0.9.41 — 2026-10-18

- design Step 4 no longer tells a session to bank `tests/item-ac-form.test.sh` before the handoff as a check of its own item — the test skips `next: design` rows and reads its own repo's items — and now has it re-read `qa_level` and `close_by` against the criteria it just wrote.
- develop's live-run check now matches the runner's run subcommand (`'playwright test|vitest run'`), so a running Playwright MCP server no longer reads as a test run.
- queue now writes a secret-absence check against the value's shape, never the variable's name.

## 0.9.40 — 2026-10-11

- develop now treats a declared success threshold as a goal to iterate toward or escalate, never a number to edit; queue pins such a threshold in a test and checks a file's other timing assertions before writing a contended-run AC, phrasing it as "no <named failure> in N runs".
- develop's mutation-check rule now says to `git add` an untracked file before committing it and to chain the mutation run on the commit with `&&`, and its hand-off step says never to batch `./handoff` in one parallel tool call with the notes writes it must follow.
- prototype now builds at a path the ticket pins rather than the default, and resolves a level 1 or 2 path from the repo root when no `prototype:` block is configured.
- A sprint's report, proposal and escalations now name every ticket as a clickable path to its item file, at the AC's line where an AC is named, instead of a bare id.

## 0.9.39 — 2026-10-10

No behaviour change — internal guards and records only.

## 0.9.38 — 2026-10-10

- A sprint's Step 1 probe now runs at --max-budget-usd 1.00, since 0.25 fell below a fresh host's startup floor and failed like a broken CLI; the skill states the supervisor's per-turn floor as per host (76k measured on one) and says to read it from harvest-usage.sh --run.
- harvest-usage.sh prices claude-opus-5-5 (USD 4.00 in, 20.00 out, cache read 0.20 per million, which is 0.05x input), holds each model's cache-read rate in RATES rather than as one 0.1x multiplier, and derives its `RATES per million:` header from that table, naming every model.
- harvest-usage.sh's per-skill table now has a row for a skill whose turns all went unpriced, and any skill row with unpriced turns ends `unpriced turns: <n>`.
- sprint-ledger.sh record writes `unpriced` (or a figure plus `partial: <n> unpriced turn(s)`) on GATE, RATIO and DESIGN lines where it used to write USD 0.00, and the wall_clock_min row names the run log's event timestamps as its source.
- sprint Step 7 resumes a session-limited stage that the harvest cannot price at the full stage cap, and logs `resumed` with `cap_basis: "unpriced"`.
- verify's fallback wait for a long sweep is now a bounded loop inside one python3 call with time.sleep, rather than a shell sleep loop the harness refuses.

## 0.9.37 — 2026-10-07

- A sprint now resolves the opus alias once, at its Step 1 probe, and dispatches every stage and every resume on that concrete model id, recording it on scope_confirmed and on each dispatch event, so one run can no longer mix two models and a run log names the model each session ran on (0187).
- A sprint is now planned from the first develop-ready row rather than from a design row that outranks it: the proposal names the design rows related to that gate and the one design row that will head the next sprint, and under a confirmed scope those are designed first and then built. Design may now run beside develop, verify or design; ./next --drive steps over a design row whose files a running develop is editing, and exits 6 (wait) when a develop gate names a file a running design session is reading. Retro and queue still run alone (0188).
- When the findings buffer crosses on a run that confirmed no scope, ./next --drive now says the retro waits until the run is out of work, instead of naming a confirmed scope the supervisor never passed. With a scope, the wording is unchanged (0174).
- A sprint's ledger block now lists every ticket the run closed, each with its title and the verdict that closed it, beside per-window elapsed time and cost, totals, averages and cost per closed ticket against MEASUREMENT.md's pair. ./close takes --note to write a release note under ## Unreleased in CHANGELOG.md, and tools/release promotes those notes to the version it bumps, refusing an empty ## Unreleased unless --no-behaviour-change is passed. tools/harvest-usage.sh --by-session prints one row per context window (0041).
- verify now gives every plural or quantifier clause in its clause table (every, each, those, per X) a fixture of at least two items that differ, and puts a sweep's output file inside the session's working directories rather than /tmp, polling in a bounded loop where Monitor cannot be armed.
- A sprint now builds its baseline worktree beside the checkout, so config.yml's relative paths resolve and a green HEAD no longer reads red, and opens a fail's detail pointer to name the failed criterion before presenting it, instead of relaying the escalation as the cause.
- A new item's acceptance-criteria section says how to strike a criterion: as a non-list ~~ACn~~ line, since a struck bullet reds tests/item-ac-form.test.sh.
