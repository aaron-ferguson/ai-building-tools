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
