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

- The citations guard now resolves the conventions path from the main checkout, so running the suite in a worktree outside the checkout's parent directory (a temp directory, say) no longer reports a conventions red that no ticket owns (0189).

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
