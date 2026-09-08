---
id: "0114"
title: Let an agent-run retro complete its release chain instead of stopping half-released
type: bug
next: design
status: ready
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
---

## Problem

**`retro` Step 5 instructs every session to run a chain that an agent session structurally cannot
finish, and the stop lands after six of its eight steps have already acted.**

Step 5: *"A skill edit has a release chain — run `tools/release` from the repo root."* Step 7 of
that chain confirms the push interactively (`tools/release:279-297`):

```
elif [ -r /dev/tty ]; then
  printf '  push %s commit(s) to %s? ...' ...
else
  die "no tty to confirm the push on; re-run with --yes if you mean to release" 3
```

An agent's shell has no controlling terminal — macOS answers `/dev/tty: Device not configured` — so
`[ -r /dev/tty ]` is false and the script dies with exit 3.

**The script's behaviour is correct and its usage line already documents `--yes`
(`tools/release:23`, `:340`). The instruction is what is wrong.** By the time the chain reaches step
7 the version bump is committed and the suite has run — the die message says so itself: *"the bump
is committed locally and nothing was released."* So **every agent-run retro that edits a skill ends
in a half-released state**: bumped, committed, unpushed, uninstalled. Step 5 says this fires on most
retros, which makes it a standing condition rather than an edge case, and it reads to the user like
a failure rather than a missing flag.

**It compounds with 0075.** 0075 FR3 has the next version derived from *the remote's* current
version, precisely to stop the collision that happens when local and remote disagree. A committed
bump that never reached the remote is exactly that disagreement — produced, now, by the tool's own
stop path. The two tickets are pulling on the same rope from opposite ends.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — An agent-run retro reaching Step 5 either completes the chain or stops **before** the chain
  acts. It must not stop between the bump and the push, which is the only state that needs a human
  to reason about recovery.
- FR2 — Wherever the approval lands, `git-conventions.md`'s requirement that a release-triggering
  push is confirmed **specifically** is satisfied, and the change names where that confirmation is
  now evidenced. The chain's own prompt is where that rule is currently held, so removing it without
  naming a replacement drops a convention rather than relocating it.
- FR3 — The half-released state is recoverable by whoever finds it: the change says what a session
  does when it meets a committed bump that was never pushed. There are already such commits.
- FR4 — The code is named, not only the prose. `tools/release`'s step 7 and `tests/release.test.sh`
  are the artefacts; the change states whether each is touched, so the outcome cannot be prose
  describing one protocol while the script runs another.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Git | A push from this repo is a release — other machines install from the branch. Whatever lands keeps the confirmation specific and per-push; `--yes` passed by default with no user act would remove it, not relocate it. | `git-conventions.md` |
| Progressive delivery | The version bump is how an edit reaches installed copies. A change to when the bump is committed relative to the push changes what a half-failed release leaves behind, so it is stated rather than discovered. | `progressive-delivery-conventions.md` |
| Documentation | The instruction and the script's usage line must agree after this. They disagree today only because one omits a flag the other documents. | `documentation-conventions.md` |

## Open design question

- **Question:** Where does the release approval live — does `retro` Step 5 invoke the chain with
  `--yes` for a non-interactive session, or does the chain's own `/dev/tty` prompt go and the
  approval move to the point where the user actually grants it, before the chain is invoked at all?
- **Why it blocks specification:** the two answers write different acceptance criteria against
  different artefacts. **`--yes` in Step 5** is one sentence, leaves `tools/release` and
  `tests/release.test.sh` untouched, and keeps the confirmation where `git-conventions.md` can see
  it only if the session asked the user first — which nothing then requires. **Moving the approval**
  changes the script's step 7 and `tests/release.test.sh`'s cases, and needs the confirm-a-release
  rule evidenced somewhere new. Until it is settled there is no AC that can name `tools/release`'s
  behaviour at all.
- **The 2026-09-07 pass leans to the second and did not decide it:** that session asked the user for
  push approval through the harness *before* invoking the chain, which is the right order and left
  the chain's own prompt redundant. One observation is not a decision.
- **Settle it with:** `/design` — the inputs are `retro` Step 5, `tools/release:279-297` and its
  usage line, `git-conventions.md`'s push rule, and `tests/release.test.sh`. Nothing needs to be
  seen.

## Acceptance criteria

Cannot be written until the design question is settled. These hold regardless:

- [ ] AC1 — Given a retro session with no controlling terminal, when Step 5's chain runs, then
  either the push happened or the chain committed nothing. **Red: the behaviour as it stands today**
  — bump committed, exit 3, nothing pushed. This criterion is unsatisfiable by the current tree,
  which is the point of writing it this way.
- [ ] AC2 — Given a repository whose HEAD carries a committed version bump that was never pushed,
  when a session reads the step that owns recovery, then it is told what to do. Red when that
  sentence is deleted.
- [ ] AC3 — Given the landed change, when read against `git-conventions.md`'s push rule, then it
  names where the release approval is evidenced. Red when the naming is removed — a change that
  merely adds `--yes` and says nothing satisfies AC1 and fails this one, which is the pairing that
  stops the cheap answer being taken silently.
- [ ] AC4 — Given `tools/release`'s usage line and `retro` Step 5, when read together, then they
  describe the same invocation. Red when either is changed without the other.

## QA plan

- **Why that level:** `unit` is the only runner here and it covers both halves — `tests/*.test.sh`
  greps the prose for AC2-AC4, and `tests/release.test.sh` already drives the real script against a
  real git fixture with a real bare remote, which is what AC1 needs.
- **Specific checks:** AC1 is driven in `tests/release.test.sh`'s existing fixture, with stdin and
  `/dev/tty` unavailable, asserting on the **message** rather than the exit status — that file's
  header already states why (*a silent refusal exits non-zero too*). AC2-AC4 are section-anchored
  prose assertions. Prove each can fail by mutating the clause it matches and reverting.
- **Do not drive AC1 against the real remote.** `tests/release.test.sh` never pushes anywhere real
  and never shells out to `claude`; keep that property.

## Out of scope

- **The multi-repo form of the chain and its report** — 0113. Different failure in the same bullet:
  that one is about a pass that can run the chain and cannot describe the result.
- **Fetching before the edits and deriving the bump from the remote** — 0075. This ticket does not
  change how the version is chosen, only whether the chain finishes.
- Making `tools/release` non-interactive by default for a human at a terminal.

## Notes & decisions

- **Routed to `design`.** The finding named two candidate fixes and judged the second more likely.
  That is a preference, not a decision, and the two write incompatible ACs against different files.
  The blocking part is not which is nicer — it is that `git-conventions.md` requires the push
  confirmation to be specific, so removing the prompt is only permissible if the approval is
  evidenced elsewhere, and deciding *where* is the work.
- Verified 2026-09-07 against the current tree: `tools/release:294` is the `die`, `:23` and `:340`
  carry `--yes`, and `skills/retro/SKILL.md` Step 5 names neither.
- Captured from `FINDINGS.md` 2026-09-07.
