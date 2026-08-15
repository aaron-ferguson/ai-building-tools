# Resolving the conventions

Read by `capture`, `develop`, and `qa` before they do anything that cites a standard.

These tools hold **no principles about code or product**. Every claim about what good software
looks like — TDD, secrets handling, input validation, PII in logs, accessibility, migration
safety — lives in the [`ai-building-conventions`](https://github.com/aaron-ferguson/ai-building-conventions)
repository and is **cited, never restated**. A restated rule is a rule that drifts.

What these tools *do* own is workflow: how work is captured, ranked, claimed, verified, and
closed. That split is the whole design. The test for any line is not "is this a principle?" but:

> Would this still be true if the backlog didn't exist?

Yes → it's a convention, cite it. No → it's workflow, it belongs here.

---

## Resolution order

Find the conventions directory once, at the start of the skill, in this order. Stop at the first
one that resolves to a directory containing `CONVENTIONS_CORE.md`.

**1. `.claude/backlog/config.yml` → `conventions.path`**

```yaml
conventions:
  path: ../ai-building-conventions      # relative to the repo root, or absolute
```

The explicit answer. Relative paths resolve from the project root, not the current working
directory. Prefer this when the project has a backlog.

**2. The project's `CLAUDE.md` → the `## Conventions` import**

```markdown
## Conventions
@../ai-building-conventions/CONVENTIONS_CORE.md
```

This is the wiring the conventions repo already prescribes, so most projects need no config at
all. Take the directory containing the imported `CONVENTIONS_CORE.md`.

**3. An older-style path reference in `CLAUDE.md`**

Projects wired before the core-import pattern existed name convention files by path directly:

```markdown
- Coding: /path/to/ai-building-conventions/coding-conventions.md
- Git:    /path/to/ai-building-conventions/git-conventions.md
```

Take the common parent directory **only if it contains `CONVENTIONS_CORE.md`**. That check is
what keeps this a reading rather than a guess — the project stated the path, you are confirming
it points at a conventions repo, not inferring one.

When this is the source that resolves, say so once and offer the upgrade: adding the
`## Conventions` import gives on-demand access to every convention file via the core's index,
where the old form only reaches the two or three files it happens to name.

**4. Nothing resolved → stop.**

Do not guess a path, do not search the filesystem for a directory that looks right, and do not
proceed on your own judgement of what the conventions probably say. Report this and stop:

> This project isn't wired to a conventions repository, and these tools deliberately carry no
> standards of their own — they'd have nothing to check your work against.
>
> Fix it either way:
> - add `conventions.path` to `.claude/backlog/config.yml`, or
> - add a `## Conventions` import to the project's `CLAUDE.md` (see the conventions repo README)
>
> If you don't have the repo yet: https://github.com/aaron-ferguson/ai-building-conventions

Stopping is correct here. A backlog item captured with no NFR standard, or QA'd against no
standard, looks exactly like one that was done properly — and that silent equivalence is worse
than the inconvenience of being blocked.

---

## What to load once it resolves

- **Always:** `<conventions>/CONVENTIONS_CORE.md`. It carries the always-on rules and an index
  of every other file with its trigger.
- **Always:** the project's own `CLAUDE.md`. Project overrides beat universal defaults;
  precedence is project `CLAUDE.md` > company profile > general default.
- **On demand:** exactly the files cited in the item's NFR table, plus whatever the core's index
  says the task triggers. Don't read all of them; don't read none.

Cite convention files by bare filename (`security-conventions.md`) in items and reports. The
directory is resolved per project and per machine, so an absolute path written into a backlog
item is wrong the moment anyone else reads it.
