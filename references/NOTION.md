# Importing reported feedback from Notion

Read by `queue` when `.claude/backlog/config.yml` carries `notion.enabled: true`. Opt-in and
absent by default — most projects never collect feedback from other people, so nothing here is
read on a normal capture.

---

## The flow is one-way: Notion → local

Notion is where other humans report. The local queue is what agents work from. **Nothing is
written back.** A status set in Notion is a report about the world, not a decision about the
backlog; writing back would make Notion a second source of truth for a rank and a stage that
only the local item can carry.

An imported page is a *report*, not a work item. It gets the same treatment as an entry in
`FINDINGS.md`: the full Step 2 specification, then a considered rank per Step 3. A Notion
`Priority: Urgent` is one input to tier selection and nothing more.

## The import

1. `mcp__claude_ai_Notion__notion-query-data-sources` on `notion.data_source_id`.
2. **Skip any page whose id already appears in `imported-notion-ids.txt`.** That log is what
   makes the import idempotent; without it a second run re-captures every page as a new ticket.
3. Map its fields, then run `queue`'s three numbered steps for a parked entry — specify it, leave
   it out of `QUEUE.md` if you cannot, rank it once specified.
4. Set `source: notion:<page-id>` in the item frontmatter and **append the page id to the imported
   log in the same commit as the ticket**. Appended later, or not at all, the next run duplicates it.

## What is not imported

- A page that is a question rather than a work item. Answer it, or record it as `waiting` with the
  question in the item's `## Waiting on` section; do not rank a ticket whose problem is unknown.
- A page's own comments thread. Quote what the *Problem* section needs verbatim and cite the page;
  a ticket that requires reading a Notion thread to understand cannot be built by a cold agent.
