---
id: "0214"
title: Add a profile-declared gate that a stage refuses to pass without its artifact
type: feature
next: design
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: l
created: 2026-10-20
source: user
parent:
blocked_by: []
relates: ["0100", "0101"]
expects: skills/queue/SKILL.md, skills/queue/templates/item.md, skills/queue/templates/close, skills/develop/SKILL.md, skills/verify/SKILL.md, references/CONVENTIONS.md, references/TRACKER.md, tests/
claimed_by:
claimed_at:
touches:
---

## Problem

A company profile can already say facts about an organization that these skills read generically — which tracker, which project keys (`references/TRACKER.md`). It cannot say "a change of this kind may not pass a stage until this artifact exists". An organization that needs one (a compliance record, a sign-off, a disclosure sheet for a class of change) can only put the rule in prose in its profile, which a session may or may not load and which nothing refuses on. A rule broken once in prose was never enforceable as prose (`CONVENTIONS_CORE.md`, *Prefer enforcement over instruction*).

The skills must stay company-agnostic: this repo is public and `company: none`. So the mechanism has to be generic — the profile names the gate, the skills only know "a profile-declared gate" — and a project with no profile, or a profile declaring no gate, must behave exactly as it does today.

## Open design question

- **Question:** Where does a profile declare a gate, and what does each stage do with it? Specifically: (a) the declaration shape — a gate name, a trigger question `queue` asks, the item-frontmatter field holding the artifact link, and the stage it blocks; (b) whether `close` and `next` can enforce it, given scripts resolve nothing from a company profile today, or whether `queue` copies the resolved gate into `config.yml` the way it records `conventions.path`; (c) what a gate whose profile cannot be read does.
- **Why it blocks specification:** AC for "refuses to close" cannot name what `close` reads until (b) is settled, and the two candidate answers (script reads profile vs. config.yml cache) give different failure modes.
- **Settle it with:** `/design`

## Functional requirements

Provisional — `design` confirms or rewrites these when it settles the question above.

- FR1 — A profile can declare one or more required gates, each with a name, a trigger question, an item-frontmatter field, and the stage it blocks. The shape is documented once in `references/`, with no company-specific example.
- FR2 — `queue`, on Add, asks each declared gate's trigger question and, on yes, requires the field to be filled before the ticket leaves `next: queue`.
- FR3 — The implementing code, not only prose: `close` (and `next`, where it offers a row) refuse a ticket whose triggered gate field is empty at the blocked stage, naming the gate.
- FR4 — `develop` and `verify` state the gate in their closing steps by citing the reference, not restating it.
- FR5 — A project whose profile declares no gate behaves byte-for-byte as before.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Security | A gate whose declaration cannot be read or parsed blocks the stage rather than passing it | a fixture with a malformed declaration; `close` must exit non-zero | `security-conventions.md` |
| Privacy & data | No company, client or industry material in any changed file, the ticket, or the commit | grep of the diff and message for the profile's own names returns nothing | `data-privacy-conventions.md` |
| Documentation | The declaration shape lives in one reference file and every skill cites it | a second copy of the field list in a skill fails the drift guard | `documentation-conventions.md` |

## Acceptance criteria

Provisional until `design` lands; each names what reds it.

- [ ] AC1 — Given a fixture profile declaring a gate on field `X` blocking `verify`, when `close` runs on a triggered ticket with `X` empty, it exits non-zero and names the gate. Red: removing the check makes the close succeed.
- [ ] AC2 — Given the same ticket with `X` filled, `close` succeeds. Red: a check that refuses on mere presence of the gate fails this.
- [ ] AC3 — Given a fixture with no profile, or a profile declaring no gate, the suite's existing outputs for `close` and `next` are unchanged. Red: any new line in either output.
- [ ] AC4 — Given a gate declaration that is malformed, the stage blocks and says why. Red: a parser that defaults to "no gate" on error passes it.

## QA plan

- **Why that level:** the changed artifacts are skills, templates and a close script; the repo has no test runner, so each AC names a scripted assertion in `tests/*.test.sh`.
- **Specific checks:** a new `tests/profile-gate.test.sh` covering AC1–AC4 with fixture profiles; the full existing suite for FR5.

## Out of scope

- Any specific gate. What a gate is called, what it asks and what artifact it demands is the profile's content and never this repo's.
- Reading a company profile for anything other than gate declarations.
- Retrofitting existing backlogs.

## Notes & decisions

- 2026-10-20: Captured from a request to make an organization's pre-pilot AI documentation requirement mechanical instead of prose. Routed to `design` because decision (b) — script reads the profile, or `queue` caches the gate in `config.yml` — blocks writing the enforcement ACs. Company-specific content was deliberately left out of this ticket; it lives in that company's profile.
- 2026-10-20: Minted as 0204 and renumbered to 0214 on rebase — another session had issued 0204 upstream (`0204-route-a-queue-completion-that-re-specifies-a-waiti.md`). Citations to 0204 for this work are this ticket.
