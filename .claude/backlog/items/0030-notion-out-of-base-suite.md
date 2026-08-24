---
id: "0030"
title: Remove Notion from the base tool suite and make it profile-wired
type: debt
next: verify
status: ready
qa_level: verify
size: m
created: 2026-08-23
source: user
expects:
  - skills/queue/SKILL.md
  - skills/queue/templates/config.yml
  - skills/queue/templates/item.md
  - references/NOTION.md
  - references/TRACKER.md
  - README.md
claimed_by:
claimed_at:
touches:
---

## Problem

Notion is wired into the base tool suite as though it were a default: `queue` Step 0 tells a
scaffold to consider a `notion:` block, Step 5 gives Notion its own row in the "surface parked
work" source table and a numbered import procedure, and `references/NOTION.md` ships at the plugin
root. Every project scaffolded by this suite therefore inherits a decision about where other
people's feedback lives.

Aaron's call, 2026-08-23: *"Notion is a tool that I've used for solo projects, but it is a
profile-specific preference, not a principle or a tool default. Notion should not be included in
the base tool suite in any way, but it can be referenced as a company or solo preference to be
wired in as appropriate."*

That is the same split the conventions already draw — `CONVENTIONS_CORE.md` separates principles
from preferences and puts preferences behind a profile — and the tracker integration already
models the compliant shape: `tracker:` is off unless configured, *which* tracker is a
company-profile question, and the skill never prompts for it. Notion is currently more deeply
baked than that: it is named in the skill's own prose and in its description metadata.

## Functional requirements

- FR1 — `queue` Step 5 holds no Notion-specific source row, procedure, or field mapping. The step
  keeps `FINDINGS.md` as its source and describes an *externally-reported* source generically,
  pointing at whatever the project's profile wires in.
- FR2 — `queue` Step 0 does not mention `notion:` when scaffolding, and the shipped
  `templates/config.yml` carries no `notion:` block.
- FR3 — `queue`'s frontmatter `description:` does not name Notion. ("import feedback from Notion"
  is currently a trigger phrase, so the skill advertises the integration it is losing.)
- FR4 — `references/NOTION.md` no longer ships as part of the base suite. It moves to whatever
  location the profile mechanism reads, or is deleted, and the ticket records which and why.
- FR5 — the generic extension point is documented once, in the place a profile author would look:
  what an external feedback source must provide for `queue` Step 5 to sweep it (a query, a stable
  page id to de-duplicate on, a field mapping, and the one-way rule that nothing is written back).
- FR6 — the same sweep for any *other* Notion reference the base suite carries: `README.md`, the
  `imported-notion-ids.txt` mechanism, and `source: notion:<page-id>` in `templates/item.md`. The
  `source:` field keeps a generic external form rather than a Notion-specific one.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Dependencies | Removing an integration from the base suite must not leave a dangling MCP tool citation the skill can no longer reach; the profile that wires it back in owns that dependency | `dependency-conventions.md` |
| Documentation | The removal is a preference moving behind a profile, not a capability being dropped — record that distinction where a reader of the base suite would otherwise conclude the feature was withdrawn | `documentation-conventions.md` |
| Deprecation | Aaron's own solo projects may have `notion.enabled: true` in a live `config.yml`; there must be a stated wiring path before the base suite stops reading it, not after | `deprecation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the shipped tree, when `grep -ril notion skills/ references/ README.md` runs,
  then it reports no match outside a file that exists specifically to describe the profile
  extension point.
- [ ] AC2 — Given `templates/config.yml`, when it is read, then it contains no `notion:` key.
- [ ] AC3 — Given `skills/queue/SKILL.md`, when its `description:` frontmatter is read, then
  "Notion" does not appear in it.
- [ ] AC4 — Given `queue` Step 5, when it is read, then it names `FINDINGS.md` as its always-
  available source and describes any external source by reference to the project's profile,
  without naming a specific product.
- [ ] AC5 — Given a project whose `config.yml` has no external-feedback block, when `queue` Step 5
  runs, then it sweeps `FINDINGS.md` and reports nothing about a missing integration — the current
  "skip silently and never prompt" behaviour is preserved.
- [ ] AC6 — Given `templates/item.md`, when the `source:` field's comment is read, then it
  describes a generic external form and does not use `notion:` as its example.

## QA plan

- **Level:** verify — this is documentation and template content with no runner behind it.
- **Why this level:** every requirement is a statement about file content, checkable by grep and by
  reading the two files that changed shape.
- **Specific checks:** `grep -ril notion skills/ references/ README.md .claude/backlog/config.yml`
  and `grep -n notion skills/queue/templates/config.yml skills/queue/templates/item.md`; read
  `queue` Step 5 whole to confirm it still reads coherently with one source rather than two;
  `tests/skill-size.test.sh` to confirm `queue` stays accounted for after the cut.

## Out of scope

- Building the profile mechanism itself, if one does not already exist. This ticket removes Notion
  from the base suite and states what a profile must provide; wiring Aaron's solo profile back up
  is separate work.
- Any change to the `tracker:` integration, which is already correctly profile-gated and is the
  model this ticket follows.
- Migrating existing Notion-sourced items in any project's backlog.

## Notes & decisions

- The `tracker:` block is the precedent for the compliant shape: off unless configured, never
  prompted for, and *which* product is a profile question. Follow it rather than inventing a
  second pattern.
- Why this ranks above the locally-painful tooling tickets: blast radius. Every project scaffolded
  by this suite inherits the Notion default, which is tie-breaker 1 (all projects > one project).

### Built 2026-08-24 (claim 1446)

- **FR4 resolved to delete, not move, and this is the decision the FR asked to have recorded.** The
  base suite has no profile mechanism to move the file *into* — building one is this ticket's own
  *Out of scope* — so a "move" would have meant inventing the destination the ticket forbids
  inventing. `references/NOTION.md` is therefore removed, and the Notion-specific procedure (the MCP
  data-source call, the page-id log, the property mapping) survives verbatim in git history.
  `EXTERNAL-FEEDBACK.md` names the retrieval command — `git log --diff-filter=D --
  references/NOTION.md` — so the port into a profile is a lookup, not a reconstruction from memory.
  That is what discharges the deprecation NFR: the replacement path is stated in the same change
  that stops the base suite reading `notion:`, not after it.
- **`expects:` named four files; the code had six.** `references/TRACKER.md:33` cited the Notion
  import as the shape a tracker's reverse import follows, and `templates/item.md:26` used
  `notion:<page-id>` as the `source:` example. FR6 had predicted `item.md` in prose without it
  reaching the frontmatter list, and nothing predicted `TRACKER.md` — a cross-reference from an
  unrelated file is exactly what a ticket written weeks earlier cannot enumerate. Both are promoted
  into `touches:`. Calibration for the next capture: grep the product name, do not reason about
  which files "own" the integration.
- **Removing an integration made the skill file bigger, not smaller — 24,486 → 24,652 bytes.** This
  is counter-intuitive enough to be worth stating before someone treats it as a defect: a
  product-specific procedure is short because the product supplies the nouns, whereas a generic
  extension point has to explain the indirection itself (*which* product is a profile question, why
  the default is absence, where the shape is documented). The saving is real but lands in the
  conditionally-read `references/` file, which is the "pointer, not a cut" move `skill-size.test.sh`
  recommends — it just does not show up as a smaller SKILL.md. `queue`'s recorded justification in
  that guard still holds; the file was 4.3KB over the goal before this ticket and remains so.
- **The guard is a grep for the product name, not for the config key.** The likely regression here is
  not a deliberate reversal but a helpful later session adding "e.g. Notion" as an illustration — a
  key-shaped check would pass straight through that. `tests/external-feedback.test.sh` exempts
  exactly one path, `references/EXTERNAL-FEEDBACK.md`, because an extension point with no named
  example of a source is an abstraction nobody can implement against; a fixture case asserts the
  exemption is that one path and not "any file that mentions it".
- **Scope held, with one deliberate exception.** The prose added for the generic extension point was
  tightened after it measured larger than what it replaced. That is not scope creep into a
  refactor — it is the context-rent rule in `CONVENTIONS_CORE.md` applied to the lines this ticket
  itself wrote.
