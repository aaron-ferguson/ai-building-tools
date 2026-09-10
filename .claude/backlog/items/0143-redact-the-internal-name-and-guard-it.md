---
id: "0143"
title: Redact the internal organisation name from this public repo and guard the rule forbidding it
type: bug
next:
status: done
qa_level: unit
size: m
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0118", "0122"]
expects:
  - tests/measurement.test.sh
  - .claude/backlog/items
  - .claude/backlog/RANKING-HISTORY.md
claimed_by:
claimed_at:
touches:
closed: 2026-09-10
---

## Problem

**`CLAUDE.md` forbids internal organisation material in this public repo, and five tracked files
carry an internal repository name anyway.** The rule is stated as the repo's defining constraint —
`company: none` "is not a default, it is the constraint" — and it is the one privacy rule with no
check behind it. The privacy guard that exists (`tests/measurement.test.sh`, `HOME_PATH_PAT`) matches
home-directory paths and nothing else, so an organisation name is published with the suite green.

The leaked token is an internal repository path, written in the `Problem` and `Decision` sections of
one item by a capture pass and a design pass, and then copied forward — it now appears in two more
item files, in `RANKING-HISTORY.md` and in `FINDINGS.md`. This row does not restate it; the session
that claims this row finds the occurrences by the search FR1 describes, which is also why `0122` —
whether a mention of a privacy rule may name the thing the rule forbids — is related and not a
blocker.

**The history is already pushed and cannot be unpublished by this row.** Redaction stops the
republishing; removing it from history is a rewrite of a branch other machines install from, which is
a person's decision and not this ticket's. The row records that boundary rather than deciding it.

`0118` covers the adjacent gap — that the sessions most likely to leak are the ones that run no
suite — and is deliberately left whole: this row adds the pattern, `0118` adds the reach.

## Functional requirements

- **FR1** — The guard matches an internal organisation or client name in any tracked file, from a
  configured list rather than a literal in the test, so adding a name does not mean editing an
  assertion. The list lives where a public repo can hold it: the names are the secret, so the list is
  a path the guard reads if present and skips if absent, never a committed enumeration.
- **FR2** — Every current occurrence is redacted to a placeholder form that still says what the
  sentence needed it for (*an internal repository*, *a second backlog*), so no item loses its meaning.
- **FR3** — The guard has the same redaction exemption `HOME_PATH_PAT` has, proved the same way, so
  prose *about* this defect can be written without reddening it.
- **FR4** — A falsification control asserts the pattern still catches a real-shaped name, with the
  samples assembled rather than written, for the reason the existing block documents.

## Non-functional requirements

- **Security** — the configured name list is never committed and never printed by a failing
  assertion; the guard reports the file and line, not the matched text. How this would red: a case
  asserting the failure output does not contain the matched token.
- **Compatibility** — the home-path guard keeps working unchanged. How this would red: the existing
  `HOME_PATH_PAT` cases, which must stay green.

## Acceptance criteria

- [x] AC1 — Given a configured name list and a tracked file containing one of those names, when
  `tests/measurement.test.sh` runs, then it fails and names the file and line. Red-making input: the
  tree as it stands today, which contains five such files and passes.
- [x] AC2 — Given no configured name list present, when the test runs, then the name check is reported
  as not applicable and the file still reports `0 failed`. Red-making mutation: failing closed on a
  missing list, which makes the suite unrunnable on a fresh clone.
- [x] AC3 — Given a tracked file containing the placeholder form FR2 uses, when the test runs, then it
  is not flagged. Red-making mutation: dropping the exemption, which flags this item file itself.
- [x] AC4 — Given the assembled real-shaped sample, when the pattern is applied, then it matches.
  Red-making mutation: widening the exemption until the sample passes.
- [x] AC5 — Given `git grep` over the tracked set for the redacted token, when it runs, then it
  reports nothing. Red-making input: today's tree.
- [x] AC6 — Given a failing run, when its output is read, then the matched token does not appear in
  it. Red-making mutation: interpolating the match into the message, the obvious implementation.
- [x] AC7 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
  reports `0 failed`.

## QA plan

- **Why this level:** `unit` — the guard is a shell assertion block in an existing suite file, and
  every requirement is a case over assembled samples and a fixture tree.
- **Specific checks:**
  - Run `tests/measurement.test.sh` first on its own, then the whole suite file-by-file with
    `|| true` per `config.yml`'s note.
  - Confirm AC5 by `git grep` rather than by reading the files changed, so a sixth occurrence nobody
    listed is found.
  - Mutate the exemption and the pattern independently — `0111`'s AC5 and the `findings-routing` AC5
    block are both precedents for one guard silently covering two claims.

## Out of scope

- Rewriting pushed history. Named in the Problem section as a person's decision.
- Running the guard from the skills that commit without a suite — that is `0118`.
- Deciding whether a rule's own prose may name what it forbids — that is `0122`, and this row is
  written to be correct under either answer.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

**Verified 2026-09-09 by `verify` session 94ea, at `qa_level: unit`, over the checkout at
`4dbd220` (clean at Step 2 and at the verdict).** Every mutation below was run against a throwaway
`git worktree` at `4dbd220` driving `PRIVATE_NAMES_FILE` at a **synthetic** list holding an assembled
name, so no real name was staged, matched or printed. The worktree was removed and the control run
on the untouched checkout with the real configured list is green — that green is what licenses every
red above it.

| # | How it was checked | Result |
|---|---|---|
| AC1 | Worktree fixture `fixture-leak.md` line 2 holding a synthetic configured name, `git add`ed so `git grep` sees it. `tests/measurement.test.sh` → `FAIL … a tracked file publishes an internal organisation or client name` / `fixture-leak.md:2`, `120 passed, 1 failed`. Red-making input confirmed **against the real list at the real token**: the pattern built from `.private-names` matches **18 lines in 8 files** at `751be95^` and **0** at `HEAD` and in the working tree | ✅ |
| AC2 | `PRIVATE_NAMES_FILE=/nonexistent/nope` → `ok  internal-name check not applicable — no name list configured (a fresh clone has none)`, `121 passed, 0 failed`. Mutation: that branch's `ok` → `bad` (fail closed) → `120 passed, 1 failed`, so the branch controls the tally and is reached | ✅ |
| AC3 | **Reached at tree level, contrary to the build note** — a worktree plus a synthetic list needs no committed name. Fixture holding only the wrapped form `<Acme-shaped>` → `ok  no tracked file publishes …`, `121 passed, 0 failed`. Mutation: `EXEMPT_PREFIX=''` → the fixture is flagged at `fixture-leak.md:1` **and** the three control cases red, `117 passed, 4 failed`. Also carried by the control's own `<>`/`{}`/`$` cases | ✅ |
| AC4 | The three assembled real-shaped samples match under the synthetic list. Mutation: exemption widened to `(^|[^<{$a-z ])` → `FAIL … the pattern MISSED a real-shaped internal name (the Acme profile treats it as) — the exemption is too wide`, `120 passed, 1 failed` | ✅ |
| AC5 | `git grep -ilE` with the pattern built from the real `.private-names`, over the tracked set: **no match** in the working tree (exit 1) and none at `HEAD`. Not vacuous — the same pattern returns 18 lines in 8 files at `751be95^`, which is also what falsifies the Problem section's count of five and confirms the build note's correction | ✅ |
| AC6 | Failure output from the AC1 run searched for the matched token: **0 occurrences**, and 0 for the fixture's surrounding line. Mutation: line 957's `\| cut -d: -f1,2` removed → the run prints `fixture-leak.md:2:the <name> profile treats it as canonical`, 1 occurrence. The redaction is load-bearing | ✅ |
| AC7 | `for t in tests/*.test.sh; do "$t" \|\| true; done` over all **27** files: every file `0 failed` (tallies pasted per file, not summed). Re-run after `0148` was filed, since `citations`, `falsifiable-acs`, `item-ac-form` and `graph-fields` all read the new item — still 27/27 | ✅ |
| NFR Security | `.private-names` is git-ignored (`.gitignore:12`) and `git ls-files --error-unmatch` reports `did not match any file(s) known to git`. The guard's own `the configured name list is not tracked` case was falsified by pointing `PRIVATE_NAMES_FILE` at a tracked file → `FAIL … the configured name list is TRACKED by git, so the names are published`, `119 passed, 2 failed`. Token withheld from failure output: AC6 | ✅ |
| NFR Compatibility | All seven `HOME_PATH_PAT` cases green in every run above, including each mutated one — the two blocks are independent | ✅ |
| FR2 (redaction quality) | Read the 18 replaced lines as they now stand: *an internal repository*, *the company's Jira*, *the company's design-system MCP*, *That internal repository routes to Jira under company policy*. Each sentence still carries what the name was there for | ✅ |

**Probes past the criteria.** Recorded here because a bare PASS does not show what was covered:

- 🔍 Comments-and-blanks-only list (empty after parse) → `ok  internal-name check not applicable — the configured list holds no names`, `121 passed, 0 failed`. The two not-applicable paths are separate branches and both are reached.
- 🔍 List pointed at a tracked file → reds, as above. `PRIVATE_NAMES_FILE` can name any path, so the `.gitignore` rule alone would not have covered it; the belt-and-braces case earns its place.
- ⚠️ **A malformed list entry silently disables the whole check and the suite still reports `0 failed`.** `git grep` exits 1 for no match and **128** for a pattern it cannot compile, and the single `elif` on its status cannot separate them, so both take the clean-tree branch. With `Zorp(tech` in the list and a real leak in the tracked set: `fatal: … parentheses not balanced` on stderr, then `ok  no tracked file publishes a configured internal organisation or client name`, `121 passed, 0 failed`. **Not a failure of this ticket** — none of its seven criteria covers a malformed list — so it is filed as **`0148`** (`3ecf3b7`), not handed back. It is one branch from the `cut`-status defect this build already found and fixed, which is why the row cites that note.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a `verify` park on `0111`. The park found one item file; the
  retro's own `git grep` found five files, which is why FR2 is scoped by a search and not by a list.
  Written without naming the token, on the reading of `0122` that is safe under both answers.
- **2026-09-09 (develop, 8ca0)** — **The scope was eight tracked files and eighteen lines, not
  five files.** The Problem section's count was a cache of the retro's own grep taken the same day,
  and `FINDINGS.md` — one of the five — was drained by `c666eb6` between the filing and this claim.
  Four of the five remained; four more files the retro's narrower search did not reach were found by
  running FR1's guard, which is the search FR1 said to use. The count moved in both directions at
  once, which is why the FR was right to scope by a search and not by a list.
- **2026-09-09 (develop, 8ca0)** — **`CLAUDE.md`'s own statement of the rule was redacted too, and
  that is the answer this row was allowed to give.** *Out of scope* requires the row to be correct
  under either answer to `0122` (whether a rule's prose may name what it forbids). Redacting is
  correct under both; leaving it is correct under only one. `0122` is therefore still open and this
  row did not decide it — but it no longer has a live occurrence to decide *about* in this repo.
- **2026-09-09 (develop, 8ca0)** — **AC3 has no tree-level form, and the substitution is recorded at
  the check.** AC3's red-making mutation ("dropping the exemption flags this item file itself")
  needs a tracked file holding a wrapped internal name; committing one is exactly what the Security
  NFR forbids, so the state is unreachable by construction rather than by oversight. The claim is
  carried instead by the falsification control's assembled samples over a synthetic list of its own,
  and the paragraph naming what the control does *not* prove sits beside it in
  `tests/measurement.test.sh` — because the next QA pass reads the plan, not this note. **Verify
  should read AC3 as satisfied by that control or bounce the substitution, not look for the file.**
- **2026-09-09 (develop, 8ca0)** — **The control drives a synthetic list rather than the configured
  one, deliberately.** A control that only runs where a real list happens to exist is green by
  construction on every machine that has not configured one — including a fresh clone and any CI
  box — which is precisely the check that cannot fail. Driving it from a list the control writes
  itself makes the exemption and the pattern testable everywhere, and is what lets AC2's
  not-applicable path coexist with FR4 rather than cancel it.
- **2026-09-09 (develop, 8ca0)** — **A guard reported a leak it could not name, on a clean tree.**
  `elif named=$(git grep ... | cut ...)` reads `cut`'s status, and `cut` succeeds on empty input, so
  the failure branch fired when the search found nothing. Split into two statements, with the reason
  written at the site. Parked to the conventions repo as a testing-conventions gap: the existing
  rule says to assert the message rather than the status, and does not yet say that a search you
  then format must be a separate statement from its formatting.
- **2026-09-09 (develop, 8ca0)** — **The guard protects a machine that has declared its names and
  cannot protect one that has not.** `.private-names` is machine-local by design (FR1), so a fresh
  clone reports the check not applicable and stays runnable. That is a real hole and the named
  trade, not an oversight: `0118` — reaching the sessions that commit without running a suite — is
  the row that narrows it, and it is unblocked by this one.
