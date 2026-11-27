---
id: "0064"
title: Make the copy of a skill that runs provably the released one
type: bug
next:
status: done
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0026", "0061", "0084", "0129", "0157"]
expects:
  - skills/verify/SKILL.md
  - skills/design/SKILL.md
  - skills/develop/SKILL.md
  - skills/queue/SKILL.md
  - skills/prototype/SKILL.md
  - skills/retro/SKILL.md
  - README.md
  - CLAUDE.md
  - tools/release
  - tests/release.test.sh
ac_digest: AC1=3990b053 AC2=5b6d0b3f AC3=63686a6f AC4=44ecaa4e AC5=8f89b56f AC6=bb74f016 AC7=c6a73335
claimed_by:
claimed_at:
touches:
slice: S2
closed: 2026-11-27
---

## Problem

**Outcome (merged 2026-11-26, at the user's direction):** a session can tell which installed copy of a stage it is running, and that the copy matches the commit that was released. A rule can no longer be reported missing on the day it shipped.

A stage whose name collides with a built-in skill is a stage that can silently not run. The session
that verified 0026 invoked `/verify` and loaded the **built-in** evidence-capture skill rather than
`ai-building-tools:verify`; this repo's stage protocol had to be read out of
`skills/verify/SKILL.md` by hand afterwards. Nothing in the run said which skill had answered.

The specific collision the finding named may or may not still exist, and this ticket does not
depend on it: **the class is live now on a different name.** The skill listing available to a
session in this repo today carries a built-in `design` — a canvas-authoring skill — alongside
`ai-building-tools:design`, the stage that settles a backlog decision. Those are unrelated jobs with
one short name, and the failure is silent in the worst direction: the built-in answers, produces
something plausible, and the ticket at `next: design` is never touched.

The stakes are higher than a mis-typed command because these skills *write*. A stage session that
believes it is `ai-building-tools:design` will hand off a ticket, edit `QUEUE.md` and commit; one
that has actually loaded a different skill will not, and the queue is left saying the row moved.

Two facts make this cheap to fix and easy to keep missing. The plugin-qualified form
(`/ai-building-tools:design`) always resolves correctly and is never ambiguous. And a skill can say
what it is in its first line, which turns a silent mis-resolve into something a reader notices in
the transcript.

### Absorbed 2026-11-26: 0157 — Make release verify compare the install against the released commit

**`tools/release verify` compares the install against `HEAD`, so it goes red on the first backlog
commit after a release.** Three claim commits after a release it reported `FAILED -- the install does
not hold 7726456` over `.claude/backlog/QUEUE.md` and two item files, and `record FAILED --
gitCommitSha is 59d4b2d` where 59d4b2d was the released commit and the record correct. Every
differing path was backlog state. The substitute that answered the real question was
`git worktree add --detach <path> <released-sha>` then `diff -rq` against the install: 230 paths
identical (verify 0129 AC6).


## Functional requirements

- FR1 — Each of the six stage skills opens by naming itself unambiguously — the plugin and the
  skill — so a session that loaded a different skill of the same name is visible in its own output.
- FR2 — `README.md` documents the plugin-qualified invocation form as the one to use, and says why:
  a bare name can resolve to a built-in or another plugin, silently.
- FR3 — `CLAUDE.md`'s existing paragraph on the installed copy being what runs also covers *which*
  skill answered, since both are the same failure — a session executing something other than what
  this repo contains — and today it covers only the version.
- FR4 — Any place in this repo that tells a reader to invoke a stage by bare name is updated to the
  qualified form, so the documentation does not itself recommend the ambiguous call.
- FR5 *(was 0157 FR1)* — `verify` compares against the commit the installed version was released at (the record's `gitCommitSha`, or the bump commit for that version), never `HEAD`.
- FR6 *(was 0157 FR2)* — the comparison excludes `.claude/backlog/` and reports it excluded.


## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The invocation form is documented where a new reader starts (`README.md`) and where a session in this repo reads its own rules (`CLAUDE.md`) | `documentation-conventions.md` |
| Progressive delivery | The skills ship to every machine installing the plugin, and a name collision depends on what else that machine has installed — so the fix must work without knowing what else is there | `progressive-delivery-conventions.md` |
| Observability | (0157) The report names the commit compared against and why that one. | A report naming only `HEAD`. | `observability-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given each of the six `skills/*/SKILL.md` files, when the opening lines are read, then
  each names the plugin and the skill.
- [x] AC2 — Given `README.md`, when read, then it names the plugin-qualified invocation form and
  says a bare name can resolve elsewhere.
- [x] AC3 — Given `CLAUDE.md`, when read, then its paragraph on what actually runs covers which
  skill answered, not only which version.
- [x] AC4 — Given every shipped file in this repo, when grepped for an instruction to invoke a
  stage by bare name, then none remains outside of prose quoting a user's words.
- [x] AC5 — Given the whole suite, when it runs, then every suite passes — including
  `tests/skill-size.test.sh`, with a recorded justification naming this ticket for any file pushed
  over its goal.
- [x] AC6 *(was 0157 AC1)* — Given a fixture release followed by a commit touching only `.claude/backlog/`, when `tools/release verify` runs, then it passes. Red-making input: today's HEAD comparison.
- [x] AC7 *(was 0157 AC2)* — Given a fixture release followed by a commit changing `skills/`, not released, when `verify` runs against an install of the released commit, then it passes; and given the install altered, it fails. Red-making change: excluding everything.


## Progress

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").

- [x] S1 — a stage skill says which copy of it is running — discharges AC1, AC2, AC3, AC4, AC5
- [x] S2 — `tools/release verify` compares the install against the released commit (0157) — discharges AC6, AC7


## QA plan

- **Level:** verify — the deliverable is prose across eight files and no test runner applies; the
  scripted assertions are the greps below plus the size guard.
- **Why this level:** nothing executable changes, and each AC is a grep with a named phrase.
- **Specific checks:** AC1 is a loop over the six skill files asserting on their opening lines
  specifically, not on the file. AC4 is a repo-wide grep whose expected result is empty — write it
  so that a match prints the offending file and line, since an absence assertion that only exits
  non-zero cannot say what it found. Then `tests/skill-size.test.sh` and the full suite.

### From 0157

- **Why that level:** `unit` — `tests/release.test.sh` already scaffolds fixture releases.
- **Specific checks:** `tests/release.test.sh`.


## Out of scope

- **Renaming any skill.** It would break every reference in this repo, in `RANKING.md`, in 40-odd
  item files and in whatever other machines have installed — a migration far larger than the
  failure, and the qualified-invocation form removes the harm without it. If renaming is ever
  wanted it is its own ticket with its own migration plan.
- **Detecting the collision automatically.** A guard here would have to know what else is installed
  on the machine, which this repo cannot see. FR1 makes it visible in the transcript instead.
- Whether the *installed* copy matches this repo. That is 0061 — the same family, a different axis.

### From 0157

- 0061's question of how a session learns the install differs.


## Notes & decisions

- Routed to `develop`: FR1's mechanism is a line of prose per file, and the qualified-invocation
  form is a fact about how skills resolve rather than a decision. Renaming, the only option that
  would have needed a design pass, is ruled out in *Out of scope* on migration cost.
- **The finding's specific example is treated as unverified and the ticket does not rest on it.**
  Whether `/verify` still collides could not be confirmed from inside this session; the `design`
  collision was confirmed from the skill listing this session was given. The FRs are written against
  the class so that neither answer changes the work.

### From `FINDINGS.md`, landed 2026-09-05

- **The `/verify` instance, recorded in full — and it belongs beside the note above that the ticket
  does not rest on it** (FINDINGS 2026-08-30). What was observed: typing `/verify` in this repo
  loaded a bundled Claude Code skill of the same name — a runtime-observation skill whose opening
  rules are "Don't run tests. Don't typecheck" and "the scope is a diff" — rather than
  `ai-building-tools:verify`, which reads a ticket's acceptance criteria and whose declared
  `qa_level` for almost every row in this backlog **is** a scripted assertion. The two are not merely
  different, they are inverses on the one instruction that matters. A session following the loaded
  skill would have refused to run `tests/reporting.test.sh`, reported SKIP for "no runtime surface",
  and closed nothing, because the bundled skill has no concept of a backlog row. It was caught only
  because the operator noticed the base directory in the skill header — which is the detection method
  FR1 is meant to replace, and evidence that it works when someone happens to look. The same
  collision is available for `design` and `run`. The finding's own fix direction matches FR1–FR4: a
  distinguishing name, or a line telling a session to invoke the plugin-qualified form explicitly.
- **2026-10-17 (retro, absorbed from AetherWorks FINDINGS.md).** A fourth occurrence: bare `/verify` loaded the bundled skill during AetherWorks 0095's verify with CLAUDE.md's *invoke the stage skills as `ai-building-tools:<name>`* warning already in context; caught only by reading that paragraph and the `Hand off 0095 to verify` commit. A rule broken four times is not enforceable as prose — the finding proposed a `UserPromptSubmit` hook or project-level skills shadowing the bundled names, either of which is a stronger form of FR1's distinguishing name. Unverified: whether a hook sees a slash command before expansion.
- 2026-10-28 — **Absorbed 0061**, withdrawn in the triage: how a session learns the installed plugin differs from this repo is this row's question too.
- **2026-11-26 (queue): merged by outcome, at the user's direction.** The 2026-11-26 consolidation grouped the backlog by outcome so a whole outcome is worked in one ticket and its context is paid for once. Absorbed and withdrawn, each id burned and each item file kept as the record:
  - `0157` (Make release verify compare the install against the released commit): FR5–FR6, AC6–AC7
  Each absorbed ticket's Problem is quoted verbatim above, and its FRs, ACs, NFR rows, QA plan, Out of scope and Notes are carried below with `*(was NNNN FRn)*` tags. **Bare FR and AC numbers inside the carried text were renumbered to this ticket's.** A reference to another ticket's criterion not written as `NNNN ACn` may have been renumbered too, and the withdrawn file holds the original. An unspecified slice sends this ticket to `design` when it is next; its open question is below.

- **2026-11-27 (develop, S1 built at 2d3159c9, token 474d).** S1 only; S2 (`tools/release`, 0157) touches no file this leg had open, so the leg ended. The `--slice S1` hand-off goes to `verify`, since S1 discharges AC1–AC5.
  - **FR1 mechanism: the heading.** Each of the six stage skills' first body line is now `# /ai-building-tools:<name>` (prototype's was `# Prototype`). It is the first thing the loaded skill puts in the transcript, so a mis-resolve shows on its first line; no extra sentence was added because `skills/prototype/SKILL.md` sat 34 bytes under its `argued_at` + MARGIN bound (30,361). Prototype absorbed its growth by folding `/prototype` into the `## Invocation` heading and dropping "without repeating earlier steps" from the escalation bullet: 30,358 bytes, no re-argument. Headroom after: queue ~350, develop ~800 bytes.
  - **AC4 — the qualified sites (run).** Every command a stage tells the next session or a person to run: develop's `/design <id>`, `/verify <id>` (×3), `/retro` (×2) and its `/develop 0007` argument example; the `next: /<stage>` example lines in design, prototype, retro, sprint and `references/REPORTING.md`; `templates/item.md`'s *Settle it with*; `templates/handoff`'s refusal stderr (re-copied to `.tickets/handoff`, which `tests/backlog-scripts-installed.test.sh` requires). **Left bare deliberately**, each a name or a user's words, never an instruction to invoke: skill `description:` triggers ("invokes /develop" quotes the user); "Do not invoke `/prototype`/`/retro`"; `queue`'s "bare `/queue`" routing row (what the user typed); README's skill table and its prose about what each skill does; `templates/next` comments; `MEASUREMENT.md`; `CHANGELOG.md` history. **Not a stage, so outside AC4:** `/sprint` and `/orchestrate` — and `tests/sprint.test.sh` pins bare `/sprint` in README's table and `/sprint resume <run-id>` in Step 1, so qualifying them would red two prose guards. The repo-wide grep used: `git ls-files | grep -vE '^\.tickets/|^CHANGELOG|^tests/' | xargs grep -nE '(^|[^a-z:/._-])/(queue|design|prototype|develop|verify|retro)\b'` — every remaining match is in the left-bare list above.
  - **FR2** is a paragraph directly above README's skill table, where a reader starts; the existing line under *To check a new environment* stays. **FR3** extends `CLAUDE.md`'s installed-copy bullet: the name does not prove which skill answered either.
  - AC1 check (run): an awk loop over the six files printed each first non-blank line after the frontmatter, all qualified. Whole suite green after the handoff re-copy; `tests/skill-size.test.sh` 45/0. No mutation run: none of this leg's ACs rests on a guard this leg wrote.

- **2026-11-27 (verify S1, token bfb6): FAIL on AC4, one site.** `README.md:26` reads "Default to `/design` — escalation is cheap" — an imperative telling the reader which stage to run, by bare name. It is not a name in a table, not a description of what a skill does, and not a user's words, so it is outside every left-bare category in the build notes, and AC4 says none remains. **The constraint:** qualify the invoked name in that sentence (`/ai-building-tools:design`), then re-run the AC4 grep and the suite. The rest of that paragraph (`/design` never invokes `/prototype`) is description and stays bare. AC1, AC2, AC3 and AC5 pass on this leg (QA evidence below); no AC ticked, no slice ticked. Drift: frontmatter `qa_level: unit` against the QA plan's `**Level:** verify` — the frontmatter was run.

- **2026-11-27 (develop S1 bounce, token 6b1c, 11fd156e).** `README.md:26` now reads "Default to `/ai-building-tools:design`"; the descriptive `/design never invokes /prototype` after it stays bare, per the verdict's constraint. AC4 grep re-run (run) over README: every remaining match is the skill table, description of what a skill does, or `/sprint` (not a stage) — lines 8, 14–19, 25, 27, 29–30, 36, 41, 208, 440. No guard in `tests/` pins "Default to". Whole suite green, 50 files, 0 failed. No mutation run.

- **2026-11-27 (verify S1 re-entry, token 6dd8): PASS on the S1 leg.** `README.md:26` now reads "Default to `/ai-building-tools:design`"; the AC4 grep's remaining matches are all names in the skill table, descriptions of what a skill does, user's words, the CLAUDE.md warning that quotes the bare form, or `/sprint` (not a stage). Every S1 AC re-checked from this pass's own evidence and mutation (QA evidence below). Handed back to `develop` with `--slice S1`; no AC ticked, since S2 (AC6, AC7) holds the closing verify. Drift still stands: frontmatter `qa_level: unit` against the QA plan's `**Level:** verify` — the frontmatter was run.

- **2026-11-27 (develop S2, token 476c; cd1efb3c, 9743665b, 76d58311, 952b54a2).** S2 built; handed to `verify` with `--slice S2`, since S2 discharges AC6 and AC7 and holds the closing verify.
  - **FR5 mechanism.** `tools/release verify` with no `--commit` no longer defaults to `HEAD`. Each recorded install is compared against its own released commit (`released_commit()`): the record's `gitCommitSha` when it is a commit in the checkout, otherwise the bump commit for the recorded version, meaning the oldest commit of the newest unbroken run whose `plugin.json` carries that version (`bump_commit_for()`). Neither found → refuses, naming the version and `--commit`. An explicit `--commit` behaves as before, and so does the release chain's step 9, which passes the pushed sha.
  - **Why the record sha comes first, not the bump commit.** A stranded-bump release pushes commits after the bump, and the install holds those, so the bump commit would red a correct install. **The second assertion changes shape in that mode.** With the compared commit taken *from* the record, "gitCommitSha equals the compared commit" is true by construction, so the record check becomes "the recorded sha's `plugin.json` carries the recorded version". It still fails on its own (a record whose halves disagree). In the bump-commit fallback and under `--commit` it stays the equality check, so an unusable sha still fails.
  - **FR6: the path the FR names is a stale cache.** The backlog is at `.tickets/` now, and `.backlog/` is a second legacy location (0228, CHANGELOG). The install ships `.tickets/` (0.9.51's cache directory holds it). So all three, `.claude/backlog/ .backlog/ .tickets/`, are excluded from both the diff and the tracked count, and every report prints an `excluded` line naming them. **Observability NFR:** every report prints `compared  <sha>` and, on the next line, why that commit (gitCommitSha / bump commit / `--commit`), each saying "not HEAD" except the `--commit` one.
  - **AC6's default case never reaches the FR6 exclusion** (run, mutation M3 below): the released tree has no post-release backlog commit in it, so the default passes on FR5 alone. The exclusion is guarded by a separate case, an explicit `--commit` at the claim commit.
  - **Mutations (run, each on committed code, restored by `git checkout --`, control 87/0 after):** M1 the default reverted to `HEAD` → 6 FAIL (AC6 ×3, AC7 pass-case, FR5 fallback ×2). M2 "excluding everything" (the AC7 red-making change, `not_backlog` emits nothing) → 7 FAIL, including AC7 "an altered install verified clean". M3 no exclusion → 1 FAIL, FR6 explicit-commit case. M4 the record assertion always equality → 0 FAIL at first, so the record-version case was added in 9743665b; re-run → 2 FAIL.
  - **Real install (run):** `tools/release verify` against plugin 0.9.51, with backlog commits and this leg's commits on top: verified, compared against `4a989e4` (its gitCommitSha), 104 tracked paths identical, record ok.
  - **Clause table (AC6, AC7).** AC6: Given "a fixture release followed by a commit touching only `.claude/backlog/`" (case: `s2` clone, commit "Claim 0001"); when "`tools/release verify` runs" (no `--commit`); then "it passes" (`verify passes after a backlog-only commit`). AC7: Given "a fixture release followed by a commit changing `skills/`, not released" (commit "Unreleased skill change"); when "`verify` runs against an install of the released commit" (`S2INST` from `git archive $SHA`); then "it passes" (`verify passes over an unreleased skills/ commit`); and "given the install altered, it fails" (`verify fails once the install is altered`, naming `skills/demo/SKILL.md`).
  - Whole suite at 76d58311: 50 files, 0 red. The 952b54a2 change touches only `tools/release` and `tests/release.test.sh`, and the release suite is green at 87/0 there. `CHANGELOG.md` was left alone because its entry is verify's `./close --note`. **Stale prose, not edited (outside touches):** `CLAUDE.md:49` says the chain diffs "against the pushed commit" and that `verify` "makes that comparison on its own"; on its own it now compares against the released commit, which is the pushed commit for a release this tool made.

- **2026-11-27 (verify S2, closing leg, token 593c): PASS on every AC.** S2 (AC6, AC7) checked literally with this pass's own mutations; S1's ACs (AC1–AC5) re-checked, since the closing verify checks all of them, and no file S1 rests on changed since `11fd156e`. AC6's Given names `.claude/backlog/` only while the guard's fixture also touches `.backlog/` and `.tickets/`; a literal variant (commit touching only `.claude/backlog/`) was run and passes 87/0, so the superset fixture hides nothing. Stale prose noted by develop at `CLAUDE.md:49` ("against the pushed commit") stays true for a release this tool made and is not an AC. Drift still stands: frontmatter `qa_level: unit` against the QA plan's `**Level:** verify` — the frontmatter was run.

### Carried notes of the absorbed tickets

### From 0157 — Make release verify compare the install against the released commit

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** One buffer entry; filed because the tool the release chain ends on is red within minutes of every release in this repo.

## QA evidence

**S1 leg, 2026-11-27, verify token bfb6 — FAIL (AC4).** Copy executed: installed plugin 0.9.51; repo checkout is the authority for the change under test (`2d3159c9`).

Conventions: ../ai-building-conventions

Command (frontmatter `qa_level: unit`; QA plan prose says `verify` — drift, frontmatter run), per-file form `commands.unit_by_file`:
`for t in tests/*.test.sh; do "$t" || true; done` — 50 files, every one exit 0, 0 failed in each tally (e.g. `tests/skill-size.test.sh` "45 passed, 0 failed", `tests/next.test.sh` "815 passed, 0 failed", `tests/release.test.sh` "71 passed, 0 failed"). `./next --ac-digest 0064 --check`: `0064: ac_digest matches`.

Clause table (S1's ACs): AC1 Given "each of the six `skills/*/SKILL.md` files" (plural — six differing files), predicate "opening lines are read", object "names the plugin and the skill". AC2 Given `README.md`, objects "plugin-qualified invocation form" and "a bare name can resolve elsewhere". AC3 Given `CLAUDE.md`, object "paragraph on what actually runs covers which skill answered, not only which version". AC4 Given "every shipped file in this repo", predicate "grepped for an instruction to invoke a stage by bare name", object "none remains outside of prose quoting a user's words". AC5 Given "the whole suite", object "every suite passes — including `tests/skill-size.test.sh`", qualifier "recorded justification naming this ticket for any file pushed over its goal".

| AC | How checked | Evidence paths | Result |
|---|---|---|---|
| AC1 | Scripted loop asserting the first non-blank body line of each of the six files equals `# /ai-building-tools:<name>`: "AC1 green: 6/6". Mutation: prototype heading back to `# Prototype` → "AC1 RED skills/prototype/SKILL.md: # Prototype", exit 1; restored by path, green | `skills/{queue,design,prototype,develop,verify,retro}/SKILL.md` | PASS |
| AC2 | Read `git show 2d3159c9 -- README.md`: new paragraph above the skill table — "Invoke each skill by its plugin-qualified name … A bare name can resolve to a built-in skill or another plugin's skill of the same name, silently". Prose, unguarded by design (CLAUDE.md, *No new guard greps prose*) | `README.md` | PASS (read; unguarded) |
| AC3 | Read the installed-copy bullet in `CLAUDE.md`: "Nor does the skill's name prove *which* skill answered … Invoke the stages as `/ai-building-tools:<name>`". Prose, unguarded | `CLAUDE.md` | PASS (read; unguarded) |
| AC4 | The build notes' grep, `git ls-files \| grep -vE '^\.tickets/\|^CHANGELOG\|^tests/' \| xargs grep -nE '(^\|[^a-z:/._-])/(queue\|design\|prototype\|develop\|verify\|retro)\b'`, plus a broader `run\|invoke\|use … <stage>` grep; every match classified by hand. Mutation: `skills/develop/SKILL.md:610` reverted to `/verify <id>` → grep printed `skills/develop/SKILL.md:610:`; restored. **Gap: `README.md:26` "Default to `/design`"** is an instruction to invoke a stage by bare name | `README.md`, `MEASUREMENT.md`, `CLAUDE.md`, `skills/**/SKILL.md`, `skills/queue/templates/next`, `references/`, `docs/` | **FAIL** |
| AC5 | Whole suite green (above). Mutation: 201 bytes appended to `skills/prototype/SKILL.md` → `tests/skill-size.test.sh` "FAIL skills/prototype/SKILL.md is 30559 bytes … 44 passed, 1 failed"; restored → "45 passed, 0 failed". No file pushed over its goal, so no justification owed | `tests/*.test.sh`, `skills/prototype/SKILL.md` | PASS |
| NFR Documentation | README and CLAUDE.md both carry the form (AC2, AC3); `documentation-conventions.md` — documented where a reader starts | `README.md`, `CLAUDE.md` | holds; unguarded (prose) |
| NFR Progressive delivery | The heading and qualified form work regardless of what else is installed — no machine-specific detection added | `skills/*/SKILL.md` | holds; unguarded (prose) |
| NFR Observability (0157) | S2's row; not this leg | — | n/a this leg |

Dirty set at Step 2: empty. Dirty set at verdict: empty. Intersection: empty — not advisory.

**S1 leg re-entry, 2026-11-27, verify token 6dd8 — PASS (S1: AC1–AC5).** Copy executed: installed plugin 0.9.51; repo checkout is the authority for the change under test (`11fd156e`, HEAD `80a9179a` at run).

Conventions: ../ai-building-conventions

Command (frontmatter `qa_level: unit`; QA plan prose says `verify` — drift, frontmatter run), per-file form `commands.unit_by_file`:
`for t in tests/*.test.sh; do "$t" || true; done` — 50 files, 50 tallies, every tally `0 failed` (e.g. `tests/skill-size.test.sh` "45 passed, 0 failed"). `./next --ac-digest 0064 --check`: `0064: ac_digest matches`.

Clause table: reused from the prior round (above), unchanged.

| AC | How checked | Evidence paths | Result |
|---|---|---|---|
| AC1 | Scripted loop, first non-blank body line of each of six files equals `# /ai-building-tools:<name>`: "AC1 green: 6/6". Mutation: prototype heading → `# Prototype` gave "AC1 RED skills/prototype/SKILL.md: # Prototype", "AC1 green: 5/6", exit 1. Restored by path; control "AC1 green: 6/6" | `skills/{queue,design,prototype,develop,verify,retro}/SKILL.md` | PASS |
| AC2 | Read `README.md` lines 7–10: "Invoke each skill by its plugin-qualified name … A bare name can resolve to a built-in skill or another plugin's skill of the same name, silently". Prose, unguarded by design | `README.md` | PASS (read; unguarded) |
| AC3 | Read `CLAUDE.md`'s installed-copy bullet: "Nor does the skill's name prove *which* skill answered … Invoke the stages as `/ai-building-tools:<name>`". Prose, unguarded | `CLAUDE.md` | PASS (read; unguarded) |
| AC4 | Same grep as the prior round: `git ls-files \| grep -vE '^\.tickets/\|^CHANGELOG\|^tests/' \| xargs grep -nE '(^\|[^a-z:/._-])/(queue\|design\|prototype\|develop\|verify\|retro)\b'`. Every match classified: `README.md:26` now qualified; remaining README lines 8, 14–19, 25, 26 (trailing descriptive `/design never`), 27, 29–30, 36, 41, 208, 440 are table names or descriptions; `CLAUDE.md:35–36` quotes the bare form as the warning; skill `description:` lines quote the user; "Do not invoke" lines; `skills/queue/templates/next` comments; `MEASUREMENT.md:674`; `skills/prototype/SKILL.md` path/footer mentions. Mutation: `README.md:26` reverted to "Default to `/design`" → grep printed `README.md:26:Default to \`/design\``. Restored by path; control printed the qualified line | `README.md`, `CLAUDE.md`, `MEASUREMENT.md`, `skills/**/SKILL.md`, `skills/queue/templates/next` | PASS |
| AC5 | Whole suite green (above). Mutation: 250 bytes appended to `skills/prototype/SKILL.md` → "FAIL skills/prototype/SKILL.md is 30608 bytes … 44 passed, 1 failed"; restored by path → "45 passed, 0 failed". No file over its goal, so no justification owed | `tests/*.test.sh`, `skills/prototype/SKILL.md` | PASS |
| NFR Documentation | README and CLAUDE.md both carry the form (AC2, AC3) | `README.md`, `CLAUDE.md` | holds; unguarded (prose) |
| NFR Progressive delivery | Heading and qualified form need no knowledge of what else is installed | `skills/*/SKILL.md` | holds; unguarded (prose) |
| NFR Observability (0157) | S2's row; not this leg | — | n/a this leg |

Dirty set at Step 2: empty. Dirty set after the last evidence command: empty. Intersection: empty — not advisory.

**S2 leg, closing verify, 2026-11-27, verify token 593c — PASS (AC1–AC7).** Copy executed: installed plugin 0.9.51; repo checkout is the authority for the change under test (`cd1efb3c`..`952b54a2`, HEAD `a9e4a32b` at run).

Conventions: ../ai-building-conventions

Command (frontmatter `qa_level: unit`; QA plan prose says `verify` — drift, frontmatter run), per-file form `commands.unit_by_file`:
`for t in tests/*.test.sh; do "$t" || true; done` — 50 files, 50 tallies, every tally `0 failed`, no file exited non-zero (`tests/release.test.sh` "87 passed, 0 failed", `tests/skill-size.test.sh` "45 passed, 0 failed"). `./next --ac-digest 0064 --check`: `0064: ac_digest matches`.

Clause table: AC1–AC5 reused from the S1 rounds above. AC6 — Given "a fixture release followed by a commit touching only `.claude/backlog/`"; when "`tools/release verify` runs"; then "it passes"; red-making input "today's HEAD comparison". AC7 — Given "a fixture release followed by a commit changing `skills/`, not released"; when "`verify` runs against an install of the released commit"; then "it passes"; and Given "the install altered", then "it fails"; red-making change "excluding everything". Reused from develop's build notes, checked against the AC text: no omission.

| AC | How checked | Evidence paths | Result |
|---|---|---|---|
| AC1 | Loop over six files, first non-blank body line equals `# /ai-building-tools:<name>`: 6× `ok`. Mutation evidence from the S1 rounds; no S1 file changed since `11fd156e` (`git diff --stat 11fd156e..HEAD` over skills, README, CLAUDE.md, references, templates: empty) | `skills/{queue,design,prototype,develop,verify,retro}/SKILL.md` | PASS |
| AC2 | Read `README.md` lines 7–10: "Invoke each skill by its plugin-qualified name … A bare name can resolve to a built-in skill or another plugin's skill of the same name, silently". Prose, unguarded by design | `README.md` | PASS (read; unguarded) |
| AC3 | `CLAUDE.md:34`: "Nor does the skill's name prove *which* skill answered". Prose, unguarded | `CLAUDE.md` | PASS (read; unguarded) |
| AC4 | The S1 grep re-run; every match is a table name, a description, a `description:` trigger quoting the user, a "Do not invoke" line, a `templates/next` comment, `MEASUREMENT.md:674`, or the CLAUDE.md warning — same classification as the S1 PASS round | `README.md`, `CLAUDE.md`, `MEASUREMENT.md`, `skills/**/SKILL.md`, `skills/queue/templates/next` | PASS |
| AC5 | Whole suite green (above); skill-size 45/0; no file over its goal, no justification owed | `tests/*.test.sh` | PASS |
| AC6 | `tests/release.test.sh` case "verify passes after a backlog-only commit" plus "names the compared commit" / "says why". **M1** (red-making input: `COMMIT` defaulted to `rev-parse HEAD` before `cmd_verify`) → "80 passed, 7 failed", including `FAIL AC6 — verify red over a correct install after a backlog commit` and both AC6 report cases. **Literal Given:** fixture commit cut to `.claude/backlog/` paths only (commit stat: `.claude/backlog/QUEUE.md`, `.claude/backlog/items/0001-x.md`) → 87/0. Both restored by path; control 87/0 | `tools/release`, `tests/release.test.sh` | PASS |
| AC7 | Cases "verify passes over an unreleased skills/ commit" and "verify fails once the install is altered" (names `skills/demo/SKILL.md`). M1 reddens the pass case (`FAIL AC7 — verify compared against HEAD`). **M2** (red-making change: `not_backlog` emits nothing) → "80 passed, 7 failed", including `FAIL AC7 — an altered install verified clean`. Restored by path; control 87/0 | `tools/release`, `tests/release.test.sh` | PASS |
| FR6 exclusion | **M3** (`not_backlog` passes everything) → "86 passed, 1 failed": `FAIL FR6 — backlog paths failed verify`. Restored; control 87/0 | `tools/release`, `tests/release.test.sh` | guarded |
| Real install | `tools/release verify` against 0.9.51: "verified", `compared 4a989e49…` "(the gitCommitSha recorded for this install, the commit it was released at; not HEAD)", `excluded .claude/backlog/ .backlog/ .tickets/`, "104 tracked paths identical", record ok; exit 0, with backlog and S2 commits on top of the release | `tools/release` | PASS |
| NFR Documentation | README and CLAUDE.md carry the form (AC2, AC3) | `README.md`, `CLAUDE.md` | holds; unguarded (prose) |
| NFR Progressive delivery | Heading and qualified form need no knowledge of what else is installed | `skills/*/SKILL.md` | holds; unguarded (prose) |
| NFR Observability (0157) | Every report prints `compared <sha>` and why; M1 reddens "the report names the commit it compared against" and "says why that commit" | `tools/release`, `tests/release.test.sh` | holds; guarded |
| Always-on (`CONVENTIONS_CORE.md`) | Enforced in a script with behaviour tests, not prose; fixture identity `fixture@example.invalid`; no egress, logging or auth change | `tools/release`, `tests/release.test.sh` | holds |

Dirty set at Step 2: empty. Dirty set after the last evidence command: empty. Intersection: empty — not advisory.
