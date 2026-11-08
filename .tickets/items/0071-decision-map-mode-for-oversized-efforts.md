---
id: "0071"
title: Add a decision-map mode for work too large or too foggy for one project ticket
type: feature
next: design
status: ready
qa_level: verify
size: l
created: 2026-08-26
source: agent
parent:
blocked_by: []
relates: ["0069"]
expects:
  - skills/queue/SKILL.md
  - skills/queue/templates/item.md
claimed_by:
claimed_at:
touches:
---

## Problem

`/queue`'s existing project/parent mechanism (`parent:` in `templates/item.md`) already lets a
ticket with children become a project that's never itself ranked, claimed, or built — 0001, 0002,
0009, and 0036 all use it today. But nothing in `/queue` or `/design` says how to *chart* one of
these before its children exist: what to call the destination, how to record what's still too
fuzzy to ticket without either inventing premature tickets or losing track of the fog, or how to
tell "this needs its own project" from "this is just a large `size: l` ticket."

A comparable external skill (`wayfinder`, surveyed 2026-08-26) answers exactly this for "a huge
chunk of work, wrapped in fog, too big for one session": name the destination first (it fixes
scope), chart the frontier breadth-first, create only the tickets specifiable *now*, and hold
everything else in an explicit "not yet specified" section that graduates into tickets as the fog
clears — never pre-sliced into ticket-sized pieces before it's sharp enough. It also distinguishes
"not yet specified" (in scope, not yet sharp) from "out of scope" (ruled out by the destination) —
a distinction the project/parent mechanism has no equivalent for today: a project ticket here
either has children or it doesn't, with nothing standing for "known unknowns not yet ticketed."

## Open design question

- **Question:** does adopting this mean extending the existing project/parent mechanism (adding a
  "not yet specified" / "out of scope" section to a project ticket's body, and a charting step to
  `/queue` or `/design` for when a project is first created) — or introducing it as a separate
  charting skill that only hands off into `/queue` once the map is legible, the way the surveyed
  repo keeps its decision-map skill standalone from its ticket-breakdown skill? The first extends a
  mechanism this backlog already leans on hard (four active projects); the second adds a skill
  this toolkit doesn't have a slot for yet (none of `queue`/`design`/`prototype`/`develop`/
  `verify`/`retro` currently owns "is this even ticketable yet").
- **Why it blocks specification:** the two shapes have different acceptance criteria and different
  blast radius — one touches `templates/item.md` and `skills/queue/SKILL.md`'s existing
  project-ticket rules, which four live projects already depend on; the other is additive and
  lower-risk but means a seventh skill.
- **Settle it with:** `/design` — read `templates/item.md`'s `parent:` documentation and how 0036
  was actually charted in practice (per `RANKING-HISTORY.md`'s "0036 became a project" entries)
  before deciding whether the existing mechanism is already most of the way there.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — A project ticket can record work that is known to be in scope but not yet specific enough
  to ticket, distinct from work explicitly ruled out of scope, and distinct from its list of
  resolved decisions.
- FR2 — Whatever charts a new project states the destination — what reaching the end of this
  effort looks like — before any child ticket is created, on the stated basis that naming the
  destination is what fixes the scope for everything charted after it.
- FR3 — The mechanism never requires pre-slicing not-yet-specified work into ticket-sized pieces
  before it's sharp enough to state as a decidable question; the existing `queue` discipline of
  "insert only what you can specify now" is respected, not overridden.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | If `templates/item.md`'s project-ticket body gains new sections, existing project tickets (0001, 0002, 0009, 0036) stay readable under the old form until someone chooses to backfill them — no sweep is required by this ticket | `migration-conventions.md` |
| Documentation | The destination-first rule and the not-yet-specified/out-of-scope distinction are stated once, in the skill(s) that own project charting | `documentation-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled.

- [ ] AC1 — Given a project ticket, when it names something in scope but not yet specific enough
  to ticket, then that entry is visibly distinct from its out-of-scope entries and from its list
  of resolved decisions.
- [ ] AC2 — Given a new project being charted, when the first child ticket is created, then the
  project's destination has already been stated.
- [ ] AC3 — Given the four existing project tickets (0001, 0002, 0009, 0036), when read after this
  ticket lands, then they still parse under whichever mechanism `/queue` and `/develop` use to find
  project rows — no breakage of the live backlog.

## QA plan

- **Level:** verify — provisional; a template/prose change stays `verify`; revisit if the design
  answer changes `next`/`claim`/`close`'s parsing of project rows, which would make it `unit`.
- **Why this level:** the likely deliverable is a template and skill-file change; the scripts only
  enter if the design answer touches how they detect a project row.
- **Specific checks:** a scoped grep for the destination-first rule and the not-yet-specified /
  out-of-scope distinction; if `next`/`claim`/`close` change, this project's full `tests/*.test.sh`
  suite runs.

## Out of scope

- Re-charting any of the four existing live projects under the new mechanism.
- A visual map renderer — the surveyed skill's "map" is a single tracker issue with a body
  convention, not a diagram; this ticket is about the vocabulary and body shape, not a UI.

## Notes & decisions

- Captured 2026-08-26 from a comparison against a third-party skills repo (`wayfinder`,
  github.com/mattpocock/skills).
- Sized `l`: the design question's answer plausibly touches a mechanism four live projects depend
  on, which is real blast radius even though nothing about it is urgent.
- Relates to 0069 — see that ticket's note.
