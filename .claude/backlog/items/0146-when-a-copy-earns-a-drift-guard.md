---
id: "0146"
title: Decide when a required duplication earns a drift guard, and guard the copies that qualify
type: debt
next: develop
status: in-progress
qa_level: verify
size: m
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0106", "0027"]
expects:
  - tests/declared-copies.test.sh
  - tests/close.test.sh
  - skills/queue/templates
  - tests
  - CHANGELOG.md
ac_digest: AC1=5fbfaaac AC2=c1acc8f1 AC3=9050975f AC4=56e774ba AC5=8f2742d6 AC6=a6cbfedc AC7=727df98e AC8=b99456d7 AC9=c672124b
claimed_by: "e36d"
claimed_at: 2026-10-27T02:37:50Z
touches:
  - tests/declared-copies.test.sh
  - tests/close.test.sh
  - skills/queue/templates
  - tests
  - CHANGELOG.md
---

## Problem

**Four "change one, change all" duplications live in these scripts and exactly one of them has a drift
guard.** The install contract makes copying the only option — a backlog script sources nothing, so
shared code cannot be extracted — which means the question is not how to stop duplicating but **when a
copy earns a guard**, and that has been decided per ticket four times with three different answers:

| duplication | copies | guard |
|---|---|---|
| the `saw`/`saw_on_pass` helper | four test suites | none |
| the `DECOMMENT` awk block | three scripts | none |
| the `fm_value` reader | three scripts | none |
| the scope-comparison block (`0106`) | `close`, `handoff` | byte-for-byte comparison |

Each carries a comment saying to change them together, which is a rule with nothing enforcing it.
`0106` wrote a comparison for its own copy and the other three were left, so the repo's answer today is
"whichever ticket happened to think of it" — and a comment is exactly the artefact
`documentation-conventions.md` now warns ages without reddening.

## Requirements

- **FR1** — A required copy is **declared** by wrapping each copy in a marker pair on lines of their
  own: `# copy-begin: <name>` and `# copy-end: <name>`, `<name>` a kebab-case identifier shared by
  every copy. The marker replaces the "Change one, change N" comment; the begin line's neighbour
  comment names `tests/declared-copies.test.sh` as the guard, and carries no count of copies.
- **FR2** — A new suite `tests/declared-copies.test.sh` scans `skills/queue/templates/*` and
  `tests/*.test.sh` under a root it is given (default: the repo), groups marked blocks by name, and
  reds when: a begin has no matching end (or the reverse, or they nest); a name has fewer than two
  copies; any copy of a name is not byte-identical, between its markers, to the others. A red names
  the block, both files and the first differing line.
- **FR3** — The same suite reds when a shell function name is defined (`name() {` at line start) in
  two or more files under `skills/queue/templates/` outside a marked block — the detector for an
  undeclared copy, which is how `reopen` came to carry `DECOMMENT` and `fm_value` unannounced.
  Scoped to templates only: every test file defines `ok`, `bad` and `assert_*` by design.
- **FR4** — Every duplication this row enumerates is declared under FR1: `decomment` (the
  `DECOMMENT=` assignment in `next`, `close`, `handoff`, `reopen`), `fm-value` (`close`,
  `handoff`, `reopen`), `fm-list` where its copies are identical (a differing copy is reported in
  *Notes & decisions*, not normalised), `scope-block` (`close`, `handoff`), `saw-on-pass` (the
  `saw_on_pass` line in every test file carrying it) and `saw-prefix` (the one-line
  `saw: `-prefix `saw` in every test file carrying it). The `SAW_LINES` window `saw` variants are
  distinct helpers, not copies, and stay unmarked.
- **FR5** — `tests/close.test.sh`'s *0106 FR3* byte-comparison case is removed, its comment
  pointing at the new suite: one copy, one guard.
- **FR6** — The suite reads no path under `.claude/backlog/`. It compares blocks across *different
  files of the source tree*; `tests/backlog-scripts-installed.test.sh` compares a *whole template
  against its installed copy*. Neither subsumes the other.
- **FR7** — A `CHANGELOG.md` `## Unreleased` note: a session editing a marked block must edit
  every copy, and the suite says where they are.

## Acceptance criteria

- [ ] AC1 — Given an authored fixture tree with two files carrying `# copy-begin: x` blocks that
  differ in one character, when `tests/declared-copies.test.sh <fixture-root>` runs, then it exits
  non-zero and its output names `x`, both files and the differing line.
- [ ] AC2 — Given a fixture with a `# copy-begin: x` and no `# copy-end: x`, when the suite runs on
  it, then it exits non-zero naming the unclosed block and its file.
- [ ] AC3 — Given a fixture where name `x` is marked in exactly one file, when the suite runs on it,
  then it exits non-zero saying `x` has one copy.
- [ ] AC4 — Given a fixture whose `skills/queue/templates/` holds two files each defining
  `helper() {` outside any marked block, when the suite runs on it, then it exits non-zero naming
  `helper` and both files; and given the same two definitions inside identical marked blocks, it
  passes.
- [ ] AC5 — Given the repo tree, when the suite runs with no argument, then it exits 0 and reports
  the blocks `decomment`, `fm-value`, `scope-block`, `saw-on-pass` and `saw-prefix` each with at
  least two copies (`decomment` four, `scope-block` two).
- [ ] AC6 — Given the repo tree, when `grep -rn 'Change one, change' skills tests` runs, then it
  prints nothing.
- [ ] AC7 — Given a copy of the repo tree with one character changed inside the `scope-block` copy
  in `skills/queue/templates/handoff` only, when the suite runs on that copy, then it exits non-zero
  naming `scope-block` — the drift `close.test.sh`'s removed 0106 FR3 case used to catch.
- [ ] AC8 — Given the suite's source, when `grep -n '\.claude/backlog' tests/declared-copies.test.sh`
  runs, then no line reads from that path (a comment explaining FR6 is the only permitted match).
- [ ] AC9 — Given the full suite (`for t in tests/*.test.sh; do "$t" || exit 1; done`), when it
  runs after the change, then every file passes, `tests/abort-announce.test.sh` included for the new
  file.

## Out of scope

- Extracting shared code into a library. Forbidden by the install contract, named above.
- Reviewing whether the four duplications should exist.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a park that enumerated all four duplications and framed the
  question as when a copy earns a guard rather than how to avoid copying. Routed to `design` because
  every part of it is a trigger to be chosen, not a defect to be fixed.
- **2026-09-12 (retro pass 2026-09-12, absorbed from FINDINGS.md).** Evidence for this decision from four sessions: the suites copy `skills/queue/templates/<script>` into fixtures, so mutating `.claude/backlog/<script>` reddens nothing and reads as an unfalsifiable guard (verify 0146 next, develop 0133, verify 0144 close). A comment now sits at each `*_SRC=` line and `CLAUDE.md` scopes *installed copy is what runs* to skills; the equality guard between the copies is still this ticket's question (`backlog-scripts-installed` catches drift only once both are committed).
- **2026-09-21 (retro pass 2026-09-21, absorbed from FINDINGS.md).** A fifth required duplication,
  and the purest case of the "divergence would be silent" trigger the question above names:
  `gate_contiguous` in `skills/queue/templates/next` ends a gate at anything the rank walk would not
  step over, and `walk_steps_over` reproduces that walk's three `continue` arms — in-progress, an
  open blocker, held — by hand. A fourth arm added to the walk leaves the gate **silently stricter
  than the walk it is defined against**, and only the blocker arm has a fixture (`0158` AC3). It
  also constrains the *shape* half of the question: this copy is control flow rather than a block of
  text, so neither a byte-for-byte nor a normalised comparison can express it — a derivation, or a
  case per arm, is what it would take (develop `0158`, claim b040).
- **2026-10-25 (design, claim d2ae) — decided.** Re-verified at HEAD b37b350 before deciding.
  **Trigger: a copy earns a guard when it is declared — and it must be declared when its divergence
  would be silent**, i.e. both copies would still run and pass their own tests while answering
  differently. Every duplication this row names meets that (a `decomment` that drifts in one script
  makes two scripts disagree about one token, with no error). The silent/loud test decides
  *whether to declare*; the marker makes the rule mechanical once declared. Rejected: *every
  copy* (cannot be found mechanically — that is FR3's narrower detector); *more than N lines*
  (`saw_on_pass` is one line and its divergence silently disables `SHOW_MATCHED` in one suite);
  *crossing the template/installed boundary* (that boundary is already guarded whole-file by
  `backlog-scripts-installed`; none of these copies cross it).
  **Shape: byte-for-byte, between markers, in one shared suite.** Rejected: a normalised comparison
  — no current copy needs a local difference (all four text blocks hash identical today), so it is
  a second thing to keep correct bought for a hypothetical; a copy that needs a local difference is
  not a copy and should not be marked. Rejected: a per-ticket comparison like 0106's — that is how
  the repo reached one guard for four copies. Cost accepted: marker lines in ~16 files, and a
  legitimate local tweak must be un-marked rather than tolerated.
  **The comments are already wrong, which is the case for the decision:** `DECOMMENT` is in four
  templates (`next`, `close`, `handoff`, `reopen`) while `next` says "change both" and `close`/
  `handoff` "all three"; `reopen` carries it and `fm_value` with no comment at all. `saw_on_pass`
  is in 14 test files while the comments count three and four. The `saw` helper itself has two
  distinct shapes (a one-line `saw:` prefix, and a `SAW_LINES` window in which `close-by` and
  `cross-cutting-change` differ by one word) — distinct helpers sharing a name, not drift, so FR4
  marks only the prefix form.
  **The fifth duplication is gone:** `walk_steps_over`/`gate_contiguous` were removed by 0178
  (a560171) when gates moved to `gate_max_rows`, so the control-flow shape question it raised has
  no live case; if one recurs, a copy inside one file is not forced by the install contract and is
  extracted, not guarded.
  **Rule's home:** the trigger and marker are this repo's (the install contract forcing copies is
  local); the general rule — a declared copy needs a mechanical guard, because the comment
  declaring it ages without reddening — is parked to the conventions repo's `FINDINGS.md` rather
  than written there from here. **Scope:** all copies guarded under this row — the guard is one
  suite and the markers are comment lines, and splitting would ship a guard that covers some
  copies while the rest keep the old comment. `qa_level: verify` and no `close_by` re-read and kept:
  AC7 is a mutation check a verifying session should run itself.

