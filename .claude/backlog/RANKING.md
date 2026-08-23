# Why the order is what it is

Standing reasoning. Read on a re-rank, not on every claim.

## Current shape

Two efforts are live and they contend for the same files.

**0009 — one skill per session** sits at the top by explicit decision (2026-08-23): finishing the
process work matters more than the nested-work phase behind it. It came out of a measured
end-to-end run costing $15.11 over 95 turns, of which 85% was context handling and 15% was
output. Twelve tasks in four gates.

**0002 — the ticket graph** is phase 1 of the nested-work design (effort 0001) and now sits
below it. Its tasks are unchanged and still correct; they are simply not first.

## The order

1. **0010** — the field model. First because everything else in 0009 reads or writes `next` and
   `status`, so landing it late means rewriting the same paragraphs twice. It also **took over
   FR3 of 0005**: both rewrite the queue's header row, to contradictory shapes, and one owner
   avoids writing that line twice.
2. **0012** — parking findings. Second and unblocked because it is the ticket that makes
   isolation safe rather than lossy, and it is useful on its own before any invocation is
   removed. Measured: two of four findings in the run existed only in conversation.
3. **0013** — verify closes. Ahead of the rest of gate B because it deletes a rule the others
   would otherwise have to work around, and it removes a section 0020 would otherwise compress.
4. **0011** — the `next` reader. After 0010 by dependency, and deliberately below 0013 because it
   **collides with 0006**, which rewrites the same script. Whichever runs second reads the
   first's output rather than its own ticket.
5. **0014, 0015, 0016, 0017** — the rest of gates B and C, in dependency order. 0015 is blocked
   on both 0012 and 0013 rather than merely ordered after them: removing the invocations first
   converts a measurable saving into silent information loss.
6. **0018, 0019** — routing. Below gate C only because gate C is the part with the saving
   attached; either could move up without harm.
7. **0020, 0021** — the trims. Last, and 0021 last of all: every other ticket in 0009 rewrites
   paragraphs in the files it compresses, so trimming first means trimming twice.
8. **0005, 0007, 0006, 0008** — phase 1 of the graph, in their original order.
9. **0003, 0004** — later phases, blocked on 0002.

## Notes on tie-breakers used

- **0009's tasks above 0002's** is not a tier judgement. Both are Tier 3. It is an explicit
  owner decision that the process work lands first, recorded here so a later reader does not
  read it as drift.
- **0012 above 0013** is tie-breaker 4, smaller and more certain, and tie-breaker 2: it unblocks
  two tickets where 0013 unblocks one.
- **0021 blocked by the whole effort** rather than by one ticket is unusual and correct. The
  blocker is not any single outcome but the files settling.

- **0022 at rank 1** is tie-breaker 1: it is a live regression in the shipped scaffold, introduced
  by 0010 and owned by no other ticket. It ranks above 0009's remaining tasks because a new
  project cannot claim a row at all until it lands, and above 0006 — which fixes the same defect
  in `next` — because 0006 is blocked and this is not.

## The collision to watch

0009 and 0002 touch the same files, and this is the thing most likely to cost real time:

| File | 0009 | 0002 |
|---|---|---|
| `templates/QUEUE.md` | 0010 pares the header | 0005 sets the header *(struck, handed to 0010)* |
| `templates/item.md` | 0010 adds `next`/`status` | 0005 adds `parent`/`blocked_by`/`relates` |
| `.claude/backlog/next` | 0011 rewrites for new fields | 0006 rewrites to walk ancestors |
| `skills/*/SKILL.md` | 0010, 0013, 0015–0021 | 0008 adds graph rules |

Only the first is resolved. The rest must be **sequenced, not parallelised** — there is no merge
protocol behind two sessions in one file. The cheapest resolution for `next` is to let 0011 land
and then re-specify 0006 against the shape it finds, rather than writing the parser twice.
