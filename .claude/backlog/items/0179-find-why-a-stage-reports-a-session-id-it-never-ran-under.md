---
id: "0179"
title: Find why a stage reports a session id it never ran under, and stop anything trusting one
type: bug
next: design
status: in-progress
qa_level: unit
close_by: verify
size: l
created: 2026-09-23
source: retro
parent:
blocked_by: []
relates: ["0160", "0161", "0173"]
expects:
  - skills/sprint/SKILL.md
  - skills/sprint/outcome.schema.json
  - tools/sprint-ledger.sh
  - .claude/backlog/close
  - skills/queue/templates/close
claimed_by: "b6b5"
claimed_at: 2026-09-24T13:04:51Z
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

**The existing rows cover three different halves and leave the middle empty.** `0160` (done)
*detects* it at `sprint` Step 4, and its own Problem concedes *"Detection comes after the damage"*.
`0161` (ready) *recovers*: a scripted path from closed back to verify. `0173` (done) immunises
*one consumer*, the ledger. **Nobody owns root cause or prevention.** The author asked on
2026-09-22 for this to be worked in the next sprint.

**The damage window is structural.** The stage commits, releases its claim and closes before the
supervisor reads the envelope, so prevention cannot live in Step 4 — it lives in the stage or in
`close`.

**The hard case is the 2026-09-22 verify gate.** Every independent signal says that work was sound:
suite green under `commands.unit`, all six items carry the `Conventions:` line `close` demands, QA
evidence per-AC and specific about which mutation reddened what, `conventions_resolved` non-null. The
id was the **only** bad field. A rule that treats a bad id as proof the pass was worthless reopens six
correctly-verified tickets.

## Requirements for design to carry through

- **FR1 — Root cause.** Establish why a stage emits an id it did not run under. Candidates to
  test, not assume: the stage cannot read its own id (is `CLAUDE_CODE_SESSION_ID` set in a
  `claude -p --session-id` child, and does the stage prompt tell it to read it?), or the schema's
  description invites it to compose one. The answer decides whether FR3 is needed at all.
- **FR2 — Audit, not another point fix.** Enumerate every consumer of the self-reported
  `session_id` (ledger — fixed by `0173`; `sprint` Step 4's trust check; run log; anything else) and
  adopt one rule: **nothing reads the id a stage reports when the dispatcher already knows it.**
- **FR3 — Prevention at the write that does the damage.** Decide whether `close` should refuse
  unless the QA evidence carries the dispatcher's `CLAUDE_CODE_SESSION_ID` — a value the harness
  sets, not the stage's self-report.
- **FR4 — What a supervisor may conclude.** When the id is the only unreliable field in an
  otherwise well-evidenced envelope, say what the supervisor does: accept with a flag, re-verify a
  sample, or reopen via `0161`. Written so it does not reopen sound work by reflex.

## Notes & decisions

- 2026-09-23 — filed by retro (session edf44941-de11-48ca-92b8-093a50099f9b) from two FINDINGS
  entries, both parked by the sprint supervisor for run-20260922T031109Z. Ranked first on the
  author's request.
