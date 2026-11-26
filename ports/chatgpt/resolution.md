**2. Project instruction files.** In the repository root, inspect the
`## Conventions` section of `AGENTS.md`, then `CLAUDE.md`. Each can declare
a line such as `@../ai-building-conventions/CONVENTIONS_CORE.md`.
Read that file explicitly. Resolve relative paths against the project root.

Use the first readable core in the order config, AGENTS.md, CLAUDE.md.
Check all declared pointers for disagreement even if the first resolves.
Report broken pointers and conflicting destinations, naming the source selected.
If none resolves, stop before writing anything and explain how to set
`conventions.path` or add the import to a project instruction file.

## What to load

Read the resolved core, applicable project instructions and company profile.
Project overrides take precedence over company and general defaults.
Read files triggered by the core index and the ticket's NFR citations.
Cite convention files by bare filename in tickets and reports.
