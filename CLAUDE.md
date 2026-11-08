# ai-building-tools

The `queue` · `design` · `prototype` · `develop` · `verify` · `retro` skill suite, and the
backlog scripts they drive. **This repo is public.**

## Conventions
@../ai-building-conventions/CONVENTIONS_CORE.md

## Profile
- collaboration: solo
- company: none
- release: released

`company: none` is not a default — it is the constraint. This repo is public, so **no company
material reaches it**: no court, case or client data, no internal names, no company profile.
`.tickets/config.yml` carries the same rule as `routing.company: none`, and a ticket that
would need a company profile does not belong here.

`release: released` because other machines install this plugin and this project's own sessions run
it. The release is the version bump and the install, not a deploy — see below.

## This project is the tool its sessions are running

Sessions here work a backlog **using** the skills stored in this repo, so an edit to
`skills/**` changes the instructions the *next* session receives and nothing about the current one.
Two consequences, and both have cost real work:

- **For skills, the installed copy is what runs** (the suites run the backlog scripts' *templates*),
  **and the version number does not prove it matches.** Skills
  resolve once at session start from `~/.claude/plugins/cache/`, which can sit at a different
  version than the checkout, or the same version with different bytes. A session has reported a
  rule missing that had shipped the same day. Diff the trees before concluding a rule is absent:
  `diff -rq skills/ ~/.claude/plugins/cache/ai-building-tools/ai-building-tools/<version>/skills/`
- **When asked to release, or to bump the plugin version, run `tools/release` from the repo root.**
  The chain is push → bump `.claude-plugin/plugin.json` → update the install → restart,
  and every step is silent when skipped. Worse, a step can be *performed*, report success, and
  still not have happened:
  **`claude plugin update` reporting success is not evidence the bytes changed**, and neither is
  the `gitCommitSha` it then writes into `installed_plugins.json` — the cache directory is keyed by
  version, so if the version did not move nothing is re-extracted and the record is updated anyway.
  Both halves of that record were observed wrong on the same evening, in opposite directions.
  `tools/release` does the whole chain in one invocation, refuses before pushing when the version
  has not been bumped, and ends by diffing the resolved install directory against the pushed
  commit; `tools/release verify` makes that comparison on its own.
  A bump refuses on an empty `## Unreleased` in `CHANGELOG.md`: add the notes there first, one per
  behaviour a session will now see differently, and pass `--no-behaviour-change` only when the
  release changes none.

## Where toolkit work comes from

This repo runs its own skills on itself, so every friction it notices is about itself, and a
backlog fed only by that grows without end: on 2026-10-27, 83% of tickets were agent- or
retro-filed and the triage withdrew 67 of them. So a finding from this repo's own sessions is
**held** (`retro` Step 4), not filed, until a project that uses these tools to build something
confirms it, or the user asks. v1 is the capability rows the triage kept (0069, 0070, 0071,
0214); work outside v1 and outside a confirmed finding needs a stated reason.

## Tests

**No new guard greps prose.** Natural language is vague by nature, and a matcher over it grows its
own defect classes faster than it catches regressions: needles a larger figure satisfies, phrases a
rewrap splits, absences nothing can assert. A rule that must hold exactly goes in a script that
refuses when it is broken, with a behaviour test; anything else stays prose, unguarded. An existing
prose guard that reds on a correct rewording is deleted, not re-anchored.

No test runner. The suite is `tests/*.test.sh`, each self-contained and printing its own tally:
`for t in tests/*.test.sh; do "$t" || exit 1; done`. Every guard greps prose, which is why
`testing-conventions.md`'s rules on guards that cannot fail carry unusual weight here — and why
**rewrapping a guarded paragraph is a breaking change**: `grep` is line-based, so an asserted
phrase that straddles a line break cannot be matched at all.

Every file carries the same announce-on-abort block directly after `set -eu` and sets `TALLIED=1`
on the line after its tally, so a file that dies early prints `ABORTED` with its counts so far and
never exits 0. A new file copies the block from a sibling; `tests/abort-announce.test.sh` reds until
it does (0169).

## Concurrency

Several sessions work this backlog at once. `references/CONCURRENCY.md` governs every write;
`.tickets/{claim,close,next}` are the scripts that make claims durable. In a plugin repo the
skill and reference files **are** the product, so they are structurally multi-writer and the
file-scope rule is weaker here than it reads. What holds instead is one session per shared file, a
designed wait when every row collides, and no opening a `verify`-held file mid-session:
`references/CONCURRENCY.md`, *The working tree is shared too*.
