---
id: "0129"
title: Rename orchestrate to sprint and leave the old command resolving
type: chore
next:
status: done
qa_level: verify
close_by: verify
size: m
created: 2026-09-09
source: user
parent: "0128"
blocked_by: ["0067"]
relates: ["0064"]
expects:
  - skills/orchestrate/SKILL.md
  - skills/orchestrate/outcome.schema.json
  - tests/orchestrate.test.sh
  - tests/skill-size.test.sh
  - tests/last-line.test.sh
  - tests/reporting.test.sh
  - tests/close-by.test.sh
  - references/REPORTING.md
  - tools/harvest-usage.sh
  - README.md
  - .claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - skills/develop/SKILL.md
  - skills/queue/templates/config.yml
claimed_by:
claimed_at:
touches:
                                      # prove AC1 reds on a copy rather than a move; never committed
closed: 2026-09-11
---

## Problem

The skill is named for what it does mechanically — it orchestrates sessions — rather than for the
unit of work it produces. Aaron, 2026-09-08: *"essentially, what we're doing is we are setting up a
Scrum sprint and going through the whole process, ending with a retro."* Every stage the skill drives
maps onto that arc, and `sprint` is the name the arc already has.

**The rename is cross-cutting and this repo has been hurt by one before.** `orchestrate` appears in
**31 files**, measured 2026-09-09. `0067` exists because the last repo-wide rename — effort → project,
27 files — reddened `0005`'s held guard mid-pass and tagged its commits with another ticket's live
claim token. Twenty-one of those 27 files were **closed tickets**, and whether a rename may rewrite
the record of what was verified is the open question `0067` must settle. That is why this row is
blocked rather than merely careful.

**The live surface and the historical record are different things.** The skill directory, the tests,
`README.md`, `references/REPORTING.md`, `tools/harvest-usage.sh`, the plugin manifests and
`skills/queue/templates/config.yml` are what runs. The item files under `.claude/backlog/items/` —
`0036`, `0039`, `0040` and the rest — are the record of what was true when they were written.

**Other machines install this plugin.** `CLAUDE.md`: *"other machines install this plugin and this
project's own sessions run it."* `deprecation-conventions.md` requires a replacement path, notice
proportional to switching cost, and a recorded owner and date — and it applies to this repo's own
tooling, not only to what it ships to customers.

## Functional requirements

- FR1 — The skill directory is `skills/sprint/`, its `SKILL.md` and `outcome.schema.json` move with
  it, and the skill's `name` and description are updated in whatever registry the plugin manifests
  hold.
- FR2 — `/orchestrate` continues to resolve to the same skill for at least one released version,
  with a recorded removal version and date, per `deprecation-conventions.md`.
- FR3 — Every **live** citation of `orchestrate` resolves to `sprint`: the test files, `README.md`,
  `references/REPORTING.md`, `tools/harvest-usage.sh`, `skills/develop/SKILL.md`, and
  `skills/queue/templates/config.yml`.
- FR4 — **Closed backlog item files are not rewritten**, subject to whatever `0067` settles; if
  `0067` decides otherwise, this ticket follows that decision rather than this FR.
- FR5 — `tests/orchestrate.test.sh` becomes `tests/sprint.test.sh` and every guard inside it that
  asserts a phrase from the skill still matches after the rename. Guards grep prose and `grep` is
  line-based, so a phrase moved across a line break by rewrapping cannot be matched at all
  (`CLAUDE.md`, *Tests*).
- FR6 — The version is bumped and the install updated through `tools/release`, whose final step
  diffs the resolved install directory against the pushed commit. A renamed skill directory is
  precisely the change a version-keyed cache can fail to re-extract while reporting success
  (`CLAUDE.md`).

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | The alias is the additive half; removing `/orchestrate` is a later, separate change with its own notice | `migration-conventions.md` |
| Documentation | `README.md` and `references/REPORTING.md` name the new command; the removal date for the alias is recorded where a reader will find it | `documentation-conventions.md` |
| Dependencies | None added — a rename introduces no package | `dependency-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given the repo after this ticket, when `ls skills/` runs, then `sprint/` exists and
      `orchestrate/` does not. **Red if** the directory is copied rather than moved, leaving both.
- [x] AC2 — Given the live surface, when `grep -rl 'orchestrate' skills/ tests/ references/ tools/
      README.md .claude-plugin/` runs, then the only matches are the FR2 alias and its recorded
      removal date. **Red if** any test, reference or tool still names the old skill.
- [x] AC3 — Given a session invoking `/orchestrate`, when the skill resolves, then it loads the
      sprint skill and prints the deprecation notice naming the removal version. **Red if** the
      alias is dropped, which makes the command resolve to nothing on every machine that has it.
- [x] AC4 — Given `.claude/backlog/items/`, when `grep -rl orchestrate items/` runs, then the closed
      item files still contain the historical citations unchanged. **Red if** a bulk `sed` rewrites
      the record of what was verified — the failure `0067` was opened for.
- [x] AC5 — Given `tests/sprint.test.sh`, when the whole suite runs, then it passes and its own
      tally is non-zero. **Red if** the file is renamed while its asserted phrases still quote the
      old skill's text, or if a rewrap splits an asserted phrase across a line break, which prints
      no tally rather than a failure (`0119`).
- [x] AC6 — Given the pushed commit, when `tools/release verify` runs, then the resolved install
      directory matches it. **Red if** the version is not bumped, since the cache is keyed by
      version and nothing is re-extracted while the record is updated anyway.

## QA plan

- **Why that level:** no test runner applies to a directory rename and a set of prose citations, but
  every criterion above is a mechanical check — a path test, a `grep`, and `tools/release verify`.
- **Specific checks:** the full suite `for t in tests/*.test.sh; do "$t" || true; done` run
  file-by-file rather than fail-fast, so a red is attributed to this ticket rather than to another
  session's in-flight work (`config.yml`, `commands.unit`); `tools/release verify`; and the AC2 and
  AC4 greps run as written.

## Out of scope

- Removing the `/orchestrate` alias. That is a later change with its own notice period.
- Any behaviour change to the skill. This ticket moves and renames; `0130` through `0135` change
  what it does.
- Deciding whether a cross-cutting rename may rewrite closed tickets — that is `0067`.

## Notes & decisions

- **2026-09-09 — routed to `develop`, blocked on `0067`.** No design question is open *here*: the
  new name is chosen and the surface is enumerable. What is unsettled is the shape any cross-cutting
  rename takes in this backlog, which is `0067`'s question and applies to more than this rename.

- **2026-09-10 — built, `cfec`. The alias is a plugin COMMAND, not a second skill directory**, which
  is what lets FR2 and AC1 both hold: AC1 requires `skills/orchestrate/` to be gone, so the alias
  cannot live there. `commands/orchestrate.md` is new to this repo and the mechanism is observed
  rather than assumed — the `vercel` plugin in the official marketplace ships `commands/*.md` at its
  root, and the descriptions in those files are exactly what this session's own skill listing shows
  for `vercel:deploy` and its siblings. A plugin command surfaces under the same `plugin:name`
  namespace a skill does, so `/orchestrate` resolves exactly where it did.

- **The ticket's figures were caches and both were wrong low.** The Problem section says
  `orchestrate` appears in 31 files; it is 50 (2026-09-10), of which 17 are live surface. FR3
  enumerates the live citations and misses five: `skills/retro/SKILL.md`,
  `skills/queue/templates/next` with its installed copy `.claude/backlog/next`,
  `tests/next.test.sh`, `tools/validate-json-schema.py` and `.claude/backlog/config.yml`. FR3's
  *rule* — every live citation resolves — is what was built to; its list is not the contract. AC2's
  guard is a sweep for the same reason.

- **`ORCHESTRATE_SKIP_PROBE` went with it, and it is the one interface change here.** The env var
  that makes AC22's nested-dispatch probe skip loudly is now `SPRINT_SKIP_PROBE`. It is named in no
  other file, so nothing else needed changing; anyone who had it exported gets the probe back rather
  than a silent skip, which is the safe direction.

- **Eight open sibling tickets still name the moved paths in `expects:`** — 0041, 0054, 0089, 0132,
  0133, 0134, 0135, 0137. This session did not touch them. 0067's rule permits a rename to rewrite
  open unheld items, but it is written about the backlog's own vocabulary rather than about a
  product rename, and *A stage writes only the ticket it holds* points the other way; the tie-break
  is not this ticket's to make. Parked in `FINDINGS.md`. **This still needs a row** — no row exists
  for it.

- **AC6 — released as 0.9.25, on the author's explicit authorisation.** `tools/release` pushes to a
  public remote, which `develop` Step 5 and `git-conventions.md` both make the author's call rather
  than this stage's, so it was asked before the run and `--yes` carries that answer. The chain
  verified the bytes: 230 tracked paths identical to `59d4b2d`, and the recorded `gitCommitSha`
  agrees. The resolved install carries `skills/sprint/` and `commands/orchestrate.md` and has no
  `skills/orchestrate/` — which is the check that matters here, a renamed directory being precisely
  what a version-keyed cache can fail to re-extract while reporting success (`CLAUDE.md`).
  **A restart is required before `/orchestrate` or `/sprint` resolves to the new copy**: skills
  resolve once at session start, so AC3's end-to-end half — a session invoking the alias and seeing
  the notice — is only observable in a session started after this release, never in this one.

## QA evidence

Verified 2026-09-10, token `841c`, at `qa_level: verify`. Tree clean at Step 2 (`git status
--porcelain` empty) and clean at verdict. Suite run file-by-file per `config.yml`'s note, never
fail-fast: **29 test files, 0 failed**, tallies pasted from each file's own output.

| # | Criterion | How it was checked | Result |
|---|---|---|---|
| AC1 | `sprint/` exists, `orchestrate/` does not | `ls skills/` → `design develop prototype queue retro sprint verify`. Commit `bb8b778` records `R098 skills/orchestrate/SKILL.md → skills/sprint/SKILL.md` and `R100` for the schema — a git-recorded rename, not a copy. **Mutation:** recreated `skills/orchestrate/SKILL.md` → `FAIL AC1 — skills/orchestrate still exists: the directory was copied rather than moved`, 163 passed / 1 failed; restored, control green | PASS |
| AC2 | live surface names the old skill only at the alias | `grep -rl 'orchestrate' skills/ tests/ references/ tools/ README.md .claude-plugin/` → `README.md` alone, line 17, the deprecation notice. The `commands/orchestrate.md` alias is the FR2 home. **Mutation:** appended `# see the orchestrate skill` to `tools/harvest-usage.sh` → `FAIL AC2 — the retired name is still cited as live in: tools/harvest-usage.sh`; restored | PASS |
| AC3 | `/orchestrate` resolves and prints the notice | `commands/orchestrate.md` present, naming `/sprint`, `skills/sprint/SKILL.md`, `Deprecated`, owner `Aaron Ferguson`, removal `2026-12-10`. End-to-end half observed live: this session started after the 0.9.25 release and its skill listing carries `ai-building-tools:orchestrate — Deprecated alias for /sprint … Removed on or after 2026-12-10 — use /sprint` alongside `ai-building-tools:sprint`. The alias was **not invoked** — doing so starts a backlog-driving run. **Mutations:** alias file moved away → `FAIL AC3 — commands/orchestrate.md is absent`; owner rewritten to "the team" → `FAIL AC3 — the alias does not state Aaron Ferguson`; both restored | PASS |
| AC4 | closed item files keep their historical citations | `grep -rl orchestrate items/` → 26 files, counts intact (`0036`:7, `0039`:44, `0040`:7, …). `git show --name-status bb8b778` touches exactly one item file, `0129`'s own; `git diff --name-only bb8b778~1 0c8f65f -- .claude/backlog/items/` returns only `0129`. No bulk `sed` reached the record | PASS |
| AC5 | `tests/sprint.test.sh` passes with a non-zero tally | `tests/orchestrate.test.sh` is gone (`R094` in `bb8b778`); `tests/sprint.test.sh` prints `164 passed, 0 failed, 0 skipped`, and its `SKILL=` resolves to `skills/sprint/SKILL.md`. **Mutation:** split the asserted phrases `CLAUDE.md auto-discovery` and `no conventions` across line breaks in the skill → `FAIL AC1 — the skill bans --bare without saying it means no conventions`, 163 passed / 1 failed **with a tally printed**; restored, control green at 164/0. A first attempt splitting only the one phrase stayed green — that guard is a two-branch `||`, so both branches had to move | PASS |
| AC6 | install matches the pushed commit | `tools/release verify` **reported FAILED** and the red is not this ticket's: it compares the install against `HEAD` (`7726456`), which has advanced past the release by three backlog commits, and its three differing paths are `QUEUE.md`, `items/0107` (another session's claim) and `items/0129` (this stage's claim) — no product path among them. The AC's own condition was checked directly instead: worktree at the released commit `59d4b2d`, `diff -rq` against `~/.claude/plugins/cache/ai-building-tools/ai-building-tools/0.9.25` → **all 230 tracked paths identical**, only the runtime `.in_use` marker extra. The install carries `skills/sprint/` and `commands/orchestrate.md` and no `skills/orchestrate/`, so the version-keyed cache did re-extract. AC6's stated "Red if" — the version not bumped — is absent. Parked in `FINDINGS.md`; needs a row | PASS |

**NFRs.** *Migration* — the alias is purely additive: `bb8b778` adds `commands/orchestrate.md` and
removes no entry point; the removal of `/orchestrate` is out of scope with its own notice.
*Documentation* — `README.md` lines 15–18 name `/sprint` in the skill table and record the
deprecation with its removal date; `references/REPORTING.md` line 100 cites
`skills/sprint/outcome.schema.json`. *Dependencies* — no package manifest in the diff; none added.

**Always-on pass (`CONVENTIONS_CORE.md`).** No secrets, log fields, analytics events or egress
destinations in the diff, so no `data-privacy-conventions.md` trigger; no auth, credential or
data-visibility surface, so no Security gap; no UI, so no Accessibility gap. `company: none` holds —
`tests/measurement.test.sh` passes 129/129 including its guard that no tracked file publishes a
configured internal organisation or client name. **Newly reachable:** one new entry point,
`/orchestrate` as a plugin command. It is a strict alias — it prints the notice and reads
`skills/sprint/SKILL.md` — so it adds no state or action the skill did not already offer.

**Advisory:** not advisory. Dirty set empty at Step 2 and at verdict; intersection with the evidence
set therefore empty.
