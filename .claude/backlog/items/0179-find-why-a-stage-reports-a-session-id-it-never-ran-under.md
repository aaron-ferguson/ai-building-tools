---
id: "0179"
title: Find why a stage reports a session id it never ran under, and stop anything trusting one
type: bug
next: verify
status: ready
qa_level: unit
close_by: verify
size: m
created: 2026-09-23
source: retro
parent:
blocked_by: []
relates: ["0160", "0161", "0173"]
expects:
  - skills/sprint/SKILL.md
  - skills/sprint/outcome.schema.json
  - tests/sprint.test.sh
  - tests/sprint-ledger.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**Stages return a session id that is not the one they were dispatched under, and the shape is
getting worse.** Three occurrences, all under `sprint`:

- **2026-09-13**, run-20260913T034946Z, verify gate: the placeholder
  `00000000-0000-4000-8000-000000000000`, with `conventions_resolved: null` and a substituted test
  command. `0160` was written against this one.
- **2026-09-22**, run-20260922T031109Z, develop gate 2: dispatched with
  `--session-id dda30e75-a894-4c1c-8f50-65952605cd42`, returned the well-formed
  `4f1d8a26-7c3b-4e59-9a10-2b6d5e83c714`. **No transcript exists for the returned id**; the
  dispatched one's does. The id was invented, and every other field was well-formed.
- **2026-09-22**, same run, verify gate: dispatched with
  `--session-id e0cf784f-539e-4df2-8dbd-51858fff2e29` (transcript exists, 1.4 MB), returned the
  placeholder again — and **closed six tickets** (0176/0165/0163/0162/0166/0173) before the
  supervisor saw the envelope: `6f6a2bc` and 14 more commits. Its escalation text asserted *"No
  session id was pre-assigned at dispatch"*, which was false, so **a stage's own account of its id
  cannot be used to triage the problem either.**

A placeholder announces itself; a plausible fabrication does not, so **eyeballing an envelope is no
longer a control** — only comparison with the dispatched value distinguishes them.

**The damage window is structural.** The stage commits, releases its claim and closes before the
supervisor reads the envelope, so prevention cannot live in Step 4.

**The hard case is the 2026-09-22 verify gate.** Every independent signal says that work was sound:
suite green under `commands.unit`, all six items carry the `Conventions:` line `close` demands, QA
evidence per-AC, `conventions_resolved` non-null. The id was the **only** bad field.

## Outcome

The stage outcome no longer asks a stage for a value it was never given. The supervisor takes each
stage's session id from its own `dispatch` event, so a fabricated or placeholder id cannot occur in
a new run, and nothing — Step 4, the run log, the ledger — reads one.

## Non-goals

- A `close` refusal keyed on `CLAUDE_CODE_SESSION_ID` (FR3 — rejected, see Notes & decisions).
- Reopening the six tickets the 2026-09-22 verify gate closed. They stand.
- Changing `tools/sprint-ledger.sh`. `sessions_of` already takes its sessions from dispatch events
  (`0173`), and `session_mismatches` stays to report the historical logs that do carry a bad id.
- The recovery path from closed back to verify — that is `0161`.

## Requirements

- **FR1 — The root cause, as found (2026-09-24).** The stage is never told its id. The dispatch
  prompt (`skills/sprint/SKILL.md` Step 3) carries the skill and its arguments only, while
  `outcome.schema.json` makes `session_id` required, pattern-constrained, and describes it as *"the
  UUID the supervisor pre-assigned at dispatch, echoed back"* — a value the stage has nothing to
  echo. A model forced to fill a required UUID field it has no source for composes one: a
  placeholder, or a plausible fabrication. The harness *does* set `CLAUDE_CODE_SESSION_ID` in the
  stage's shell (observed in this design session: set, and equal to the `--session-id` in the
  `.out` filename and the transcript name), but no instruction tells the stage to read it, and
  neither bad transcript ever ran it: in `e0cf784f…`'s message bodies the dispatched id appears
  exactly once, as a filename in an `ls` of `runs/`, and in `dda30e75…`'s not at all.
- **FR2 — One rule: nothing reads the id a stage reports, because the stage reports none.** Remove
  `session_id` from `skills/sprint/outcome.schema.json` (`required` and `properties`). Every place
  the supervisor needs a session id takes it from the dispatch it made itself.
  Audit of consumers (2026-09-24), each with its disposition:
  - `skills/sprint/SKILL.md` Step 1 probe prompt (the `aaaaaaaa-…` literal) — drop the
    `session_id` clause, or the probe asks for a property the schema now forbids.
  - Step 4's comparison paragraph (*"An outcome whose `session_id` is not the dispatched one…"*)
    — delete it; there is nothing to compare. The following paragraph's *"either of those two
    checks"* becomes the malformed-outcome and `conventions_resolved: null` checks, named.
  - Step 5's `outcome` event — its `session_id` is **written by the supervisor from the dispatch**
    it is answering, never copied out of stdout. `tools/sprint-ledger.sh` `outcomes_of` filters on
    that field being a string, so an outcome event without it drops out of the ledger.
  - `tools/sprint-ledger.sh` `sessions_of` / `session_mismatches` — unchanged (see Non-goals).
  - `tools/floor-probe.sh:178` reads `session_id` from CLI transcript JSON, not from an outcome —
    not a consumer, unchanged.
  - Tests: `tests/sprint.test.sh` fixtures (lines ~195, ~232), the probe assertion (~908) and the
    `0160 AC1` guard (~2382); `tests/sprint-ledger.test.sh`'s `0173 Documentation NFR` guard
    (~1251). Each asserts the field exists or is compared, and is replaced, not deleted silently.
- **FR3 — No `close` refusal.** Decided against; reasons in Notes & decisions.
- **FR4 — What a supervisor concludes from an id alone.** Nothing that moves a ticket. In a new run
  the case is unreachable. In an old run log, a mismatched id beside a schema-valid envelope with
  `conventions_resolved` non-null is a flag the ledger reports (`session_mismatches`) and the
  closes stand; the triggers for naming tickets as closed on an untrusted pass are the malformed
  envelope and `conventions_resolved: null`, and `0161` is the path back for those.

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/outcome.schema.json`, when its `required` array and `properties`
  keys are read, then neither contains `session_id`, and `additionalProperties` is still `false`.
- [ ] AC2 — Given the Step 1 probe command in `skills/sprint/SKILL.md`, when its prompt text is
  read, then it names no `session_id`, and a test asserts that (red on today's file).
- [ ] AC3 — Given `skills/sprint/SKILL.md` Step 4, when it is grepped, then no sentence tells the
  supervisor to compare an outcome's `session_id` with the dispatched one, and the untrusted-pass
  paragraph names its two triggers as the malformed outcome and `conventions_resolved: null`.
- [ ] AC4 — Given Step 5 of `skills/sprint/SKILL.md`, when the `outcome` event is described, then
  it says the event's `session_id` is the dispatched UUID written by the supervisor, not read from
  the stage's stdout, and a test guards that phrase on one line.
- [ ] AC5 — Given `tests/sprint.test.sh`'s `0160 AC1` guard and `tests/sprint-ledger.test.sh`'s
  `0173 Documentation NFR` guard, when this change lands, then each is replaced by a guard for the
  new rule (AC1/AC3), with a comment naming 0179 as what superseded it, and each new guard is shown
  red against the pre-change file before it goes green.
- [ ] AC6 — Given `tests/sprint-ledger.test.sh`'s existing `0173` cases for a phantom id and for
  `session_mismatches`, when this change lands, then they pass with their fixtures unchanged — a
  historical log carrying a bad id is still reported and still books no phantom session.
- [ ] AC7 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs,
  then it is green, including `tests/item-ac-form.test.sh`.

## QA plan

Unit. AC1–AC5 by the guards themselves, each shown red on the pre-change file (per
`testing-conventions.md`, a guard that cannot fail is not a guard). AC6 by the `0173` ledger cases,
which use fixtures rather than `runs/` (untracked, so not every checkout has the real log). The change reaches real dispatches only after a
release (`tools/release`), because the supervisor `cat`s the installed schema — say so in the
handoff rather than treating the checkout as proof.

## Notes & decisions

- 2026-09-23 — filed by retro (session edf44941-de11-48ca-92b8-093a50099f9b) from two FINDINGS
  entries, both parked by the sprint supervisor for run-20260922T031109Z. Ranked first on the
  author's request.
- 2026-09-24 — **design: remove `session_id` from the outcome schema; the supervisor already has
  it.** Root cause per FR1: the schema demands a value the dispatch never supplies. This settles
  FR1 and makes FR3 unnecessary, as the ticket anticipated.
  - **Rejected — tell the stage to read `CLAUDE_CODE_SESSION_ID` and echo it.** It would make the
    field correct, but its only content would be a copy of what the dispatcher wrote in its own run
    log, and a stage that skips the Bash call still fabricates. What echoing proves — that the
    envelope came from the dispatched process — is already proven by capturing that process's
    stdout into `runs/<run-id>.<session-id>.out`.
  - **Rejected — put the id in the dispatch prompt.** Same objection: the value is known to the one
    party that needs it; routing it through a model is where it got corrupted.
  - **Rejected — FR3, `close` refuses unless QA evidence carries `CLAUDE_CODE_SESSION_ID`.** `close`
    runs in the stage's own shell, where the harness always sets that variable (observed), so the
    refusal could never fire: a guard that cannot fail. The failure that did real damage on
    2026-09-13 was `conventions_resolved: null` with a substituted test command, and `close`'s
    `Conventions:` requirement already covers that.
  - **Trade-off accepted:** the mismatch check is gone as a canary. It had no unique catch: of three
    occurrences, one coincided with `conventions_resolved: null` (caught independently), and two
    accompanied work every other signal says was sound.
  - **Existing requirements, accounted:** FR1 answered; FR2 confirmed and made concrete as an audit
    with dispositions; FR3 replaced by a recorded rejection; FR4 changed from "accept, sample or
    reopen" to "no ticket moves on an id alone". AC1–AC7 are new — the ticket arrived with none.
  - **Superseded guards:** this intentionally retires `0160` AC1's Step 4 comparison and `0173`'s
    schema-description Documentation NFR. `0173`'s ledger behaviour stays.
  - `size` lowered from `l` to `m`: no script changes, one schema field, prose and test edits.
- 2026-09-24 — **develop (token fb1a), `11c503c`.** Built as designed; no FR stale (`grep -rn 0179`
  found nothing but this ticket's own lifecycle commits).
  - Schema: `session_id` gone from `required` and `properties`; `additionalProperties: false` kept,
    so an envelope that still sends one is **refused** — a new case asserts that with the fabricated
    id from run-20260922T031109Z.
  - SKILL.md: probe prompt drops the clause (AC2); Step 4's comparison paragraph deleted and the
    untrusted-pass paragraph now opens *"A malformed outcome, or one returning
    `conventions_resolved: null`"* (AC3); Step 5 carries the AC4 sentence on one line, deliberately
    over-width so the line-based guard can match it; Step 3's `--session-id` bullet says why the
    schema asks for no id.
  - Tests: `0160 AC1` → `0179 AC3` (and AC2/AC4 guards beside it) in `tests/sprint.test.sh`;
    `0173 Documentation NFR` → `0179 AC1` in `tests/sprint-ledger.test.sh`, each with a comment naming
    0179. The two fixtures and both missing-field loops dropped `session_id`, and the AC22 probe
    test's own prompt was changed to match the skill's.
  - **Red-before-green, run:** all new guards were red on the pre-change files (9 fails in
    `sprint.test.sh`, 1 in `sprint-ledger.test.sh`). **Mutation, run:** `additionalProperties: true`
    on the committed schema reds all three AC1 guards; restored by `git checkout`.
  - AC6 **run**: the `0173` phantom-id and `session_mismatches` cases pass with fixtures unchanged
    (129/0). AC7 **run**: whole suite green; the AC22 live probe executed (0 skipped) and returned a
    schema-valid outcome against the *new* schema.
  - **Not yet live:** a dispatch `cat`s the installed schema, so real runs still require the field
    until `tools/release`. This very session was dispatched under 0.9.32's schema and still had to
    report a `session_id` (it read `CLAUDE_CODE_SESSION_ID` to do so).
