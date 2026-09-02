---
id: "0078"
title: Route a finding by what it is about, not which repo you are standing in
type: feature
next: develop
status: ready
qa_level: unit
size: m
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0075", "0080"]
expects:
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/retro/SKILL.md
  - skills/queue/SKILL.md
  - references/CONVENTIONS.md
claimed_by:
claimed_at:
touches:
---

## Problem

**A finding about the toolkit, noticed while working a consuming project, has no route to the
toolkit.** Every stage skill's *park what surprised you* step writes to the **local** project's
`FINDINGS.md`, whatever the finding is about. From there:

- the project's `/queue` writes rows to the **project's** queue, where a skill defect does not belong;
- `CONCURRENCY.md`'s *A stage writes only the ticket it holds* forbids a stage from authoring a row
  anywhere else;
- so the only thing that ever crosses the repo boundary is `/retro`, which can make **edits** and
  never **rows**.

**The result is measured, not hypothetical.** AetherWorks' buffer on 2026-09-01 held **44 entries
over ten days**, of which **25 pointed at a skill, a convention file or a backlog script** — while
**0 of its 34 queue rows did**. Findings with no route sat until a retro happened to run, and were
re-read at full price by every sweep in between. Two of them recurred verbatim while waiting: the
e2e probe-scaffolding gap was filed 2026-08-30 and again 2026-09-01, and the "fold into item NNNN"
gap was filed twice and then *measured* a third time at six items and twelve checks.

**The destination already exists and works.** This repo has its own backlog — `QUEUE.md`,
`FINDINGS.md`, items, and the same `claim`/`close`/`next` scripts. The 2026-09-01 retro parked its
own three findings **here** instead of in AetherWorks, and they were immediately in reach of this
queue. That is the whole fix: route by subject, and the existing machinery works unchanged.

`references/EXTERNAL-FEEDBACK.md` is not this. It is one-directional and points inward — other
people's reports arriving *into* a project's queue. Nothing carries a project's findings outward.

## Functional requirements

1. **The park step in every stage skill routes by subject**: a finding about a skill, a convention
   file, or a backlog script is parked in that tool repo's `FINDINGS.md`; everything else stays local.
2. **The tool repo is resolved, not guessed.** The conventions directory is already resolved per
   `references/CONVENTIONS.md`; the same resolution names where a conventions finding goes. Say how
   the tools repo is located, and **stop rather than guess** when it cannot be — the same refusal
   `CONVENTIONS.md` already makes.
3. **A repo that is not a writable checkout falls back to parking locally, marked**, with the marker
   naming the destination repo, so a later `retro` forwards it rather than re-deriving it.
4. **The commit is by pathspec in the destination repo**, in the same turn, per `CONCURRENCY.md` —
   parking across a boundary must not sweep another session's staged work in either repo.
5. **`retro` reads the tool repo's own buffer** as well as the project's when it runs there.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | This repo is public. A finding routed here must carry no company material, client name or private path — the `company: none` constraint in this repo's `CLAUDE.md` binds anything written here by any project. | `data-privacy-conventions.md` |
| Git | One commit per repo, by pathspec, same turn. Never one commit spanning two repos. | `git-conventions.md` |
| Documentation | Each skill states the routing rule once and cites it elsewhere; four copies of it would drift. | `documentation-conventions.md` |

## Acceptance criteria

1. `develop`, `verify` and `retro`'s park steps route a tool finding to the tool repo's buffer and
   everything else to the local one.
2. The rule names how the destination repo is resolved, and says to stop rather than guess.
3. The install-only fallback is stated: park locally with a marker naming the destination.
4. The privacy constraint on writing into a public tool repo is stated at the routing rule.
5. Deleting the routing sentence from any one of the three skills turns a guard red.

## QA plan

- **Level:** unit — this repo's whole suite.
- **Why this level:** prose across four skills; every guard here greps prose.
- **Specific checks:** one assertion per skill, each on its own line, matching the routing sentence
  in that file. Prove each can fail by deleting the line it matches. Assert the fallback and the
  privacy clause separately, so dropping either reds on its own.

## Out of scope

- Building the forwarding mechanism for the install-only case. FR3 records the marker; a `retro` that
  forwards markers is a second row, worth writing when a second machine exists.
- Changing `EXTERNAL-FEEDBACK.md`, which governs the inbound direction and is unaffected.

## Notes & decisions

- Aaron, 2026-09-01: *"Updating, using this toolkit, should include improving the toolkit. Any project
  that uses the toolkit should be able to send back feedback on how to make that toolkit better."*
- The three candidate shapes floated in AetherWorks' buffer were a `type: tooling` switch on the item,
  a separate `/improve` stage, and a tooling backlog living in the tool repos. **This item is the
  third**, and it needs no new stage and no new field.
