---
name: prototype
description: Build a prototype of a feature at whichever fidelity level is wanted right now — a quick Mermaid flow diagram, a self-contained clickable HTML mockup, or a real mocked-out component wired into a configured app workspace. Works from a ticket key or an ad-hoc feature idea pasted inline — no ticket required. Trigger whenever the user wants to visualize a flow, sketch a screen, mock something up, show stakeholders a clickable demo before engineering builds it, or turn a ticket or idea into something clickable — including "sketch this out", "mock this up", "show me what this would look like", "make this clickable", or "build a quick prototype of X". Produces something to LOOK at; for a design question that needs an answer rather than an artifact, that is a different job.
---

# Prototype

Generates a prototype at one of three fidelity levels — diagram, clickable HTML mockup, or a real Angular
component — for any ticket or ad-hoc feature idea. A force multiplier for design thinking, not a
replacement for design or engineering work.

**One skill per session.** Run this skill in its own conversation; the backlog carries the handoff — the
ticket's `next` field and `FINDINGS.md`, never a conversation. Measured **2026-08-22**: **85% of $15.11
went on context handling** at **191,752 tokens per turn**, modelling to **~$5.09** isolated. **No standard
is relaxed** — the rigour is all in the 15% that was output.

## Configuration

This skill carries no company or workspace specifics. Anything environment-shaped — the ticket system, the
design system, the app a level-3 build lands in — comes from the context config the project declares:
`CLAUDE.md` names `company: <name>` and the path to that config directory; read `tools.yml` there. Keys
used: `ticket_source`, `design_system`, `prototype`.

**What works without config, and what stops.** The grading is deliberate — the cheap levels are useful
anywhere, the expensive ones fail loudly rather than guessing.

| Capability | Needs | If absent |
|---|---|---|
| Level 1 (diagram) | nothing | works |
| Level 2 (clickable HTML) | nothing | works, on the template's placeholder palette — say so |
| Design-system fidelity | `design_system` | keep the placeholder tokens and say they are placeholders |
| Fetch / post to a ticket | `ticket_source` | work from the inline description; never invent a key |
| Level 3 (real component) | `prototype` | **stop** and name the missing block |
| Figma export | `prototype.figma` | **stop** and name the missing block |

**Never substitute a guess for a missing key.** A prototype built against invented paths or invented brand
colors is worse than one that did not get built, because it looks finished.

## Invocation

- `/prototype <TICKET-KEY>` — fetch the ticket, ask which level (unless already stated)
- `/prototype <TICKET-KEY> clickable` / `... level 2` — skip the fidelity question
- `/prototype` — the user pastes or describes a feature idea inline; no ticket needed
- Mid-session escalation — "make it clickable", "prototype it for real" jumps straight to a higher level
  without repeating earlier steps

## The three fidelity levels

If the user doesn't say which level they want, **ask — don't guess**. The levels trade speed for realism,
and picking wrong wastes their time either way: too low and they have to ask again, too high and you have
burned effort on polish nobody needed yet.

1. **Diagram** — a Mermaid user-flow, viewable as a standalone HTML file. Cheapest to produce and cheapest
   to throw away. Right for agreeing a flow, the happy path and the edge cases before anyone has opinions
   about pixels.
2. **Clickable prototype** — one self-contained HTML file: styled like a real screen, realistic mock data,
   and wired so tabs, buttons, forms and navigation actually respond (in-memory, nothing persists, nothing
   calls out). No server, no build — double-click to open. Right for stakeholder demos and gut-checking
   that a flow *feels* right before committing engineering time.
3. **Mocked-out real solution** — an actual component in the workspace named by `prototype.root`, built
   from the real components in its catalog and run with the configured serve command. Right for
   engineering handoff, or when it must look and behave byte-for-byte like what will ship.

## Design system

If `design_system` is configured and exposes an MCP server, **it is the source of truth** — build on it
rather than invented colors or guessed styling. That is what makes a prototype read as a real product
screen instead of a generic mock.

- **`get-tokens`** — real colors, spacing, radii, typography. Follow any resolution notes the config
  records; systems differ in how primitives map to semantic roles.
- **`check-contrast`** — before committing any colored-text-on-tint pairing (pills, badges, banners),
  verify **WCAG AA**. Mid shades frequently fail AA on their own light tints; step darker for text.
- **`list-components` / `search-components` / `get-component` / `get-usage-example`** — the real
  inventory, props, slots, events and ready-to-use markup. Use these to name and shape components
  correctly at any level.
- **audit/score helpers** (`audit-spacing`, `audit-typography`, `score-alignment`, `suggest-token`) —
  for tightening a build once the structure is in place.

**Per level.** Level 1: no styling to speak of, so skip unless naming a real component in the notes.
Level 2: the template ships **neutral placeholder tokens** — replace that block with real ones when a
system is configured and `check-contrast` anything new; with none configured, keep the placeholders and
say plainly the colors are not the brand's. Level 3: pair the component catalog with the MCP — the
catalog lists what is actually wired into the workspace, the MCP gives authoritative props and tokens,
and real components with token CSS vars beat hand-rolled styles.

**If the MCP is configured but unavailable this session, fall back to the template tokens and say so.**
Never silently invent brand colors.

## Step 1: Get the input

If a ticket key is provided:
- Fetch it from the configured `ticket_source`, requesting summary, description, issue type, and
  the acceptance-criteria and requirements fields named in `ticket_source.fields`.
- No `ticket_source` configured → say so and ask for the feature description inline.
- If the ticket has no description and no AC: ask the user to describe the feature before proceeding.

If no ticket key: treat the message as an ad-hoc feature description. Parse it directly — don't require a ticket to exist first. If it's too thin to work with (a one-line idea with no sense of the flow), ask a couple of clarifying questions before generating anything.

## Step 2: Pick the fidelity level

If the user named a level in the invocation, use it. Otherwise, briefly describe the three options above and ask. Default to assuming they want to iterate up (start cheap, escalate once the flow is agreed) rather than jumping straight to level 3 unless they're clearly asking for the real thing.

## Step 3: Generate the design source

The shared blueprint behind every fidelity level — produce it whichever level was chosen. For level 1 it
*is* the deliverable; for levels 2 and 3 it drives the build.

**Flow (Mermaid)** — `graph TD` for sequential flows, `flowchart LR` for parallel paths. Include the entry
point (how the user gets here), the happy path, key decision nodes, error states and recovery paths, edge
cases from AC, and terminal states (success, error, cancel).

```mermaid
graph TD
    A([User opens case]) --> B{Case has documents?}
    B -->|Yes| C[Show document list]
    B -->|No| D[Show empty state with upload CTA]
    C --> E[User selects document] --> F[Preview modal opens]
```

**Screen-by-screen wireframe** — for each distinct screen or modal state:

```
**Screen N: [Name]**
- **Purpose**: what this screen accomplishes for the user
- **Key elements**: inputs, buttons, tables, modals, nav — be specific
- **States**: empty / loading / error / success
- **Interactions**: [user action] → [what happens]
- **Design system hints**: existing catalog components that fit
```

Scale depth to the source: a story gets per-screen specs matching the AC, an epic gets a higher-level flow
with specs only at the feature level. Generate straight from AC where it is well-defined; otherwise infer
from the description and **say out loud what you assumed**.

## Step 4: Propose & revise

Display the flow and wireframe (even if the target is level 2 or 3 — the user should see the blueprint before you build on it). Ask:
> "Does this capture the intent? Say 'update [screen/flow]' to revise, or 'looks good' to build the [level] prototype."

Re-generate only what's called out, re-display, repeat until approved.

## Step 5: Build the artifact

**Where everything lives**: `<prototype.root>/<prototype.output_subdir>/[slug]/` — one directory per feature, regardless of fidelity level or whether it came from a ticket. Derive `[slug]`:
- From a ticket: `PROJ-1234` → `proj-1234-[short-feature-name]`
- Ad-hoc: kebab-case the feature name, e.g. "case timeline redesign" → `case-timeline-redesign`

### Level 1 — Diagram

Write `prototypes/[slug]/diagram.html`, a standalone Mermaid viewer:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>[Feature Name] — User Flow</title>
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <style>
    body { font-family: sans-serif; padding: 2rem; background: #fafafa; }
    h2 { color: #333; }
    .mermaid { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,.1); }
  </style>
</head>
<body>
  <h2>[Feature Name] — User Flow</h2>
  <div class="mermaid">
[mermaid diagram content — no code fences, just the raw diagram]
  </div>
  <script>mermaid.initialize({ startOnLoad: true, theme: 'default' });</script>
</body>
</html>
```

Also write `prototypes/[slug]/wireframe.md` with the screen-by-screen description from Step 3.

Tell the user: "Open `prototypes/[slug]/diagram.html` in your browser to view the flow."

### Level 2 — Clickable HTML prototype

Copy `assets/prototype-template.html` to `prototypes/[slug]/prototype.html` and **edit the copy** — it already has the design tokens, light/dark theming, a compact single-row topbar, a small client-side router, the persistent left **drawer** of administrative controls, and reference `list`/`detail` views showing the click-through pattern. Don't rewrite the boilerplate.

**The rule of thumb for the drawer**: anything about running the prototype *as a tool* belongs in it — swapping mock data volume, saving/loading a scenario, theme. Anything part of the *feature being demoed* belongs in the main content, however administrative it looks: a filter bar, a status legend that is part of the screen, a form's own field. A stakeholder must see and use those without hunting through a drawer.

**Real app navigation is not admin tooling — this is the mistake to avoid.** If the feature has persistent navigation between top-level screens, that is part of the feature and belongs in the main app content, always visible, exactly as in production — never in the collapsible drawer. Build it as ordinary markup in the app shell (a `<nav>` alongside `.main` inside `.app`) and wire it with the same `navTo`/`data-nav` pattern. The drawer's "View" section is reserved for a narrower case: combining things that would *never* coexist in production, e.g. three role-restricted portals as tabs so one file can demo all three — and even then say so in the field-reference doc. **When in doubt it is real navigation**, so put it in the app.

**The drawer mimics the collapsible sidebar pattern from tools like Jira, deliberately** — match it rather than reinventing. It is **collapsed by default** (`body.drawer-collapsed`), so the feature owns the full screen on load; expanding docks it open, shifting `.app` via `margin-left` rather than overlaying. The *topbar* spans full width at all times and never moves, and the single toggle icon (a small inline SVG) sits at its far left — which keeps it reachable whether the sidebar is open or collapsed, and is why the sidebar has no header of its own. The icon never changes, only its `title`. **It is the only way to toggle**: a hover-to-open edge strip was tried and removed as distracting in demos. Nothing auto-collapses when you pick an action. All of this is generic, driven off one class, and needs no per-prototype work.

From there:

- Replace `views` with one function per screen from the wireframe. Each returns a DOM node, `navTo(viewKey, opts)` switches, `state` carries context the next view needs.
- **App navigation**: more than one top-level screen → build real persistent nav in the main content, and delete the template's drawer "View" `.menu-section` unless this is the demo-only-combination case above.
- Replace `DATA_STATES` with the feature's real data, defining **all three** variants — not optional polish, it is the point of the switcher. **typical**: representative rows covering the statuses and edge cases that matter. **empty**: zero rows, and the view must render a real empty-state message rather than a blank table — if the wireframe never specified what "no results" looks like, that is exactly the gap this catches, so decide it now. **overloaded**: enough rows to plausibly stress the screen (50–100+, more if production volume is higher) with a few deliberately long values, so wrapping, truncation and pagination get a real look before engineering hits the same problem. Every screen should react to all three; if one only makes sense in a single state, say so rather than leaving it silently broken.
- **Leave the Save / Load scenario controls alone** — no per-screen work needed. The logger watches every field change and click via event delegation, so it logs a readable trail and can export or re-import an exact `db` + `state` snapshot whatever screens you build. That is what lets the user capture what a stakeholder did and reload it later. Only exception: tag a genuinely custom meta-control `data-no-log`.
- Replace `db` with data matching the feature, shaped so the screens can be genuinely clicked through. If completing a task should change something, mutate `db` in the handler and call `render()` — that is what makes it feel real rather than static.
- **Keep a topbar even for a single screen or modal**, minimal if need be: it is the one place the toggle icon can sit and stay reachable when the sidebar is collapsed.
- **Reuse the existing primitives** (`.stat`, `.pill`, `.tbl`, `.tabs`, `.field`, `.toast`, `.modal-backdrop`, `.drawer`, `.data-state-switch`, `.menu-section`) rather than inventing CSS the template already covers. Use `.menu-btn-row.stack` for any drawer button group with more than two or three options, or longer labels — the drawer is narrow and vertical, closer to a nav list than a toolbar.
- **No decorative emoji anywhere** — not in labels, pills, cells or toasts. These are demoed to clients, and pictorial emoji read as unpolished; plain text does the same job more credibly ("Save" not "💾 Save"). The exception is monochrome near-universal glyphs functioning as icons: `✕`, `▸`/`▾`, small single-color inline SVGs.
- The template's token block holds **neutral placeholders**, not anyone's brand. With a design system configured, replace it with real tokens and `check-contrast` any colored-text-on-tint pairing; without one, keep the placeholders and say plainly the colors aren't the brand's. **Never swap in guessed "official" colors.**

Tell the user: "Open `prototypes/[slug]/prototype.html` in your browser — it's fully clickable, no server needed." Then generate the field reference doc below.

### Level 3 — Mocked-out Angular solution

**a. Read the catalog and query the design system** — `<prototype.root>/<prototype.component_catalog>` for
what is wired into the workspace, and the design-system MCP for authoritative props, usage and tokens
before writing any UI code. Style with token CSS variables rather than hand-picked values.

**b. Create the files** in `prototypes/[slug]/`: `[slug].component.ts` (standalone, using
`inject(MockDataService)` from `prototype.mock_data_import`; extend it if new data types are needed),
`[slug].component.html` (using catalog components), `[slug].component.scss` (scoped).

**c. Register the route** in `<prototype.root>/<prototype.routes_file>`:
```typescript
{ path: 'prototypes/[slug]', loadComponent: () => import('../../prototypes/[slug]/[slug].component').then(m => m.[ClassName]Component) }
```

**d. Register in the launcher** — add to the `prototypes` array in `<prototype.launcher_file>`:
```typescript
{ title: '[Feature Title]', description: '[Brief description]', route: '/prototypes/[slug]', status: 'ready', ticket: '[KEY or "ad-hoc"]' }
```

**e. Verify the build** — run `prototype.build_command` in `prototype.root`. **Never report a level-3
prototype as ready if it doesn't compile.**

Tell the user: "Prototype ready. Run the serve command and open `<prototype.serve_url>/prototypes/[slug]`
to demo it." Then generate the field reference doc below.

### Developer documentation (levels 2 and 3 only)

A clickable mockup looks real enough that people forget it is mock data — until someone asks "what happens if this field is blank?" mid-demo, or an engineer picks it up to scope the real build and reverse-engineers intent from HTML. Write `prototypes/[slug]/field-reference.md` to answer those questions before they are asked.

**One document across levels 2 and 3** — level 3 is a fidelity upgrade of the same feature, so escalating means reading the current file and updating it in place (adding fields the Angular build introduced, correcting any that changed shape), never starting over.

For every input, control and dynamic display element across the screens just built, record: **Field** (label as shown), **Type** (`text`, `textarea`, `number`, `date`, `dropdown`, `multi-select`, `checkbox`, `radio group`, `toggle`, `file upload`, `button/action`, or `display-only`), **Required**, **Constraints** (length limits, numeric range, format), **Options / Values** (the full enumerated list — often the first thing stakeholders ask about), **Default**, and **Notes** (validation behaviour, what changes elsewhere, conditional visibility, data source).

Group by screen, matching the names from Step 3's wireframe:

```markdown
# [Feature Name] — Field Reference

Generated from the level [N] prototype at `prototypes/[slug]/`. Use this to answer field-level
questions during a stakeholder demo, and as a starting spec for the real build.

## Screen: [Screen Name]

| Field | Type | Required | Constraints | Options / Values | Default | Notes |
|---|---|---|---|---|---|---|
| Case Number | display-only | — | — | — | from case record | Not editable in this view |
| Status | dropdown | Yes | — | Active, Pending, Closed, Flagged | Active | Changing this updates the status pill on the list screen |
| Notes | textarea | No | max 500 characters | — | empty | Limit assumed — not in AC, confirm before build |
```

**Same rule as the wireframe:** pull real constraints from the ticket's AC where they exist, and when you fill a gap with a reasonable guess — a character limit, a default, an enum nobody specified — **say so in Notes rather than presenting it as fact**. That is what stops the user confidently telling a stakeholder a limit engineering never agreed to.

For level 2, note the drawer's contents **once near the top** rather than per screen, since they are shell-level: **Data State** — say what "empty" and "overloaded" actually look like for this feature's main list, because that is what comes up when a stakeholder opens the drawer mid-demo. **Scenario** — Save exports the interaction log plus the exact `db`/`state` snapshot and Load restores it exactly, so a specific scenario can be replayed rather than lost on reload. **View**, if present — say what the options correspond to in production ("these become three role-restricted screens, combined here for demo convenience only").

## Step 6: Post to Jira (only if there's a ticket)

Not every prototype needs a ticket update — a level 1 sketch used just to think something through out loud usually doesn't. Ask before posting rather than posting automatically:
> "Post this as a Design First Pass comment on [KEY]?"

If yes: post a comment to the ticket via the configured `ticket_source`, body formatted as markdown:

```markdown
## Design First Pass — [TICKET-KEY]

### User Flow
\`\`\`mermaid
[diagram here]
\`\`\`

### Wireframe Notes

**Screen 1: [Name]**
- **Purpose**: ...
- **Key elements**: ...
- **States**: ...
- **Interactions**: ...
- **Design system hints**: ...

---
*Generated by the /prototype skill (level [N]) — for designer review and refinement. Not final design.*
```

Report: `"Posted Design First Pass to [KEY] → <ticket_source.browse_url>/[KEY]"`

When referencing other tickets in the comment body, use full URLs so the tracker renders smart links — not bare keys.

## Step 7: Export to Figma (optional, level 2 or 3 only)

Triggered when the user says "export to Figma" after a prototype is confirmed working.

**Pre-flight**: for level 3, verify `prototype.serve_url` responds (if not: "Please start the dev server first, then re-run the export"). For level 2 the standalone HTML can be exported directly without a server.

**Level 3 export:**
```bash
cd <prototype.root>
<prototype.figma.export_command>   # with [slug] substituted
<prototype.figma.serve_command>
```

Then tell the user: open **<prototype.figma.dashboard_url>** — the dashboard shows all captures with thumbnails and **Copy HTML** buttons. To import into Figma web: Plugins → Find more plugins → **html.to.design** → Install (one-time), then Plugins → html.to.design → **Paste HTML** tab, then **Copy HTML** on any capture → paste → Import. Each import creates one editable frame with real text layers, shape fills and group hierarchy.

For level 2, the raw HTML of `prototype.html` can be pasted straight into the plugin — no export script needed.

---

## Step 8: Park what surprised you

Before reporting, park what surprised you in `.claude/backlog/FINDINGS.md` — one dated line, while the
context is still hot.

Triggers: **a template or skill step that had no correct answer for your case**, a configured command that
behaved unexpectedly, a scaffolding step you had to invent.

**An explicit "nothing surprised me" is a complete result** — never manufacture one, since an invented
entry is paid for by every later session. **Commit it in the same turn you write it, by pathspec**;
uncommitted it is one `git stash` from gone. Anything whose home is obvious goes there instead.

---

## Key Behaviors

- Works from a ticket or an ad-hoc idea — never require a ticket first, and scale wireframe depth to the source type. Generate from AC where available, fall back to the description, and always state the assumptions made.
- **Built on the configured design system at every level** — real tokens over invented colors, AA-verified pairings via `check-contrast`, authoritative props via `get-component`. The level-2 template's tokens are neutral placeholders; swapping in real ones is what makes a prototype read as on-brand.
- Ticket posting is optional and asked for, never automatic.
- **Each prototype lives entirely in `prototypes/[slug]/`** whatever the level, so escalating 1 → 2 → 3 adds files rather than relocating anything. `field-reference.md` is written for levels 2 and 3 and is one document across both — level 3 updates it in place.
- **Every level-2 prototype ships with the Typical / Empty / Overloaded switcher and Save / Load scenario controls by default** — not something to ask about or skip. Deciding what those three states look like is part of the design thinking, and capturing what a stakeholder did in a demo costs the prototype no extra scope.
- Those controls live in the persistent left drawer, **collapsed by default**, toggled solely by the topbar icon. Deliberately no hover-to-open edge strip and no Notes & Questions section — both tried and removed. **Real navigation between the feature's own top-level screens is never in this drawer**; it lives in the main app content as persistent nav, same as production. These defaults come from `prototype-template.html`, and a prototype built before one was added does not retroactively get it — copy the blocks forward.
- **No decorative emoji, ever** — plain text labels, with the narrow exception of monochrome functional glyphs (`✕` `▸` `▾`, small single-color inline SVGs) acting as icons. A hard default, not a per-prototype style choice: these are client demos, and pictorial emoji read as unpolished.

## Error Handling

- Ticket not found: "Could not find [KEY]. Please verify the ticket key."
- Ticket has no content: ask the user to describe the feature before generating
- Ad-hoc description too thin to work with: ask 1-2 clarifying questions before generating
- Ticket-system auth error: say the connector needs reconnecting; do not retry silently.
- Mermaid syntax error: simplify the diagram; note which branches were simplified
- Build errors (level 3): fix before reporting done

## Handoff

After Step 5 (and Step 6 if applicable), if a `/capture` skill is available, hand off with:

- **Source**: `prototype`
- **Slug**: `YYYY-MM-DD-prototype-[ticket-key-or-slug]`
- **What Mattered**: ticket key/title or feature name, the level built, key decisions in the flow and wireframe
- **Action Items**: designer follow-ups or review requests the user noted
- **Strategic Signals**: UX patterns or design-system gaps surfaced during the session
- **Changes Made**: "Level [N] prototype built at prototypes/[slug]" (plus "field-reference.md written/updated" for levels 2–3) and/or "Design First Pass posted to [KEY]", or "skipped"
- **Tactical already written**: false
