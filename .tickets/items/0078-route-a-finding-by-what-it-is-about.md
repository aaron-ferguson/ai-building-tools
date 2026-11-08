---
id: "0078"
title: Route a finding by what it is about, not which repo you are standing in
type: feature
next:
status: done
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
closed: 2026-09-09
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

- [x] AC1 — `develop`, `verify` and `retro`'s park steps route a tool finding to the tool repo's buffer and
  everything else to the local one.
- [x] AC2 — The rule names how the destination repo is resolved, and says to stop rather than guess.
- [x] AC3 — The install-only fallback is stated: park locally with a marker naming the destination.
- [x] AC4 — The privacy constraint on writing into a public tool repo is stated at the routing rule.
- [x] AC5 — Deleting the routing sentence from any one of the three skills turns a guard red.

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

- **Built 2026-09-09 [c594]. One home for the rule: `references/CONVENTIONS.md`, new section
  *Routing a finding to the repo it is about*.** Every stage already resolves and reads that file
  before it acts, so the pointer costs no extra fetch, and each of the six park steps carries one
  sentence citing it rather than a copy (NFR *Documentation*). It puts that file 178 bytes over the
  reference-size goal after the story was compressed out; the justification is recorded in
  `tests/reference-size.test.sh` and names what was considered relocating and why it was rejected —
  relocation fails **both** of the size guard's conditions here, since every stage has a park step
  so p is ~0, and the rule is mandatory the moment a park is reached.

- **FR1's destination was sharpened rather than built as written, and the sibling that moved it is
  not in `DONE.md`.** FR1 says "that tool repo's `FINDINGS.md`", which was unambiguous at capture
  (2026-09-01) and is not now: on **2026-09-07** the conventions repo grew a **root** `FINDINGS.md`
  declaring itself the buffer for gaps found from **outside**, with `.claude/backlog/FINDINGS.md`
  for gaps found from inside, its own entry format, and an explicit "neither sweeps the other". So a
  convention finding routes to the **root** file; this repo has no root buffer, so a tools finding
  routes to `.claude/backlog/FINDINGS.md`. The destinations are **asymmetric per repo** and the rule
  names each one, because "that repo's `FINDINGS.md`" would have written from-outside entries into
  the from-inside buffer. Nothing in `DONE.md` records this — the change landed in another repo — so
  the only thing that surfaced it was opening the destination before writing to it.

- **FR2 is a declared config key, not a derivation, and the reason is measured.** `tools.path` in
  `config.yml`, resolved from the repo root exactly as `conventions.path` is. The derivation a
  session would reach for first was probed rather than trusted and both halves mislead — the install
  directory is not a git repository, while the marketplace clone beside it is one with the right
  `origin`, an identical `HEAD` and a complete backlog. Full detail in `FINDINGS.md` 2026-09-09,
  including the consequence for **0075**, which is still `ready`: that clone reports `ahead 213`
  while being level, so 0075's divergence check would answer confidently wrong there. The key was
  added to `skills/queue/templates/config.yml` only — **this repo is the tool repo**, so a finding
  about it is already local and a self-referential key here would be noise.

- **FR1 is applied to six skills, not the three the ACs name.** `design`, `develop`, `prototype`,
  `queue`, `retro` and `verify` all carry a park step, and FR1 says *every* stage skill. The guard
  asserts one case per skill, so a rule applied to only some of them reds rather than passing.

- **FR5's read side is deliberately narrow, and 0111 depends on the exact wording.** `retro` Step 1
  now reads the tools repo's buffer as well, resolved by this rule and not discovered, and says
  *sweep only what a rule names; a buffer that is merely nearby is not an input*. **0111** owns
  Step 1's resolution ladder and its FR6 cites this item as the one rule naming a second buffer — so
  that sentence is the compatibility surface between the two tickets, and rewording it is 0111's
  problem as well as this one's.

- **`qa_level: unit` was the right level** — the deliverable is prose across seven files plus one new
  guard, and the whole suite is what proves it. All 25 test files green, 0 failed.

- **A guarded phrase broke from a rewrap, not from an edit — and the order the work was done in is
  what hid it.** `CLAUDE.md`'s rule about rewrapping a guarded paragraph was read before anything was
  written, and the phrases were still chosen first and the prose *then* compressed for the size
  guard, which re-flowed three of them across line breaks and cost four reds. A size-driven rewrap of
  a paragraph you are still drafting does not feel like editing a guarded one. Parked with the cheap
  mitigation neither guard states: after any reflow, `grep -n` each asserted phrase and require one
  hit per file.

## QA evidence

Verified 2026-09-09 [d89c] at `qa_level: unit` — this repo's whole suite, 25 files, run
individually rather than through the fail-fast one-liner so a red could be attributed
(`config.yml` says why). **25/25 green, 0 failed.** Frontmatter level and the QA plan's stated
level agree, so no drift to report. Tree clean at Step 2 and again at the verdict, so the
intersection with the evidence set is empty and this is a plain PASS, not advisory.

Every red below was produced by mutating a **committed** file, confirming the diff was non-empty
and the phrase count went 1 → 0, then restoring by that pathspec alone. The sequence ends on a
green control run of all 25 files, which is what licenses the reds.

| # | Claim | How it was checked | Result |
|---|---|---|---|
| AC1 | Park steps route a tool finding to the tool repo's buffer, everything else local | `findings-routing.test.sh` asserts the routing sentence and the `references/CONVENTIONS.md` citation inside each park step's window, keyed by heading text; all six skills carry both. Deleted the sentence from each of the six real files in turn — each reddened its own case | PASS |
| AC1 | The rule names all three destinations | The `Routing a finding to the repo it is about` window names the conventions repo's root buffer, the tools repo's `.claude/backlog/FINDINGS.md`, and local. Deleting `stays in the local` reddened that case alone (40 passed, 1 failed) | PASS |
| AC2 | The rule says how the repo is resolved, and to stop rather than guess | `tools.path`, resolved as `conventions.path` is, plus `Nothing resolving is a stop` and the prohibition on deriving from the plugin install. Deleting `tools.path` reddened one case (40/1) | PASS |
| AC3 | The install-only fallback is a marked local park naming its destination | `falls back to a marked local park`, `[for <repo>]`, `forwards it`. Deleting the fallback reddened AC3 and left AC4 green | PASS |
| AC4 | The privacy constraint sits at the routing rule | `carries no company material` … `stays local`. Deleting it reddened AC4 and left AC3 green — so neither clause covers the other | PASS |
| AC5 | Deleting the routing sentence from any one of the three named skills turns a guard red | Done on the real files for `verify`, `develop` and `retro` (and the other three FR1 names): each gave `39 passed, 2 failed` — the AC1 case plus the guard's own probe correctly reporting the sentence was never there to delete | PASS |
| AC5 | (extra) A rewrap reds too, not only a deletion | Broke the phrase across a line break with every word intact → `39 passed, 2 failed`. Correct direction; the known cost is that a harmless reflow also reds (0063, 0112) | PASS |
| FR2 | The config key is real, and the derivation it replaces is genuinely misleading | `tools.path` present in `skills/queue/templates/config.yml`. Reproduced both halves of the measured justification: the install dir is not a git repo, while `~/.claude/plugins/marketplaces/ai-building-tools/` has the right `origin`, a full backlog, and reports `## main...origin/main [ahead 213]` while level | PASS |
| FR5 | `retro` reads the tools repo's buffer as well | Asserted in `retro` Step 1's own window, resolved by the rule rather than discovered, with the "sweep only what a rule names" sentence 0111's FR6 depends on | PASS |
| NFR Privacy | Nothing crossing into this public repo carries company material | Scanned the whole ticket diff for client/company markers: two hits, one the rule's own text, one `AetherWorks` in the guard header — pre-existing across 19 files since `00871cd`, not introduced here | PASS |
| NFR Git | One commit per repo, by pathspec, never spanning two | All seven commits inspected: each touches one coherent path set, none spans repos, and the conventions repo is untouched and clean | PASS |
| NFR Docs | The rule is stated once and cited elsewhere | The four substantive clauses appear in `references/CONVENTIONS.md` and nowhere else; each skill carries exactly one citation (`retro` two — park step and Step 1 for FR5). No copies to drift | PASS |

**Checked beyond the table.** The destination the rule points at was opened rather than assumed:
the conventions repo's root `FINDINGS.md` does declare the outside/inside split the rule asserts,
so the asymmetry recorded in the build notes is real. The newly reachable path this change creates
— a stage session writing and committing into *another* repo's backlog — is constrained at the
rule itself (resolved never guessed, one commit per repo by pathspec, that backlog's lock, the
privacy bar), so it is reviewed rather than merely new.

**Two observations parked, neither blocking** (`FINDINGS.md`, 2026-09-09): the independence probes
report a wrong *reason* when run against an already-mutated file, and two pairs of asserted phrases
share a source line so they cannot red independently. Both are guard-quality notes; the ACs hold.
