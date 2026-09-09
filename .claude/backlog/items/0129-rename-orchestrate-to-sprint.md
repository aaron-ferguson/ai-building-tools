---
id: "0129"
title: Rename orchestrate to sprint and leave the old command resolving
type: chore
next: develop
status: blocked
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

- [ ] AC1 — Given the repo after this ticket, when `ls skills/` runs, then `sprint/` exists and
      `orchestrate/` does not. **Red if** the directory is copied rather than moved, leaving both.
- [ ] AC2 — Given the live surface, when `grep -rl 'orchestrate' skills/ tests/ references/ tools/
      README.md .claude-plugin/` runs, then the only matches are the FR2 alias and its recorded
      removal date. **Red if** any test, reference or tool still names the old skill.
- [ ] AC3 — Given a session invoking `/orchestrate`, when the skill resolves, then it loads the
      sprint skill and prints the deprecation notice naming the removal version. **Red if** the
      alias is dropped, which makes the command resolve to nothing on every machine that has it.
- [ ] AC4 — Given `.claude/backlog/items/`, when `grep -rl orchestrate items/` runs, then the closed
      item files still contain the historical citations unchanged. **Red if** a bulk `sed` rewrites
      the record of what was verified — the failure `0067` was opened for.
- [ ] AC5 — Given `tests/sprint.test.sh`, when the whole suite runs, then it passes and its own
      tally is non-zero. **Red if** the file is renamed while its asserted phrases still quote the
      old skill's text, or if a rewrap splits an asserted phrase across a line break, which prints
      no tally rather than a failure (`0119`).
- [ ] AC6 — Given the pushed commit, when `tools/release verify` runs, then the resolved install
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
