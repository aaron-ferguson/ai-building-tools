# ai-building-tools

The `queue` · `design` · `prototype` · `develop` · `verify` · `retro` skill suite, and the
backlog scripts they drive. **This repo is public.**

## Conventions
@../ai-building-conventions/CONVENTIONS_CORE.md

## Profile
- collaboration: solo
- company: none
- release: released

`company: none` is not a default — it is the constraint. This repo is public, so **no Neumo
material reaches it**: no court, case or client data, no internal names, no company profile.
`.claude/backlog/config.yml` carries the same rule as `routing.company: none`, and a ticket that
would need a company profile does not belong here.

`release: released` because other machines install this plugin and this project's own sessions run
it. The release is the version bump and the install, not a deploy — see below.

## This project is the tool its sessions are running

Sessions here work a backlog **using** the skills stored in this repo, so an edit to
`skills/**` changes the instructions the *next* session receives and nothing about the current one.
Two consequences, and both have cost real work:

- **The installed copy is what runs, and the version number does not prove it matches.** Skills
  resolve once at session start from `~/.claude/plugins/cache/`, which can sit at a different
  version than the checkout, or the same version with different bytes. A session has reported a
  rule missing that had shipped the same day. Diff the trees before concluding a rule is absent:
  `diff -rq skills/ ~/.claude/plugins/cache/ai-building-tools/ai-building-tools/<version>/skills/`
- **`tools/release` runs the release chain**: push → bump `.claude-plugin/plugin.json` → update
  the install → restart. Every step is silent when skipped. **`claude plugin update` reporting
  success is not evidence the bytes changed** — the cache directory is keyed by version, so when
  the version has not moved nothing is re-extracted regardless of the reported outcome. `tools/release`
  refuses before pushing if the version has not been bumped, then diffs the resolved install
  directory against the source after the update (0084).

## Tests

No test runner. The suite is `tests/*.test.sh`, each self-contained and printing its own tally:
`for t in tests/*.test.sh; do "$t" || exit 1; done`. Every guard greps prose, which is why
`testing-conventions.md`'s rules on guards that cannot fail carry unusual weight here — and why
**rewrapping a guarded paragraph is a breaking change**: `grep` is line-based, so an asserted
phrase that straddles a line break cannot be matched at all.

## Concurrency

Several sessions work this backlog at once. `references/CONCURRENCY.md` governs every write;
`.claude/backlog/{claim,close,next}` are the scripts that make claims durable. In a plugin repo the
skill and reference files **are** the product, so they are structurally multi-writer and the
file-scope rule is weaker here than it reads.
