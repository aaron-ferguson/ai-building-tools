---
id: "0191"
title: Read the first CHANGELOG.md version section against 0041's release-notes criterion
type: chore
next:
status: done
qa_level: verify
size: s
created: 2026-10-06
source: user
blocked_by: []
relates: ["0041"]
expects:
  - CHANGELOG.md
claimed_by:
claimed_at:
touches:
closed: 2026-10-07
---

## Problem

`0041` AC2 is a criterion about `CHANGELOG.md` **as it reads per version section**, and no version
section can exist until `tools/release --bump` promotes `## Unreleased` for the first time since
`0041` shipped. Verify 1d1f (2026-10-04, `0041` *Notes & decisions*) recorded it as *"not checkable
per version section: none exists"*: the preamble and three Unreleased entries were there, but the
`### Did not change` half had nothing to be read against. Leaving AC2 on `0041` would hold a
finished ticket open on an event no session controls, so the person split it out on 2026-10-06
(run-20261004T232135Z) and this ticket carries it.

## Functional requirements

- **FR1** — The newest `## <version> — <date>` section of `CHANGELOG.md`, written by
  `tools/release --bump`, satisfies `0041` AC2 as carried below, word for word.

No code is built here. The code that writes the section is `0041`'s (AC11–AC14 there).

## Acceptance criteria

Carried from `0041` AC2 word for word, with `0041`'s Placement-AC note: AC2's release-notes file is
`CHANGELOG.md`, checked per version section (`0041` AC13).

- [x] AC1 — Given the release-notes file, when read, then it states what changed, who it is for, what
      to do and what did not change, and no entry describes a change only by its ticket ID.

What would red it: a version section with no `### Did not change` line and no behaviour entry
saying what stayed the same; an entry reading only `0187` or `Close 0188`; a preamble naming no
audience or no instruction to the reader.

## QA plan

**When:** only after a release exists — `tools/release --bump` has produced the first
`## <version> — <date>` section of `CHANGELOG.md` since `0041` shipped. Until then the row is
`waiting`, and **a person or a sprint clears the waiting status once that release exists**, setting
`status: ready`.

**How a verify session checks it:**

1. Read the newest `## <version> — <date>` section of `CHANGELOG.md` (the first `## ` heading after
   `## Unreleased`), together with the file's preamble, end to end.
2. Confirm it states:
   - **what changed** — each entry leads with the behaviour that changed;
   - **who it is for** — the preamble or the section names the audience;
   - **what to do** — the reader is told what action, if any, the change asks of them;
   - **what did not change** — the `### Did not change` line written by
     `tools/release --bump --no-behaviour-change`, or, where behaviour did change, the behaviour
     entries otherwise.
3. Confirm **no entry describes a change only by its ticket id**. A mechanical aid, not the verdict:
   within that section, `grep -nE '^- *(Close )?[0-9]{4}\.?$'` must print nothing; then read each
   entry, since an entry that names a ticket and says nothing more in longer words still fails.
4. Record the version, the date and the lines read in *QA evidence*, by repo-relative path.

**Pass closes the ticket** (`./close`). A fail records which half is missing; the fix belongs in
`tools/release` or in the `--note` text written at close, captured as its own ticket.

## Out of scope

- Changing `tools/release`, `./close` or the `CHANGELOG.md` format — `0041` owns those.
- Rewriting historical entries to pass.

## Notes & decisions

- 2026-10-06 — **Split out of `0041` by the person** in run-20261004T232135Z: `0041` AC2's
  did-not-change half cannot exist before a release, so `0041` closes on its remaining ACs and this
  ticket carries AC2. Routed `next: verify` because there is nothing to build — the check is a
  reading of an artifact `0041`'s code produces — and `status: waiting` because the artifact
  appears only on a release, which a person runs. `qa_level: verify` because no runner applies and
  QA step 3 names the mechanical check. Ranked directly below `0041`, ahead of every other waiting
  row, so `./next --waiting` and sprint proposals surface it beside the ticket it came from.
- 2026-10-07 — **Waiting cleared**: `tools/release --bump` produced `## 0.9.37 — 2026-10-07` at
  633c4e3, after `0041` closed at 737a80e. Set `status: ready` by the verify session the person
  invoked for this ticket.

## Waiting on

Cleared 2026-10-07 (0.9.37 at 633c4e3): has tools/release --bump produced the first CHANGELOG.md version section since 0041 shipped? — a person or a sprint clears this once that release exists.

## QA evidence

Verify abe1, 2026-10-07, `qa_level: verify`. Copy executed: installed plugin 0.9.37; the subject is
`CHANGELOG.md` at 9b7b5db, not a skill.

Conventions: ../ai-building-conventions

Command (section extract + QA step 3 grep, verbatim):
`awk '/^## Unreleased/{u=1;next} u&&/^## /{n++} n==1&&/^## /{p=1} n==2{exit} p' CHANGELOG.md | grep -nE '^- *(Close )?[0-9]{4}\.?$'`
→ printed nothing, exit 1.

Read: `CHANGELOG.md` lines 1–24 — preamble 1–12, `## Unreleased` 14 (empty), `## 0.9.37 — 2026-10-07`
16–24 (seven entries, 18–24). Tree at Step 2: clean.

**Clause table, AC1**

| Clause | How checked | Result |
|---|---|---|
| Given the release-notes file | `CHANGELOG.md` per `0041` AC13; newest section is `## 0.9.37 — 2026-10-07` | ✅ |
| when read | read lines 1–24 end to end | ✅ |
| states what changed | each of entries 18–24 leads with the behaviour ("A sprint now…", "When the findings buffer crosses…", "verify now gives…", "A new item's acceptance-criteria section says…") | ✅ |
| who it is for | preamble l.4: "written for whoever installs this plugin: the sessions that run it, and the people who drive them" | ✅ |
| what to do | preamble l.6–7: "**What to do:** update the plugin install and start a new session…" | ✅ |
| what did not change | **no `### Did not change` line** in the section; QA plan step 2's fallback met by behaviour entries: l.19 "Retro and queue still run alone (0188)", l.20 "With a scope, the wording is unchanged (0174)". Not the ticket's red shape, which needs both absent | ✅ on the fallback ⚠️ |
| no entry describes a change only by its ticket ID (quantifier: *no entry*) | grep above printed nothing; each entry read: IDs only in trailing parentheses (18–21), none in 22–24 | ✅ |

**Mutations** (scratch copies, never the repo file):
- Two differing bare-ID entries `- 0187` and `- Close 0188.` inserted under `## 0.9.37` (diff `17a18,19`) → grep printed `3:- 0187` and `4:- Close 0188.`, exit 0 — red on both items.
- Control: `- 0187` under `## Unreleased` only (diff `15a16`) → nothing, exit 1 — the extract is scoped to the version section.
- Unmutated rerun → nothing, exit 1.

No NFR rows declared; no code changed, so no always-on rule applies beyond the reading.

⚠️ The preamble l.11–12 says "Each version ends with `### Did not change`", and 0.9.37 does not —
parked in `FINDINGS.md` (d1e8c8d). The QA plan's "written by `tools/release --bump
--no-behaviour-change`" is drift: per `tools/release` l.66–70 that flag writes a different line, and
`### Did not change` is hand-written by the release session.

Advisory: dirty set at Step 2 empty → intersection empty, not advisory.
