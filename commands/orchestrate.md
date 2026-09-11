---
description: Deprecated alias for /sprint. Resolves to the sprint skill and prints a deprecation notice naming the removal date. Removed on or after 2026-12-10 — use /sprint.
---

# /orchestrate — deprecated alias for `/sprint`

This command was renamed on **2026-09-10** (item `0129`). It is not the skill: it exists so that a
machine with an older install, or a habit, still reaches the same place.

**Deprecated. Owner: Aaron Ferguson. Removed in the first version released on or after
2026-12-10.** Until then the behaviour is unchanged — the same skill, the same steps, the same
outcome schema.

## What to do

1. **Print this notice first, before anything else:**

   > `/orchestrate` has been renamed to `/sprint`. This alias still works and will be removed in
   > the first version released on or after **2026-12-10** — use `/sprint` from now on.

2. **Then read `skills/sprint/SKILL.md` at the plugin root and follow it exactly**, with whatever
   arguments were passed to this command. State nothing about how to drive a backlog here: a second
   copy of those rules is a copy that diverges, and the skill is the single source.

Nothing else about this alias is configurable. If `skills/sprint/SKILL.md` cannot be read, say so
and stop rather than improvising the loop — a supervisor that invents its own routing is the exact
failure the skill's own rules exist to prevent.
