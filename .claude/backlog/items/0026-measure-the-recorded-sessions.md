---
id: "0026"
title: Measure the isolated workflow from the recorded sessions and record the verdict
type: chore
next: develop
status: ready
qa_level: verify
size: m
created: 2026-08-23
source: agent
parent: "0009"
blocked_by: []
relates: ["0025", "0036", "0037"]
expects:
  - .claude/backlog/items/0009-one-skill-per-session.md
  - README.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - tests/measurement.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Effort 0009 opened with a measurement and committed to closing with one: *"re-run the same end-to-end
exercise against a fresh project and compare cost per turn and context per turn, not just the total."*
Eleven of its twelve tasks closed on 2026-08-23. **The comparison has not been made.**

So the number the whole effort was justified by — **~$5.09 against $15.11** — is still modelled, not
observed. Every ticket in the effort cited it. Three places now carry a placeholder pointing at this
ticket for the observed figure: `README.md`, `skills/develop/SKILL.md` and `skills/verify/SKILL.md`.
Until it lands, the honest status of the effort is "the workflow changed as designed" and not "the
workflow is cheaper", and those are different claims.

**Both sides of the comparison are already on disk**, which is what this ticket was re-specified
around on 2026-08-24 (see *Notes & decisions*). `~/.claude/projects/<slug>/*.jsonl` carry, per
assistant turn, a `usage` object with `cache_read_input_tokens`, `cache_creation_input_tokens`,
`output_tokens` and `output_tokens_details.thinking_tokens`, plus the `model` for that turn — and a
`<command-name>` marker naming the skill that opened the session. Verified 2026-08-24:

- **The isolated side.** `-Users-aaronferguson-Documents-AI-ai-building-tools` holds **30 skill
  sessions** dated 2026-08-23 and 2026-08-24: `develop` 12, `verify` 9, `queue` 4, `retro` 2, plus
  three unmarked. This is the run that closed eleven of 0009's tasks.
- **The baseline side.** Five sessions touching **2026-08-22** live in
  `-Users-aaronferguson-Documents-AI`; the 328-turn one is the candidate for the $15.11 run, which
  `README.md` records as 95 turns at an average 191,752 tokens per turn.

That makes this an **observed-against-observed** comparison rather than observed-against-modelled,
which is strictly better than what 0009 committed to. It is a reporting and analysis job: no session
has to be sat, which is why the `## Waiting on` section is gone.

There is still a reason it should not drift: the baseline is a specific run on a specific day, and
`0028` and `0035` will both change how much context a session loads. Measuring the sessions that
**already ran** is not exposed to that — they are fixed history — but the longer the gap, the less
the comparison says about the suite as it then stands. `0037` carries the forward-looking run.

## Functional requirements

- FR1 — Compute, from the recorded transcripts, **cost per turn and context tokens per turn, per
  skill**, for the isolated multi-session run of 2026-08-23/24. The baseline's finding was a *shape* —
  the price of a turn doubled across the run while the work stayed the same kind — and a total cannot
  show that.
- FR2 — Compute the same two figures for the **2026-08-22 baseline session** from its own transcript,
  and state how the identified session was matched to the published $15.11 / 95 turns / 191,752
  tokens-per-turn figures. If it cannot be matched, say so and fall back to the published numbers as
  the baseline, labelled as published rather than recomputed.
- FR3 — State the **cost model** used to turn tokens into dollars: the per-model input, output,
  cache-read and cache-write rates, and their source. Both sides use the same model, or the
  difference is named. A dollar figure whose arithmetic cannot be re-run is not a measurement.
- FR4 — Record it **where each claim is made**, replacing "modelled" with what was observed:
  `0009`'s *Why this exists* and *Outcome* sections, the *One skill per session* section of
  `README.md`, and the two placeholder sentences that name this ticket —
  `skills/develop/SKILL.md` and `skills/verify/SKILL.md`.
- FR5 — **Record the verdict even when it is "it didn't work."** State plainly whether the saving
  materialised, partly materialised, or did not, and by how much against the modelled ~$5.09.
- FR6 — Report **effectiveness alongside cost**, because 0009's own commitment was that effectiveness
  must not be traded for it. Read it from the record the run left rather than from memory: `DONE.md`,
  the closed items' verify verdicts, and `FINDINGS.md`. Note what the isolated run caught, and what it
  missed that the baseline caught — the baseline found a zip-bomb vulnerability every acceptance
  criterion passed over, and a test left green with the guard it existed for deleted.
- FR7 — Report **cost per closed ticket** for the isolated run, which is the measure `0036`'s
  Performance NFR is written against, and is not derivable from cost per turn alone.
- FR8 — Produce the **per-gate batching figure** `0025`'s FR4 named this ticket as the source of: the
  cost of a session taking several related tickets against one taking them one per session. If the
  recorded sessions contain no batched `develop` or `verify` session to measure, **say so explicitly
  and name what run would produce it** rather than leaving the placeholder pointing at a figure this
  ticket did not deliver.
- FR9 — Note what the two runs did **not** hold constant — skill versions, conventions, model, project
  domain, and that one side is a greenfield project and the other this repo — so a later reader can
  weigh the comparison rather than trusting it.
- FR10 — Leave the analysis **re-runnable**: the harvest is a committed script in the repo, not a
  one-off computation in a transcript, so `0037` and `0036` can re-run it against later sessions
  instead of re-deriving the method.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The transcripts are full conversation history for this machine, and the figures land in a **public** repo. Only aggregate usage numbers and skill names are published — no message content, no file contents, no paths outside this repo, and no other project's name. The harvest script reads `usage` and the `<command-name>` marker and must not emit transcript text. | `data-privacy-conventions.md` |
| Documentation | The verdict is recorded whether or not it is the hoped-for one, and every figure carries its date and what was not held constant. | `documentation-conventions.md` |
| Dependencies | The harvest runs on what the repo already has — POSIX `sh` plus the `python3` already on the machine. It adds no package for a one-directory JSON read. | `dependency-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the recorded result, when read, then it reports cost per turn and context tokens per
      turn broken down by skill, for the isolated multi-session run.
- [ ] AC2 — Given the recorded result, when read, then it reports the same two figures for the
      2026-08-22 baseline and states how that session was matched to the published figures, or that it
      could not be.
- [ ] AC3 — Given the recorded result, when read, then it states the per-model rates used and their
      source, such that the dollar figures can be recomputed from the token counts.
- [ ] AC4 — Given `0009`, `README.md`, `skills/develop/SKILL.md` and `skills/verify/SKILL.md`, when
      read, then each carries the observed figure and none of them still describes it as modelled or
      still points at this ticket as pending.
- [ ] AC5 — Given the recorded result, when read, then it states the verdict explicitly —
      materialised, partly, or not — against ~$5.09, and says what the run caught and what it missed.
- [ ] AC6 — Given the recorded result, when read, then it carries cost per closed ticket for the
      isolated run.
- [ ] AC7 — Given the recorded result, when read, then it either carries the per-gate batching figure
      or states that the recorded sessions contain no batched session and names the run that would
      produce it.
- [ ] AC8 — Given the recorded result, when read, then it names at least two things the two runs did
      not hold constant.
- [ ] AC9 — Given the harvest script, when run against the transcript directory, then it reproduces
      the reported per-skill figures, and its output contains no transcript message content.

## QA plan

- **Level:** verify — a measurement and a written record; no runner applies.
- **Why this level:** the deliverable is figures and prose in four files plus one script. `unit` would
  test the script's arithmetic, which is worth doing inside it, but the ticket is met or missed on what
  is written down.
- **Specific checks:** `tests/measurement.test.sh` asserts, each on its own line so a reflow cannot
  red it:
  - the recorded result contains a per-skill breakdown naming `queue`, `develop` and `verify`
  - it contains a `20[0-9][0-9]-` date
  - it contains the string `5.09` and one of `materialised`, `partly` or `did not`
  - `grep -c modelled README.md` is lower than the pre-change count, so a stale claim left in place
    fails rather than passing quietly
  - `grep -c 0026 skills/develop/SKILL.md skills/verify/SKILL.md README.md` is zero for the
    pending-placeholder sentences
  - the harvest script's output matches `^[A-Za-z0-9 .,$%|:/-]*$` per line, so emitted transcript
    prose fails the run
  - AC5 and AC8 are asserted separately from AC1 because a run that produces figures and no verdict is
    the likely failure, and it is the one this ticket exists to prevent.

## Out of scope

- **The fresh-project end-to-end run. That is `0037`**, which is where the original FR1 went, and it is
  deliberately sequenced behind `0028` and `0035`.
- Changing anything in response to the result. If the saving did not materialise, that is a finding and
  a new ticket. Filling in the three placeholders that already name this ticket is FR4, not a change in
  response to the result — the sentences were written to be completed.
- Re-measuring the pre-isolation baseline by running it again. The 2026-08-22 transcript is the
  control, with FR9 recording its limits.

## Notes & decisions

- **Amended 2026-08-24, by Aaron, and this is the substantive change to the ticket.** The old FR1
  required a fresh project taken through `queue → develop → verify` with each skill in its own session.
  That made the ticket unexecutable by any stage — a session cannot create sessions — so it sat
  `waiting` at row 1. Two arguments settled it. First, the sessions needed to answer the question
  **already ran**, and both sides of the comparison are on disk. Second, `0028` and `0035` are both
  still open and both change how much context a session loads, so a fresh run measured today would
  measure a configuration this repo is part-way through replacing. Relaxing FR1 to *an observed
  multi-session run* clears the `waiting` state, lands the observed figure now, and gives `0036`
  the baseline its Performance NFR needs. `0037` carries the fresh-project run, after the context-size
  regime settles.
- **Blocker 0022 cleared.** It was the sole entry in `blocked_by` and is `done`; the row read `blocked`
  stale for a session, which `RANKING.md` records as an argument for 0027. `blocked_by` is now empty.
- **What the transcripts carry, verified 2026-08-24**, so the next reader does not re-derive it: per
  assistant turn, `message.usage` with `cache_read_input_tokens`, `cache_creation_input_tokens`,
  `output_tokens` and `output_tokens_details.thinking_tokens`, and `message.model`. Session-level, a
  `<command-name>` marker naming the skill. Context per turn is cache-read plus cache-creation plus
  input; it is not a field of its own.
- **FR3 exists because the modelled ~$5.09 has no arithmetic attached in either place it appears.**
  Reproducing an observed figure without stating the rates would repeat that.
- **The kill criterion this ticket also settles.** 0016's FR5 carried one — drop the approval-gate
  reorder if an isolated batch retro measures under $1.50 — deferred because no isolated retro had
  been run. Two `retro` sessions are in the recorded set. Settle it here rather than deferring twice.
- **FR8 is written to be satisfiable either way on purpose.** An AC that requires a figure the recorded
  history may not contain cannot be met inside this ticket's scope, and `verify` would be right to fail
  it — so the requirement is the figure *or* the stated absence and the named follow-up.
- FR5 exists because a measurement whose verdict is only recorded when favourable is not a measurement.
  `measurement-conventions.md` already requires the verdict be recorded even when it is "it didn't
  work"; this FR is the citation, not a new rule.

### Built 2026-08-24 — what the measurement turned on

- **A turn is a distinct `message.id`, not a transcript line, and this is the whole ballgame.** One
  API response is written as several lines — one per content block — and **every line repeats the
  same complete `usage` object**. Summing lines overcounts by about 2.2x on a real session, and it
  fails silently: the shape of the answer stays plausible. `tests/measurement.test.sh` feeds the
  script a three-line response and asserts the deduplicated total, because nothing else catches it.
- **This is also what matched the baseline.** Session `2ce6bc83` was described in this ticket as
  "the 328-turn one". 328 is its **line** count; deduplicated it is 158 turns, and its 2026-08-22
  portion is **98** — against the published 95. The published figure was reachable only after the
  dedup rule was found.
- **The published $15.11 and 191,752 are not reproducible from that transcript.** Recomputed they
  are $11.79 and 151,669, both about 78% of published, and no variant tried closed the gap:
  per-line summation, pricing every cache write at the 1-hour rate, or folding in the other Opus
  session of that day. So the verdict compares recomputed against recomputed, which is like for
  like, and keeps the published pair labelled as published. FR2 explicitly allows this.
- **The command marker is not where prose suggests.** It arrives as `<command-message>` *then*
  `<command-name>` for a plugin skill and the reverse for a built-in, and a session opens `/clear`
  on its own message first. Anchoring on `<command-name>` at position 0 attributed **all 30
  sessions to `unmarked`** — a complete harvest, no per-skill figures, and nothing failing. The
  guard now carries both orderings and a marker quoted inside prose that must *not* count.
- **The transcript store is live, and a harvest taken from inside it is not stable.** Mid-session
  the session count moved 30 -> 31 because another window started a `design` session. Figures are
  pinned by excluding the in-flight sessions and recording which — `--exclude` exists for that.
- **`tests/batching.test.sh` asserts `0026` is named in develop's batching paragraph.** The
  placeholder was therefore rewritten to name this ticket as the source of the *answer* — that no
  batched session exists to measure — rather than deleted. The QA plan's "grep -c 0026 is zero" is
  qualified as *for the pending-placeholder sentences*, and that is how it was read: the deferral
  phrasing is gone from both skills, the provenance is not.
- **The result is unwelcome and is recorded as it came out.** Cost per turn fell 14.5%, not the
  ~66% the effort was justified by, and the modelled ~$5.09 assumed a 60k average context against
  an observed 106,139. The mechanism is in `MEASUREMENT.md`: isolation swaps cache reads at 0.1x
  input for cache writes at 1.25x-2x, so writes per turn *rose* 22.8% while context per turn fell 30%.
- **0016's deferred kill criterion is settled and did not fire.** No isolated retro came in under
  $1.50 — the cheapest retro-only session was $4.00 — so the approval-gate reorder stays.

### Verified 2026-08-24 — FAIL on the Privacy & data NFR; all nine ACs pass

- **The nine acceptance criteria pass and every figure reproduces.** `tests/measurement.test.sh` is
  39/39. `tools/harvest-usage.sh` re-run against the live store, with the three sessions that
  postdate the record excluded (`1860b4f4`, `1a2da19b`, and the verifying session), reproduces
  `MEASUREMENT.md`'s isolated table row for row — 30 sessions, 1,112 turns, $114.27, $0.1028 per
  turn, 106,139 context tokens per turn, 22.5% output share — and the baseline session reproduces at
  98 turns, $11.79, $0.1203, 151,669, 19.0%. 328 transcript lines against 158 distinct `message.id`s
  confirms the 2.08x dedup mechanism independently. No claim token in the run's git history names
  two tickets, so FR8's stated absence is right. 19 closed rows, all `qa_level: verify`, confirm
  $6.01 and $4.45 per closed ticket.
- **What fails is the Privacy & data row, and it fails inside this file.** Lines 43 and 47 of
  *Problem* publish two literal transcript-store slugs — `-Users-aaronferguson-Documents-AI-ai-building-tools`
  and `-Users-aaronferguson-Documents-AI` — in a repo that same NFR row calls public. The row's own
  words are "no paths outside this repo, and no other project's name"; the second slug is both, and
  both encode the machine's home path. The **deliverables are clean**: `git grep` finds the string in
  no other tracked file, `MEASUREMENT.md` writes "the parent workspace's transcript store" and
  `~/.claude/projects/<slug>`, and the pre-amendment 0026 used `<slug>` as well. `106c282`, the
  amendment, introduced them.
- **The fix is a redaction, not a re-measurement.** Replace the two slugs with the wording
  `MEASUREMENT.md` already uses. Nothing is pushed yet, so this is the cheap moment — after a push it
  is a history rewrite. ACs 1-9 need no rework; re-ticking them is a re-read, not a re-run.
- **Two non-blocking corrections while the file is open.** (1) `MEASUREMENT.md`'s effectiveness
  section says "26 findings were parked ... 4 on 2026-08-23 and 22 on 2026-08-24" and then "grown to
  28 entries"; 28 is the true count and the gap is two entries formatted `- **2026-08-24 —` instead
  of `- 2026-08-24 — **`, which a date-anchored grep misses. (2) `expects:` omits `MEASUREMENT.md`
  and `tools/harvest-usage.sh`, the two central deliverables.
