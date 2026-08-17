# Mirroring to an external tracker, and recording what an item cost

Read by `queue` and `develop` when `.claude/backlog/config.yml` carries a `tracker:` or
`cost_tracking:` block. Both are opt-in and absent by default.

These tools own **workflow**, not standards — the same split `CONVENTIONS.md` describes.
So: *how* to mirror is here. *Which* tracker, project, and issue types belong to a
company profile, because they are facts about an organization, not about backlogs.

---

## Why the mirror is one-way

The local item is the source of truth for agents. It carries functional requirements,
an NFR table citing convention files, given/when/then acceptance criteria, and a QA
level. A ticket in a general-purpose tracker carries a title, a description, and a
status. Treating the ticket as authoritative would mean `verify` checking a summary
instead of the criteria, which is the whole failure the item format exists to prevent.

Three consequences, and they are the reason to write this down rather than infer it:

- **Local wins on every field it carries.** Never read a ticket back and overwrite an
  item from it. If a human edits the ticket's description, that edit is a comment on
  the item, not a change to it — reconcile it deliberately, in the item file.
- **A tracker outage never blocks work.** Log the failure in the item's *Notes &
  decisions*, report it, and continue. An agent that stops building because an API
  returned 503 has made an availability problem into a delivery problem.
- **Never hold the lock across a network call.** Mirror after releasing it. The lock
  exists to serialize a read-modify-write on one file for a few milliseconds; a hung
  HTTP request inside it strands the other window.

Work humans file *in* the tracker travels the other direction and is a separate,
explicit import — the same shape as the Notion import in `queue`, where a raw report
becomes a properly specified item rather than being copied across.

---

## Resolving where to mirror

Resolve once, at the start of the skill, and stop at the first that answers:

**1. `.claude/backlog/config.yml` → `tracker:`**

```yaml
tracker:
  enabled: true
  type: jira
  site: <instance>
  project_key: <KEY>
  issue_type_for:
    feature: Story
    bug: Bug
    chore: Task
    debt: Task
  mirror_on: [claim, close, block]
```

**2. The company profile named in the project's `CLAUDE.md` `## Profile` block.** It
declares the organization's tracker and its project keys. Use it to *fill in* the config
block — then write the result back to `config.yml` so the next session does not re-derive
it, exactly as `queue` does with `conventions.path`.

**3. Neither resolves → do not mirror.** This is a normal, silent outcome. Do not guess a
project key, do not create a project, and do not prompt to set one up unless the user
raises it. A ticket in the wrong project is worse than no ticket: it is noise in someone
else's board, and nobody will thank you for it.

**`enabled: false` with a populated block means "wired but deliberately off"** — usually
a project key that does not exist yet. Respect it; do not treat a filled-in block as
consent.

### What to write

- **On claim** — create the ticket if the item has no `tracker_key`, else transition it.
  Title from the item title. Body: the problem statement, the acceptance criteria, and a
  pointer to the item path. **Do not paste the NFR table** — it cites convention files by
  name and those names mean nothing outside the repo.
- **Store the key in the item's frontmatter** as `tracker_key: <KEY>-123`, and report it.
- **On close** — transition to done and comment the commit SHAs, so a human on the ticket
  can reach the code without asking.
- **On block** — transition and comment the blocker reason from the item file.

### What never goes in a ticket

Trackers are widely readable and permanent. Do not mirror customer data, credentials,
extract contents, log excerpts containing personal data, or anything the project's
conventions classify as sensitive. When an item's problem statement quotes real data as
evidence, the ticket gets the shape of the problem and the item keeps the specifics.

---

## Recording what an item cost

```yaml
cost_tracking:
  enabled: true
  transcript_dir: <path to this project's Claude Code transcripts>
  effort_ledger: <path to the human-hours ledger, if the project keeps one>
```

On close, append to the item file:

```markdown
## Actual cost

- **Sessions:** <session ids that worked this item>
- **Tokens:** <in> in / <out> out
- **Model cost:** $<amount> (list rates)
- **Wall clock:** <first claim to close>
- **Estimated size:** <s|m|l> — **actual:** <one line: matched, or why not>
```

**Why this belongs at close and nowhere else.** Aggregate spend can be recomputed from
transcripts at any time. *Attribution* cannot: only the session that did the work knows
which item its tokens belonged to, and once the conversation ends that mapping is gone
for good. Skipping this step does not defer the data — it destroys it.

Two uses, both of which fail without it:

- **Calibration.** `size` is an input to ranking. Recording actuals is what turns it from
  a feeling into a measurement, so the next `m` is judged against what the last several
  `m`s really cost.
- **Honest reporting.** A project justified on an AI-first estimate has to be able to
  answer whether the estimate held. It cannot answer that from a number that only exists
  in aggregate.

**Model tokens are not the cost of the work.** Human time — direction, review, and
verification — is typically the dominant term by one to two orders of magnitude. Where a
project keeps an `effort_ledger`, the item's cost line is incomplete until the hours are
in it, and any report combining them must say plainly what it counted and what it did
not. Reporting token cost as though it were total cost is the single easiest way to
produce a number that is both impressive and false.
