# Changelog

What a session running these skills will do differently, by released version. It is written for
whoever installs this plugin: the sessions that run it, and the people who drive them.

**What to do:** update the plugin install and start a new session, since skills resolve once at
session start. An entry says so where anything more is needed.

Each entry is written by the `verify` session that closed its ticket, through `./close --note`, and
leads with the behaviour; a ticket number in parentheses is provenance. `tools/release --bump` moves
`## Unreleased` under the version it bumps. Each version ends with `### Did not change`, written by
the release session, because only a whole-release view can say it.

## Unreleased

- A sprint now resolves the opus alias once, at its Step 1 probe, and dispatches every stage and every resume on that concrete model id, recording it on scope_confirmed and on each dispatch event, so one run can no longer mix two models and a run log names the model each session ran on (0187).
- A sprint is now planned from the first develop-ready row rather than from a design row that outranks it: the proposal names the design rows related to that gate and the one design row that will head the next sprint, and under a confirmed scope those are designed first and then built. Design may now run beside develop, verify or design; ./next --drive steps over a design row whose files a running develop is editing, and exits 6 (wait) when a develop gate names a file a running design session is reading. Retro and queue still run alone (0188).
- When the findings buffer crosses on a run that confirmed no scope, ./next --drive now says the retro waits until the run is out of work, instead of naming a confirmed scope the supervisor never passed. With a scope, the wording is unchanged (0174).
- A sprint's ledger block now lists every ticket the run closed, each with its title and the verdict that closed it, beside per-window elapsed time and cost, totals, averages and cost per closed ticket against MEASUREMENT.md's pair. ./close takes --note to write a release note under ## Unreleased in CHANGELOG.md, and tools/release promotes those notes to the version it bumps, refusing an empty ## Unreleased unless --no-behaviour-change is passed. tools/harvest-usage.sh --by-session prints one row per context window (0041).
- verify now gives every plural or quantifier clause in its clause table (every, each, those, per X) a fixture of at least two items that differ, and puts a sweep's output file inside the session's working directories rather than /tmp, polling in a bounded loop where Monitor cannot be armed.
- A sprint now builds its baseline worktree beside the checkout, so config.yml's relative paths resolve and a green HEAD no longer reads red, and opens a fail's detail pointer to name the failed criterion before presenting it, instead of relaying the escalation as the cause.
- A new item's acceptance-criteria section says how to strike a criterion: as a non-list ~~ACn~~ line, since a struck bullet reds tests/item-ac-form.test.sh.
