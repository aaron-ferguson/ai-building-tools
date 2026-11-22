---
name: ai-building-sprint
description: Coordinate a cloud sprint when asked to run subagents against a project ticket backlog. Dispatch the installed engineering stages in fresh agent sessions.
---

# Coordinate a cloud sprint

Confirm the target repository, branch, ticket scope, deadline and any spend cap with the user. Reuse limits already supplied. Obtain a writable cloud checkout of that branch and resolve the conventions checkout from the project configuration. Use the project's native backlog and executable scripts. Keep tracked changes scoped to the requested project.

Before claiming work, dispatch one read-only child to report the project HEAD, discover the installed stage skills, read the conventions core, and run the backlog reader. Verify its observations against your checkout. If child dispatch, the shared checkout, or an explicitly required budget limit is unavailable, stop with the specific blocker. Do not substitute an in-conversation roleplay or require a local CLI.

Use .tickets/next --drive from the project root (run the reader in the backlog directory if required). Dispatch one stage at a time. Give each fresh child the checkout path, repository and branch, ticket IDs, stage skill name, scope and limits. Instruct it to follow the installed skill, use the backlog's claim and handoff scripts, and report IDs, commits, outcomes and unresolved questions. Children must not publish branches, release software or spawn further children. Use separate children for development and verification.

Wait for the child, checking time and limits. Independently check HEAD, changed paths, ticket state and the child's reported commits before another dispatch. Re-read the backlog after each stage. Stop on a waiting decision, an unexplained dirty path, a failed handoff, a repeated state without progress, an orphaned lock, a reached limit or exhaustion of eligible tickets. Never clear another session's lock. Run design, prototype, queue or retro when requested or called for by the backlog and confirmed scope.

When publication is authorized, publish the committed changes to the agreed GitHub branch with a non-forced, head-checked update. Report local-only commits explicitly if publication is unavailable or the remote has advanced. Finish with tickets closed, work remaining, commit IDs and any decision the user needs to make.
