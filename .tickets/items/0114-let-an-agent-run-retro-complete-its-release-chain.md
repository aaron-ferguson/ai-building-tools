---
id: "0114"
title: Let an agent-run retro complete its release chain instead of stopping half-released
type: bug
next:
status: done
qa_level: unit
size: m
created: 2026-09-07
source: retro
parent:
blocked_by: []
relates: ["0075", "0113"]
expects:
  - skills/retro/SKILL.md
  - tools/release
  - tests/release.test.sh
claimed_by:
claimed_at:
touches:
closed: 2026-09-09
---

## Problem

**`retro` Step 5 instructs every session to run a chain that an agent session structurally cannot
finish, and the stop lands after the bump has already been committed.**

Step 5 (`skills/retro/SKILL.md:272-282`): *"A skill edit has a release chain — run `tools/release`
from the repo root."* Step 7 of that chain confirms the push (`tools/release:277-297`):

```
if [ "$YES" -eq 1 ]; then                       # :285
elif [ -r /dev/tty ]; then                      # :288
  read -r REPLY < /dev/tty                      # :290
else
  die "no tty to confirm the push on; re-run with --yes if you mean to release" 3
```

**The failure is worse than "it dies with exit 3", and the difference is the whole design question.**
Re-verified in an agent shell on macOS 25.5.0, **2026-09-08**:

| | |
|---|---|
| `[ -r /dev/tty ]` | **true** — the device node is `crw-rw-rw-` and `access(2)` succeeds |
| `read -r REPLY < /dev/tty` | fails: `/dev/tty: Device not configured` |
| under `set -eu` (`tools/release:44`) | **exit 1, no message** — neither `die` at :294 nor at :292 runs |

So an agent does **not** take the `else` branch. It takes the *prompt* branch, prints a prompt
nobody can answer, and the failing redirect kills the script through `set -e`. The operator gets no
`die` text at all: not "no tty ... re-run with `--yes`", not "the bump is committed locally and
nothing was released". A half-released tree and an unexplained exit 1.

`[ -r /dev/tty ]` is not a terminal test. It tests the device node, which exists on every macOS
process. Only attempting the read distinguishes a session that has a controlling terminal from one
that does not.

**By then the version bump is committed** (`tools/release:266-275`, step 6) **and the suite has
run** (step 5). Step 5 of `retro` says this fires on most retros, which makes it a standing
condition rather than an edge case.

**It compounds with 0075.** 0075 FR3 has the next version derived from *the remote's* current
version, precisely to stop the collision that happens when local and remote disagree. A committed
bump that never reached the remote is exactly that disagreement — produced, now, by the tool's own
stop path.

## Functional requirements

**The design question is settled — see *Notes & decisions*, 2026-09-08.** The push authorisation is
resolved once, early, before the chain writes anything, and `retro` obtains it from the user before
invoking the chain at all.

- FR1 — An agent-run retro reaching Step 5 either completes the chain or stops **before** the chain
  acts. It must not stop between the bump and the push, which is the only state that needs a human
  to reason about recovery.
- FR2 — **`tools/release` stops testing the device node.** `[ -r /dev/tty ]` is gone. Whether a
  terminal can answer is determined by attempting the read and handling its failure, so the three
  cases — answered, declined, cannot be asked — are distinguishable and each carries its own
  message.
- FR3 — **The authorisation is resolved before the chain writes or moves anything.** Where the run
  will push (the branch is already ahead, or a bump is about to be applied) and the answer is
  `--yes`, a `y`, a `n`, or unobtainable, that is settled while `.claude-plugin/plugin.json` is
  still unedited and `HEAD` is still where it started. Every refusal path leaves the tree as it
  found it and says so.
- FR4 — **A hand-run release stays interactive.** A human at a terminal is still asked, on the
  device, and a `n` still refuses. What changes for them is only *when* they are asked — see the
  accepted trade-off in *Notes & decisions*.
- FR5 — **`git-conventions.md`'s specific, per-push confirmation is evidenced for the agent path,
  and the change names where.** For an agent the confirmation is the session's own ask, immediately
  before the invocation, naming the branch and that other machines install from it. `--yes` carries
  an approval already granted; it is never a standing default and never supplied by a skill on the
  user's behalf.
- FR6 — **`retro` Step 5 names one invocation, and `tools/release`'s usage line documents that same
  invocation.** They disagree today in two ways, not one: Step 5 omits `--yes`, and it also omits
  `--bump`, without which the run refuses at step 4 and the bullet's own description of the script
  ("It bumps the version, pushes, updates the install") is not what the named command does.
- FR7 — **The half-released state is recoverable by whoever finds it**, and the step that owns
  recovery says how, in one sentence, naming the signal to look for.
- FR8 — **The refusal in FR3 is driven in `tests/release.test.sh` against the fixture**, which
  requires the confirm device to be injectable — the file already takes `--record`, `--plugin` and
  `--checkout` for exactly this reason (`tests/release.test.sh:18-21`). Adding that seam is part of
  this change, not left to implementation discretion. The fixture keeps its stated properties: it
  never pushes anywhere real and never shells out to `claude`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Git | A push from this repo is a release — other machines install from the branch, and `CLAUDE.md` carries **no Environments block**, so the deploy trigger is undocumented and *unknown counts as "can deploy"* (`git-conventions.md:29-35`, and its resolve-to-asking rule). The confirmation stays specific and per-push. `--yes` passed by default with no user act would remove it, not relocate it. | `git-conventions.md` |
| Progressive delivery | The version bump is how an edit reaches installed copies. This change moves the authorisation to before the bump is *written*, so a half-failed release now leaves nothing behind rather than a committed bump. That is the stated behaviour, not a side effect. | `progressive-delivery-conventions.md` |
| Documentation | The instruction and the script's usage line must agree after this, on both flags. | `documentation-conventions.md` |
| Testing | The new cases assert on the **message**, never on the exit status — `tests/release.test.sh:13-16` already states why, and this ticket's own bug is a non-zero exit that says nothing. Prove each new guard can fail by mutating the clause it matches and reverting. | `testing-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given the fixture checkout with a bump due and no `--yes`, when `tools/release` runs
  with the confirm device pointed at a path that cannot be read, then it exits non-zero with a
  message naming `--yes`, **`HEAD` is unmoved and `.claude-plugin/plugin.json` is unedited**.
  *Red today:* the current chain reaches step 7 having already committed the bump, so the HEAD
  assertion fails against the tree as it stands. This is AC1 of the original ticket, narrowed to
  what the fixture can drive.
- [x] AC2 — Given the same fixture, when the confirm device is readable but answers `n`, then the
  refusal says the release was declined and, likewise, `HEAD` is unmoved and `plugin.json`
  unedited. *Red today:* the decline at `tools/release:292` fires after step 6 has committed.
- [x] AC3 — Given `tools/release`, when it is read for how it decides whether a terminal can
  answer, then **`[ -r /dev/tty ]` does not appear**. *Red when reintroduced.* Anchored to the
  construct rather than to a message, because the defect is that the construct returns true in the
  environment it was written to exclude — a message-level guard passes while it is still there.
- [x] AC4 — Given a run with `--yes`, when it reaches the push, then nothing was prompted for and
  no refusal for want of a terminal was raised. See the QA plan for how far this is drivable.
- [x] AC5 — Given a repository whose HEAD carries a committed version bump that was never pushed,
  when a session reads the step that owns recovery, then it is told what to do and what to look
  for. *Red when that sentence is deleted.*
- [x] AC6 — Given the landed change, when read against `git-conventions.md`'s push rule, then
  `retro` Step 5 names where the release approval is evidenced — the session's ask, before the
  invocation — and states that `--yes` never stands in for it. *Red when the naming is removed.* A
  change that merely adds `--yes` and says nothing satisfies AC1 and fails this one, which is the
  pairing that stops the cheap answer being taken silently.
- [x] AC7 — Given `tools/release`'s usage line and `retro` Step 5, when read together, then they
  describe the same invocation, **`--bump` and `--yes` both**. *Red when either is changed without
  the other.*
- [x] AC8 — Given an `orchestrate`-dispatched retro, when Step 5 is reached with nobody to ask,
  then the chain is **not invoked** and the release is reported outstanding on that run's
  checklist. *Red when the no-one-to-ask branch is removed* — it is the case FR1 exists for, and
  `orchestrate:251-256, :308` already forbids the push, so the two must not contradict.

## QA plan

- **Why that level:** `unit` is the only runner here and it covers both halves — `tests/*.test.sh`
  greps the prose for AC5-AC8, and `tests/release.test.sh` drives the real script against a real
  git fixture with a real bare remote, which is what AC1-AC3 need.
- **The confirm-device seam.** AC1 and AC2 need the device injectable. AC1 points it at a
  non-existent path; AC2 at a file containing `n`. Note for whoever builds it: **a directory is not
  a usable stand-in for an unopenable tty** — `open(2)` on a directory succeeds on macOS and only
  the `read` fails, verified 2026-09-08 — which is why FR2 is written as "attempt the read", not
  "attempt the open".
- **AC4 is only partly drivable, and the honest scope is stated rather than discovered.** A full
  `--bump --yes` run reaches step 8, which shells out to `claude` (`tools/release:302-307`), and
  `tests/release.test.sh:20` forbids that. Two options, and the change records which was taken:
  drive it with a `PATH` that excludes `claude` so step 8 takes its `skipped` branch (this also
  needs the fixture's `tests/noop.test.sh` made executable, since step 5 runs it), or assert AC4 at
  the prose level only and say why. Do not weaken `tests/release.test.sh`'s no-real-`claude`
  property to get it.
- **Prove each new guard can fail** by mutating the clause it matches and reverting.
- **Do not drive anything against the real remote or the real install record.**

## Out of scope

- **The multi-repo form of the chain and its report** — 0113. Different failure in the same bullet:
  that one is about a pass that can run the chain and cannot describe the result.
- **Fetching before the edits and deriving the bump from the remote** — 0075. This ticket does not
  change how the version is chosen, only whether the chain finishes.
- Making `tools/release` non-interactive by default for a human at a terminal. FR4 holds: they are
  still asked, only earlier.
- Rolling back a bump the chain already committed. The design removes the state rather than
  automating a recovery from it; FR7 is a sentence for a human, not a `git reset` in the script,
  which resolves nothing itself by deliberate design (`tools/release:215-216`).

## Notes & decisions

- **Routed to `design`.** The finding named two candidate fixes and judged the second more likely.
  That is a preference, not a decision, and the two write incompatible ACs against different files.
  The blocking part is not which is nicer — it is that `git-conventions.md` requires the push
  confirmation to be specific, so removing the prompt is only permissible if the approval is
  evidenced elsewhere, and deciding *where* is the work.

- **DECIDED 2026-09-08 (`/design`): neither candidate as posed. The approval is not moved and not
  bypassed — it is resolved once, early, and obtained from the user by `retro` before the chain is
  invoked.** Concretely: `tools/release` settles authorisation before it writes anything and stops
  testing the device node; `skills/retro/SKILL.md` Step 5 asks the user for the push first and then
  invokes `tools/release --bump --yes`. Both artefacts are touched, which answers FR4 of the
  original ticket.

- **What settled it was re-reading the source rather than the requirement.** The ticket asserted
  `[ -r /dev/tty ]` is false in an agent shell and that the chain dies at `:294` with exit 3. Both
  are wrong: the test is **true**, the `read` fails, and `set -e` exits 1 silently (measured
  2026-09-08, table in *Problem*). That relocates the decision. `--yes` in Step 5 alone was never
  merely "the cheap answer" — it leaves a broken terminal test in the script, so every session that
  omits the flag still gets an unexplained exit 1 over a committed bump. The prior pass verified
  line numbers and read as though it had verified behaviour.

- **Rejected — `--yes` in Step 5, `tools/release` untouched.** Would have to be true for it to win:
  that the script's stop is correct and only under-documented. It is not; see above. It also cannot
  satisfy AC1 as the QA plan drives it, since that assertion is against the script in a fixture.

- **Rejected — delete step 7's prompt and move the approval wholly out of the script.** Would have
  to be true: that nobody runs `tools/release` by hand. They do, and the prompt is the only place
  `git-conventions.md`'s per-push confirmation is mechanically enforced for that path. Deleting it
  is also this ticket's own *Out of scope*.

- **Trade-off accepted: the human is asked earlier than the push.** `tools/release:277-278` claims
  the confirmation happens "at the point it happens, and never implied by having run the script".
  After this change it happens before the suite runs and before the bump is committed, so a human
  approves a release that a red suite may then stop. That is the price of FR1 — there is no
  ordering in which the authorisation both comes last and comes before the commit. It is cheap: a
  red suite refuses before pushing, nothing is committed, and the run is re-runnable. The step that
  pushes should still name where the authorisation was granted, so the log does not lose it.

- **Second trade-off: two gates for two callers.** An agent is gated by the session's ask, a human
  by the device prompt. Duplicated gates drift. Mitigations: both are asserted in
  `tests/release.test.sh` and `retro`'s prose says which applies to whom, and `--yes` remains the
  single flag that means "already asked".

- **`--bump` in the standing instruction is deliberate.** The script's header defends `--bump` as
  friction against a silently-applied version, but the version is derived from the remote
  (`tools/release:228-234`), not hand-picked, so the flag chooses nothing. The friction that
  matters is the release y/n, which FR5 keeps. Verified: the same invocation also *recovers* a
  stranded bump — `version_gt(local, installed)` is already satisfied, so the `--bump` branch is
  never reached, nothing is re-bumped, step 6 finds nothing to commit, and step 7 pushes. One
  invocation both releases and recovers, which is what makes FR6 and FR7 the same sentence.

- **Nothing depends on a fact not in hand.** Everything above was read or measured on 2026-09-08:
  `tools/release` in full, `skills/retro/SKILL.md:249-282`, `git-conventions.md:27-43`,
  `tests/release.test.sh`, `orchestrate/SKILL.md:251-256, :308`, and the `/dev/tty` behaviour.

- Checked 2026-09-08: `origin/main..HEAD` is 20 commits and **carries no stranded bump** — the
  0.9.19 bump (`7ecd056`) is pushed. FR7 is for a state that will recur, not one on the tree now.

- Captured from `FINDINGS.md` 2026-09-07.

- **BUILT 2026-09-09 (`/develop`, token `2c30`).** Two commits: `31ace2e` (the script and its
  behavioural guards), `b247558` (`retro` Step 5 and its prose guards). Whole suite green,
  25 files, nothing red.

- **The chain is 9 steps now, not 8.** Authorisation is a step of its own between the version gate
  and the tests: step 4 *decides* (`BUMP_DUE`) and writes nothing, step 5 asks, step 7 applies the
  bump and commits it. That ordering is what makes every refusal leave HEAD and `plugin.json`
  alone, and step 8 prints `authorised at step 5 ($AUTH_VIA)` so the log does not lose where the
  approval came from now that it is no longer granted at the push (FR5).

- **The mechanism the fix rests on, measured 2026-09-09 on macOS 25.5.0.** `if read -r R <
  <unreadable>; then` under `set -eu` is a **false branch, not an exit** — `read` is not a POSIX
  *special* built-in, so a redirection failure on it is an ordinary non-zero status, and an `if`
  condition is exempt from `set -e` regardless. That is the whole difference from the old code,
  where the same `read` sat bare and killed the script. Confirmed for all three devices: a
  nonexistent path, `/dev/tty` in an agent shell, and a directory (which the QA plan predicted:
  `open(2)` succeeds and only the read fails).

- **AC4 was driven the strong way — the full chain through the push.** Of the QA plan's two
  options, the run excludes `claude` by filtering every `PATH` entry that holds an executable of
  that name, and **asserts the filter worked** before running: a filter that failed refuses the
  case rather than quietly running the real install chain. The fixture's `tests/noop.test.sh` is
  executable in the new `mk_case` fixture (the 0084 fixture's stays as it was, being only a byte
  to compare). The run's final status is non-zero and that is correct — the fixture install was
  never re-extracted, so the byte comparison legitimately fails against the bump commit; every
  assertion is on the message, per the file's own rule.

- **Each 0114 case builds its own checkout/remote/install triple.** The 0084 cases mutate one
  shared fixture in sequence and assert on its HEAD, so a case here that commits and pushes would
  have broken them from a distance — silently, and from several cases away.

- **FR2 asks for three distinguishable outcomes and the ACs drive two.** A `y`-answering device
  case was added, because asserting only the refusals leaves a `confirm_release` that treats every
  readable answer as a decline green.

- **A guard phrase straddling a line break cost one red.** `never stands in for one` wrapped across
  two source lines in the first draft of Step 5 and the guard could not match it on correct prose.
  `CLAUDE.md` already carries the rule; recorded here because it fires on the *writing* side too,
  not only when rewrapping someone else's paragraph.

- **`tools/release --help` prints a line range, and the range is a cache of the header's length.**
  It was `sed -n '2,45p'`; the header is now 67 lines, so it is `2,68p`. Nothing asserts the two
  agree — a future header edit will silently truncate the help output.

## QA evidence

**Verified 2026-09-09 (`/verify`, token `a6c5`), `qa_level: unit`.** Tree clean at the start of the
pass (`git status --porcelain` empty) and clean at the verdict. Whole suite run per-file rather than
with `config.yml`'s fail-fast `unit` line, per that file's own note: **25 files, every one green,
0 failed.** Every mutation below was applied to committed files and restored with
`git checkout -- <path>`; the closing control run was green with no collateral.

**The copy under test is this repo's.** The installed plugin is at 0.9.22 and so is
`.claude-plugin/plugin.json`, but `31ace2e` and `b247558` are unpushed, so the installed copy does
**not** carry this change. The repo copy is the authority and is what was executed.

| # | How it was checked | Mutation proving it can fail | Result |
|---|---|---|---|
| AC1 | `tests/release.test.sh`, fixture `mk_case` with a bump due, no `--yes`, `--confirm-device` at a nonexistent path. Four assertions: non-zero exit, message names `--yes`, message is the tool's own (not a silent `set -e` death), `HEAD` unmoved and `plugin.json` unedited | (a) applied the bump at step 4 as the old code did → `AC1 — the refusal stopped between the bump and the push`; (b) reworded the refusal to drop `--yes` → `AC1 — the refusal never names --yes` | **PASS** |
| AC2 | Same fixture, `--confirm-device` at a file containing `n`; refusal message and the untouched-tree assertion | (a) bump applied at step 4 → `AC2 — the decline fired after the bump was committed`; (b) `declined` → `refused` → `AC2 — the refusal does not say the release was declined` | **PASS** |
| AC3 | `grep -qF '[ -r /dev/tty ]' tools/release` — anchored to the construct, not a message | Appended `# elif [ -r /dev/tty ]; then` to `tools/release` → `AC3 — tools/release still tests the device node` | **PASS** |
| AC4 | Full chain driven through the push with `--bump --yes`, `PATH` filtered of `claude` (filter asserted first), fixture bare remote. Asserts no `[y/N]` prompt, no want-of-terminal refusal, the push reached, step 9 took its skipped branch, remote advanced to HEAD | Changed `[ "$YES" -eq 1 ]` to `-eq 9` so `--yes` no longer short-circuits → five AC4 assertions red at once | **PASS** |
| AC5 | `tests/retro-tool-edit.test.sh`, three phrases inside Step 5's window: the state named, the signal, the recovery | Rewrote `` `git log origin/<branch>..HEAD` `` to "the log" → `AC5 — and the signal to look for is named` red. The file also carries its own probe deleting `re-bumps nothing` | **PASS** |
| AC6 | Two phrases in Step 5's window — `asks the user before the invocation`, `never stands in for one` — plus a `--yes`-only fixture that must stay red | `never stands in for one` → `is not a substitute` → `AC6 — and --yes carries an approval, never substitutes for one` red | **PASS** |
| AC7 | Both sides: `tools/release --bump --yes` in Step 5's window **and** in `tools/release`'s header | (a) dropped `--yes` from Step 5 → the prose half red; (b) dropped `--yes` from the script's standing-invocation line → the script half red. Each side reddens alone | **PASS** |
| AC8 | Two phrases in Step 5's window; cross-checked against `orchestrate` `:251-252` and `:308`, which forbid push, bump, install and restart — no contradiction | `does not invoke the chain` → `skips the release chain` → first half red; `outstanding on that run's checklist` → `noted on the run's list` → second half red. **A first attempt at this mutation matched nothing** (the `**` bracketing spans the whole clause); caught on the empty diffstat and re-run | **PASS** |

| NFR | How it was checked | Result |
|---|---|---|
| Git (`git-conventions.md`) | The per-push confirmation is not removed: a hand run with a real tty still prompts (`confirm_release`'s `printf` + `read`), and `--yes` is documented in both the script header and Step 5 as carrying an approval already granted, never a default. AC6 and AC7 are the mechanical half | **PASS** — see the finding on `--confirm-device` below |
| Progressive delivery | The bump is applied at step 7, after authorisation at step 5. Proved by mutation, not by reading: moving the bump back to step 4 reddens AC1 and AC2's untouched-tree assertions | **PASS** |
| Documentation | `tools/release --help` renders complete and correctly bounded — the widened `sed -n '2,68p'` ends exactly on the exit-codes block, with no truncation and no leakage into `set -eu`. Usage line and Step 5 agree on both flags (AC7) | **PASS** |
| Testing | Every new case asserts on the message. AC1 additionally asserts the message exists at all (`*"$ME_RELEASE:"*`), which is the one assertion the original defect — non-zero exit, no output — would have failed. Each new guard was mutated and reverted above | **PASS**, with one gap recorded below |
| Always-on (`CONVENTIONS_CORE.md`) | No log field, analytics event or egress destination added, so no privacy pass triggered; no auth, credential or data-visibility surface; no UI. Public-repo sweep of the diff for company material and home-directory paths: clean, and `tests/measurement.test.sh` guards the latter across the tree | **PASS** |
| Newly reachable | The change adds one new route, `--confirm-device`. Walked: it is required by FR8, it defaults to `/dev/tty`, and it cannot reach outside a path the caller already names. See the finding below | **PASS** |

### Gaps recorded rather than papered over

- **The FR5 provenance guard cannot fail.** `tests/release.test.sh`'s AC4 block asserts
  `case "$A4OUT" in *authoris*`. Removing `-- authorised at step 5 ($AUTH_VIA)` from step 8's push
  line leaves the suite **45 passed, 0 failed**: the matcher is satisfied by step 5's own banner,
  `step 5/9 authorise the release`, which prints on every run. FR5's script half is therefore
  unguarded. Left uncovered deliberately — no AC rests on it, and narrowing the matcher here would
  be inventing a guard during QA. Parked in `FINDINGS.md`.
- **`--confirm-device` is a second flag that means "already asked".** A file containing `y` at that
  path authorises a real push with no terminal — driven by the FR2 case, which reaches step 6 and
  pushes to the fixture remote. FR8 requires the seam, so this is intended, but *Notes & decisions*
  claims `--yes` "remains the single flag that means 'already asked'" and that is no longer true.
  Prose, not behaviour. Parked in `FINDINGS.md`.
