# Sweeping an external feedback source

Read by `queue` Step 5 when the project's `config.yml` carries an `external_feedback:` block.
**Absent by default and never prompted for** — most projects collect no feedback from other
people, and a project with no block sweeps `FINDINGS.md` alone and says nothing about a missing
integration.

*Which* product sits behind this is a **profile** question — a company's or a solo author's
preference, wired in where that profile lives — not a decision the base suite makes on behalf of
every project it scaffolds. `CONVENTIONS_CORE.md` draws that line: a preference goes behind a
profile, and the profile may only add constraints. `tracker:` is the same shape and the model this
follows.

---

## What a source has to provide

Four things, and a source that cannot supply all four is not sweepable — capture it by hand
instead, which is what `FINDINGS.md` is for.

1. **A query** that returns the reports, resolvable from the config alone. A sweep that needs a
   human to say which view to read is not a sweep.
2. **A stable id per report**, recorded in an idempotency log named by the config and appended **in
   the same commit as the ticket**. This is what makes a second run a no-op; appended later, or not
   at all, the next sweep re-captures every report as a new ticket.
3. **A field mapping** — which property is the title, which the type, which the reported priority.
4. **A read path only.** Nothing is written back, ever.

## The flow is one-way, and the reason is not politeness

The source is where other humans **report**; the local queue is what agents **work from**. A status
set in the source is a report about the world, not a decision about the backlog. Writing back would
make it a second source of truth for a rank and a stage that only the local item can carry, and the
two would then disagree with nothing to arbitrate.

**An imported report is a report, not a work item.** It gets exactly the treatment an entry in
`FINDINGS.md` gets: the full Step 2 specification, then a considered rank per Step 3. An imported
`Priority: Urgent` is one input to tier selection and nothing more — a label set by someone who was
not ranking this queue does not outrank the tickets already in it.

## What is not imported

- **A report that is a question rather than a work item.** Answer it, or record it as `waiting` with
  the question in the item's `## Waiting on` section. Do not rank a ticket whose problem is unknown.
- **A report's comment thread.** Quote what the *Problem* section needs verbatim and cite the
  source; a ticket that requires reading a thread elsewhere to understand cannot be built by a cold
  agent, which is the whole bar Step 2 sets.

## The config block a profile adds

```yaml
external_feedback:
  enabled: true
  source: ""            # what the profile wires in; the profile owns this dependency
  query: ""             # resolvable from this file alone
  imported_log: imported-ids.txt
  title_property: ""
  type_property: ""
  priority_property: ""
```

The profile that names a `source:` owns the dependency it drags in — including whatever MCP server
or client the query needs (`dependency-conventions.md`). The base suite cites none, so it cannot be
left holding a citation it can no longer reach.

## If you had `notion:` configured

Notion shipped in this suite as a default until **2026-08-24**, when it moved behind this extension
point (ticket 0030). **The capability was not withdrawn** — what changed is that the base suite no
longer decides where other people's feedback lives.

To keep it working: put an `external_feedback:` block in that project's `config.yml` with the
mapping your old `notion:` block held, and wire the query into your profile. The Notion-specific
procedure — the MCP data-source call, the page-id log, the field mapping — is preserved verbatim in
git history at `references/NOTION.md`; `git log --diff-filter=D -- references/NOTION.md` finds the
commit that removed it. Nothing needs to be reconstructed from memory.
